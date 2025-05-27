require 'rexml/document'
require "stringio"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/string/indent"

module Compilers
  module EncliticPronounsRules
    def self.print_filter_tags_enclitic(xml_rules_file_name, output)
      rule_count = 1
      enclitic_pronouns_rules_xml = REXML::Document.new(File.open(xml_rules_file_name))

      output.puts "  def call(verb_part, enclitics, enclitic, enclitic_tags, enclitic_lemmas, index)"
      # puts "    puts \"calling filter_tags_enclitics with verb_part:\#{verb_part} enclitic:\#{enclitic} enclitic_tags:\#{enclitic_tags} enclitic_lemmas:\#{enclitic_lemmas}\""
      enclitic_pronouns_rules_xml.elements.each("//rule") do |rule|
        output.puts "# RULE: #{rule_count}"
        condition = rule.get_elements("condition")[0]
        process_condition(condition, 1, rule_count, 1, output)
        rule_count = rule_count + 1
      end

      output.puts "    if enclitic_tags == nil or enclitic_tags.empty?"
      output.puts "      result = [nil, nil]"
      output.puts "    else"
      output.puts "      result = [enclitic, enclitic_tags, enclitic_lemmas]"
      output.puts "    end"
      output.puts "    return result"
      output.puts "  end"
    end

    private_class_method def self.filter_tags(filter, output)
      # puts "filter:#{filter}"
      evaluation_tokens = filter.split()
      or_result_expression = nil
      index = evaluation_tokens.rindex("OR")
      if index != nil
        # Expression with OR
        ors_expression = evaluation_tokens[0..(index + 1)]
        expression = nil
        ors_expression.each do |subexpression_token|
          unless subexpression_token == "OR"
            if expression == nil
              expression = "#{replace_wildcards(subexpression_token)}"
            else
              expression << "|#{replace_wildcards(subexpression_token)}"
            end
          end # from unless
        end # from each
        expression = "if enclitic_tag =~ /#{expression}/"
        or_result_expression = expression
      end # from if index != nil
      # puts "or_result_expression: #{or_result_expression}"
      # puts "filter: #{filter}"
      and_result_expression = nil
      index = evaluation_tokens.index("AND")
      if index != nil
        # Expression with AND
        if or_result_expression == nil
          ands_expression = evaluation_tokens
        else
          ands_expression = evaluation_tokens[index..evaluation_tokens.length]
        end
        expression = nil
        subexpression_token_prev = nil
        ands_expression.each do |subexpression_token|
          unless subexpression_token == "AND" or subexpression_token == "NOT"
            if expression == nil
              if (subexpression_token_prev != nil and subexpression_token_prev == "NOT") or
                (or_result_expression == nil and filter =~ /^NOT/)
                expression = "enclitic_tag !~ /#{replace_wildcards(subexpression_token)}/"
              else
                expression = "enclitic_tag =~ /#{replace_wildcards(subexpression_token)}/"
              end
            else
              if subexpression_token_prev != nil and subexpression_token_prev == "NOT"
                expression << " and enclitic_tag !~ /#{replace_wildcards(subexpression_token)}/"
              else
                expression << " and enclitic_tag =~ /#{replace_wildcards(subexpression_token)}/"
              end
            end
          end # from unless
          subexpression_token_prev = subexpression_token
        end # from each

        if or_result_expression == nil
          expression = "if #{expression}"
        else
          expression = " and #{expression}"
        end
        and_result_expression = expression
      end # from if index!=nil

      final_expression = or_result_expression
      if final_expression == nil
        final_expression = and_result_expression
      elsif and_result_expression != nil
        final_expression << and_result_expression
      end

      if final_expression == nil
        # Not OR or AND expressions
        if filter =~ /^NOT/
          expression = evaluation_tokens[1]
          final_expression = "if enclitic_tag !~ /#{replace_wildcards(expression)}/"
        else
          final_expression = "if enclitic_tag =~ /#{replace_wildcards(filter)}/"
        end
      end

      output.puts "    enclitic_tags_array = enclitic_tags.split(/ /)"
      output.puts "    enclitic_lemmas_array = enclitic_lemmas.split(/ /)"
      output.puts "    new_enclitic_tags_array = Array.new"
      output.puts "    new_enclitic_lemmas_array = Array.new"
      output.puts "    enclitic_tags_array.each_index do |index_aux|"
      output.puts "    enclitic_tag = enclitic_tags_array[index_aux]"
      output.puts "    enclitic_lemma = enclitic_lemmas_array[index_aux]"
      output.puts "      #{final_expression}"
      output.puts "      # tag removing"
      output.puts "      else"
      output.puts "        new_enclitic_tags_array << enclitic_tag"
      output.puts "        new_enclitic_lemmas_array << enclitic_lemma"
      output.puts "      end"
      output.puts "    end"
      output.puts "    if new_enclitic_tags_array.empty?"
      output.puts "      enclitic_lemmas = nil"
      output.puts "      enclitic_tags = nil"
      output.puts "    else"
      output.puts "      enclitic_tags = new_enclitic_tags_array.join(\" \")"
      output.puts "      enclitic_lemmas = new_enclitic_lemmas_array.join(\" \")"
      output.puts "    end"
    end

    private_class_method def self.process_condition (condition, condition_number, rule_number, depth, output)
      target = nil
      content = nil
      actions = Array.new
      params = Array.new
      check_default = nil
      filter = nil
      evaluation = nil
      evaluation_at = nil
      evaluation_count = nil
      conditions = nil

      output.puts "# RULE: #{rule_number} DEPTH:#{depth} CONDITION:#{condition_number}"

      condition.elements.each do |element|
        case element.name
        when 'target'
          target = element.get_text.value
        when 'content'
          element.elements.each do |subelement|
            case subelement.name
            when 'evaluation'
              if subelement.get_text
                evaluation = subelement.get_text.value
              end
              if subelement.attribute("at")
                evaluation_at = subelement.attribute("at").value
              else
                STDERR.puts "evaluation attribute not recognized"
                exit(1)
              end
            end
          end
        when 'action'
          actions << element.get_text.value
          params << element.attribute("param")
        when 'filter'
          unless element.get_text == nil
            filter = element.get_text.value
          end
        when 'condition'
        else
          STDERR.puts "unknoun option"
          exit(1)
        end
      end

      conditions = condition.get_elements("condition")

      process_evaluation_content(target, evaluation, evaluation_at, output) unless evaluation_at == nil

      if actions.empty?
        condition_number = 1
        conditions.each do |subcondition|
          process_condition(subcondition, condition_number, rule_number, depth + 1, output)
          condition_number = condition_number + 1
        end
      else
        actions.each_index do |index|
          action = actions[index]
          param = params[index]
          if action == "filter_tags"
            # Remove corresponding tags and call following condition
            filter_tags(filter, output)
          elsif action == "replace_form"
            output.puts "    enclitic = \"#{param}\""
          elsif action == "remove_initial_character"
            output.puts "    enclitic = remove_initial_character(enclitic, \"#{param}\")"
          end

          condition_number = 1
          conditions.each do |subcondition|
            process_condition(subcondition, condition_number, rule_number, depth + 1, output)
            condition_number = condition_number + 1
          end
        end
      end
      output.puts "    end"
    end

    private_class_method def self.replace_wildcards(string) = string.gsub("?", ".").gsub("*", ".*")

    private_class_method def self.expression_or(target, evaluation_at, subexpression_token)
      expression = nil
      if target == "verb_part" and evaluation_at == "end"
        expression = "#{replace_wildcards(subexpression_token)}$"
      elsif evaluation_at == "intermediate_enclitic" or evaluation_at == "next_enclitic" or evaluation_at == "final_enclitic"
        expression = "^#{replace_wildcards(subexpression_token)}$"
      else
        STDERR.puts "evaluation_at unknown:#{evaluation_at}"
        exit(1)
      end
      return expression
    end

    private_class_method def self.expression_and_evaluation_at(target, evaluation_at)
      expression = ""
      if target == "enclitic_part"
        if evaluation_at == "intermediate_enclitic"
          expression = "index < enclitics.length-1 and"
        elsif evaluation_at == "next_enclitic"
          expression = "index < enclitics.length-1 and"
        elsif evaluation_at == "final_enclitic"
          expression = "index == enclitics.length-1 and"
        else
          STDERR.puts "unknow evaluation_at:#{evaluation_at}"
          exit(1)
        end
      end
      return expression
    end

    private_class_method def self.expression_and(target, evaluation_at, subexpression_token, match_operator)
      expression = nil
      if target == "verb_part" and evaluation_at == "end"
        expression = "#{target} #{match_operator} /#{replace_wildcards(subexpression_token)}$/"
      elsif target == "enclitic_part"
        if evaluation_at == "intermediate_enclitic"
          expression = "enclitic #{match_operator} /^#{subexpression_token}$/"
        elsif evaluation_at == "next_enclitic"
          expression = "enclitics[index+1] #{match_operator} /^#{subexpression_token}$/"
        elsif evaluation_at == "final_enclitic"
          expression = "(enclitic #{match_operator} /^#{subexpression_token}$/) and (index == enclitics.length-1)"
        else
          STDERR.puts "unknow evaluation_at:#{evaluation_at}"
          exit(1)
        end
      else
        STDERR.puts "unknow target:#{target}"
        exit(1)
      end
      return expression
    end

    private_class_method def self.process_evaluation_content(target, evaluation, evaluation_at, output)
      # puts "target:#{target}"
      # puts "evaluation_at:#{evaluation_at}"
      # puts "EVALUATION:#{evaluation}"
      evaluation_tokens = evaluation.split()

      or_result_expression = nil
      index = evaluation_tokens.rindex("OR")
      if index != nil
        # Expression with OR
        ors_expression = evaluation_tokens[0..(index + 1)]
        expression = nil
        ors_expression.each do |subexpression_token|
          unless subexpression_token == "OR"
            if expression == nil
              expression = expression_or(target, evaluation_at, subexpression_token)
            else
              expression << "|" << expression_or(target, evaluation_at, subexpression_token)
            end
          end # from unless
        end # from each

        if target == "verb_part" and evaluation_at == "end"
          expression = " #{target} =~ /#{expression}/"
        elsif target == "enclitic_part"
          if evaluation_at == "intermediate_enclitic"
            expression = " index < enclitics.length-1 and enclitic =~ /#{expression}/"
          elsif evaluation_at == "next_enclitic"
            expression = " index < enclitics.length-1 and enclitics[index+1] =~ /#{expression}/"
          elsif evaluation_at == "final_enclitic"
            expression = " index == enclitics.length-1 and enclitic =~ /#{expression}/"
          else
            STDERR.puts "unknow evaluation_at:#{evaluation_at}"
            exit(1)
          end
        else
          puts "unknown target:#{target}"
          exit(1)
        end
        or_result_expression = "    if #{expression}"
      end # from if index != nil

      # puts "or_result_expression: #{or_result_expression}"
      # puts "evaluation: #{evaluation}"

      and_result_expression = nil
      index = evaluation_tokens.index("AND")
      if index != nil
        # Expression with AND
        if or_result_expression == nil
          ands_expression = evaluation_tokens
        else
          ands_expression = evaluation_tokens[index..evaluation_tokens.length]
        end
        expression = nil
        subexpression_token_prev = nil
        ands_expression.each do |subexpression_token|
          unless subexpression_token == "AND" or subexpression_token == "NOT"
            if expression == nil
              if (subexpression_token_prev != nil and subexpression_token_prev == "NOT") or
                (or_result_expression == nil and evaluation =~ /^NOT/)
                expression = expression_and(target, evaluation_at, subexpression_token, "!~")
              else
                expression = expression_and(target, evaluation_at, subexpression_token, "=~")
              end
            else
              if subexpression_token_prev != nil and subexpression_token_prev == "NOT"
                expression << " and " << expression_and(target, evaluation_at, subexpression_token, "!~")
              else
                expression << " and " << expression_and(target, evaluation_at, subexpression_token, "=~")
              end
            end
          end # from unless
          subexpression_token_prev = subexpression_token
        end # from each

        expression_and_evaluation_at = expression_and_evaluation_at(target, evaluation_at)
        if or_result_expression == nil
          expression = "    if #{expression_and_evaluation_at} #{expression}"
        else
          expression = " and #{expression_and_evaluation_at} #{expression}"
        end

        and_result_expression = expression
      end # from if index!=nil

      final_expression = or_result_expression
      if final_expression == nil
        final_expression = and_result_expression
      elsif and_result_expression != nil
        final_expression << and_result_expression
      end

      if final_expression == nil
        # Not OR nor AND expressions
        output.puts "# Not OR nor AND expressions"
        subexpression_token_prev = nil
        expression = nil
        if evaluation =~ /^NOT/
          subexpression_token_prev = "NOT"
          subexpression_token = evaluation_tokens[1]
        else
          subexpression_token = evaluation
        end
        if subexpression_token_prev != nil and subexpression_token_prev == "NOT"
          expression = expression_and(target, evaluation_at, subexpression_token, "!~")
        else
          expression = expression_and(target, evaluation_at, subexpression_token, "=~")
        end
        final_expression = "    if #{expression_and_evaluation_at(target, evaluation_at)} #{expression}"
      end
      output.puts "#{final_expression}"
    end
  end
end

if __FILE__ == $0
  profile = ARGV[0]
  method_output = StringIO.new
  Compilers::EncliticPronounsRules.print_filter_tags_enclitic("#{__dir__}/../../#{profile}/enclitic_pronouns_rules.xml", method_output)

  module_content = <<~RUBY
    module #{profile.camelize}
      module Enclitics
        class FilterTags
    #{method_output.string.indent(4)}
        end
      end
    end
  RUBY

  File.write("#{__dir__}/../../#{profile}/enclitics/filter_tags.rb", module_content)
end
