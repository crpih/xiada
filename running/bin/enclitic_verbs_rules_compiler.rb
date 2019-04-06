# -*- coding: utf-8 -*-
require 'rexml/document'

def filter_tags(filter)
  #puts "filter:#{filter}"
  evaluation_tokens = filter.split(/ /)
  or_result_expression = nil
  index = evaluation_tokens.rindex("OR")
  not_following_or = false
  if index != nil
    # Expression with OR
    if index < (evaluation_tokens.size-2) and evaluation_tokens[index+1] == "NOT"
      not_following_or = true
      ors_expression = evaluation_tokens[0..(index-1)]
    else
      ors_expression = evaluation_tokens[0..(index+1)]
    end

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
    expression = "if verb_tag =~ /#{expression}/"
    expression << " or" if not_following_or
    or_result_expression = expression
  end # from if index != nil
  #puts "or_result_expression: #{or_result_expression}"
  #puts "filter: #{filter}"
  and_result_expression = nil
  index = evaluation_tokens.index("AND")
  index = index - 2 if index != nil and not_following_or
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
            expression = "verb_tag !~ /#{replace_wildcards(subexpression_token)}/"
          else
            expression = "verb_tag =~ /#{replace_wildcards(subexpression_token)}/"
          end
        else
          if subexpression_token_prev != nil and subexpression_token_prev == "NOT"
            expression << " and verb_tag !~ /#{replace_wildcards(subexpression_token)}/"
          else
            expression << " and verb_tag =~ /#{replace_wildcards(subexpression_token)}/"
          end
        end
      end # from unless
      subexpression_token_prev = subexpression_token
    end # from each

    if or_result_expression == nil
      expression = "if #{expression}"
    else
      if not_following_or
        expression = " #{expression}"
      else
        expression = " and #{expression}"
      end
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
      final_expression = "if verb_tag !~ /#{replace_wildcards(expression)}/"      
    else
      final_expression = "if verb_tag =~ /#{replace_wildcards(filter)}/"
    end
  end
  puts "    if verb_tags != nil"
  puts "      verb_tags_array = verb_tags.split(/ /)"
  puts "      new_verb_tags_array = Array.new"
  puts "      verb_tags_array.each do |verb_tag|"
  puts "        #{final_expression}"
  puts "        # tag removing"
  puts "        else"
  puts "          new_verb_tags_array << verb_tag"
  puts "        end"
  puts "      end"
  puts "      if new_verb_tags_array.empty?"
  puts "        verb_tags = nil"
  puts "      else"
  puts "        verb_tags = new_verb_tags_array.join(\" \")"
  puts "      end"
  puts "    end"
end

def process_condition (condition, condition_number, rule_number, depth)
  target = nil
  content = nil
  action = nil
  check_default = nil
  filter = nil
  evaluation = nil
  evaluation_at = nil
  evaluation_count = nil
  conditions = nil
  
  puts "# RULE: #{rule_number} DEPTH:#{depth} CONDITION:#{condition_number}"
  
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
          elsif subelement.attribute("syllable_count")
            evaluation_count = subelement.attribute("syllable_count").value
          else
            puts "evaluation attribute not recognized"
            exit(1)
          end
        end
      end
    when 'action'
      action = element.get_text.value
    when 'check_default'
      check_default = element.get_text.value
    when 'filter'
      unless element.get_text == nil
        filter = element.get_text.value
      end
    when 'condition'
    else
      puts "unknoun option"
      exit(1)
    end
  end

  conditions = condition.get_elements("condition")

  process_evaluation_content(target, evaluation, evaluation_at) unless evaluation_at == nil
  process_evaluation_content_count(evaluation_count) unless evaluation_count == nil
  
  if check_default == "no"
    puts "      check_default = false"
    #puts "      puts \"check_default false in rule:#{rule_number} depth:#{depth} condition:#{condition_number}\"" 
  elsif check_default != nil
    puts "      check_default value not recognized"
    exit(1)
  end    
  #next_condition = condition.next_element
  #if action == "continue" and next_condition != nil
    #puts "ACTION CONTINUE"
    #process_condition(next_condition, condition_number+1, rule_number)
  if action == nil
    condition_number = 1
    conditions.each do |subcondition|
      process_condition(subcondition, condition_number, rule_number, depth+1)
      condition_number = condition_number + 1
    end
  elsif action == "filter_tags"
    #puts "ACTION FILTER_TAGS"
    # Remove corresponding tags and call following condition
    filter_tags(filter)
    condition_number = 1
    conditions.each do |subcondition|
      process_condition(subcondition, condition_number, rule_number, depth+1)
      condition_number = condition_number + 1
    end
  elsif action == "reject"
    #puts "ACTION REJECT"
    # reject
    # result (valid_decomposition, verb_part, enclitic_part, verb_tags)
    #puts "      puts \"REJECTED by rule:#{rule_number} depth:#{depth} condition:#{condition_number}\""
    #puts "      puts \"INFO BEFORE REJECT: verb_part:\#{verb_part}, enclitic_part:\#{enclitic_part}, verb_tags:\#{verb_tags}\""
    puts "      result = [false, nil, nil, nil]"
    puts "      return result"
    #puts "    end"
    #conditions.each do |subcondition|
    #  process_condition(next_condition, condition_number+1, rule_number)
    #end
  end
  puts "    end" #unless action == "reject"
end

def replace_wildcards(string)
  string = string.gsub("?",".")
  string = string.gsub("*",".*")
end

def expression_or(target, evaluation_at, subexpression_token)
  expression = nil
  if evaluation_at == "first"
    expression = "^#{replace_wildcards(subexpression_token)}"
  elsif evaluation_at == "end"
    expression = "#{replace_wildcards(subexpression_token)}$"
  elsif evaluation_at == "not_end"
    expression = "^#{replace_wildcards(subexpression_token)}.$"
  elsif evaluation_at == "all"
    expression = "^#{replace_wildcards(subexpression_token)}$"
  elsif evaluation_at == "anywhere"
    expression = "#{replace_wildcards(subexpression_token)}"
  else
    puts "evaluation_at unknown:#{evaluation_at}"
    exit(1)
  end
  return expression
end

def expression_and(target, evaluation_at, subexpression_token, match_operator)
  expression = ""
  if evaluation_at == "first"
      expression = "#{target} #{match_operator} /^#{replace_wildcards(subexpression_token)}/"
  elsif evaluation_at == "end"
      expression = "#{target} #{match_operator} /#{replace_wildcards(subexpression_token)}$/"
  elsif evaluation_at == "not_end"
      expression = "#{target} #{match_operator} /^#{replace_wildcards(subexpression_token)}.$/"          
  elsif evaluation_at == "all"
      expression = "#{target} #{match_operator} /^#{replace_wildcards(subexpression_token)}$/"
  elsif evaluation_at == "anywhere"
      expression = "#{target} #{match_operator} /#{replace_wildcards(subexpression_token)}/"
  else
    puts "evaluation_at unknown:#{evaluation_at}"
    exit(1)
  end
  return expression
end

def process_evaluation_content(target, evaluation, evaluation_at)
  #puts "target:#{target}"
  #puts "evaluation_at:#{evaluation_at}"
  #puts "EVALUATION:#{evaluation}"
  evaluation_tokens = evaluation.split(/ /)
  
  or_result_expression = nil
  index = evaluation_tokens.rindex("OR")
  if index != nil
    # Expression with OR
    ors_expression = evaluation_tokens[0..(index+1)]
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
    expression = "    if #{target} =~ /#{expression}/"
    or_result_expression = expression
  end # from if index != nil

  #puts "or_result_expression: #{or_result_expression}"
  #puts "evaluation: #{evaluation}"
  
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

    if or_result_expression == nil
      expression = "    if #{expression}"
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
    # Not OR nor AND expressions
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
    
    final_expression = "    if #{expression}"
  end
  puts "#{final_expression}"
end

def process_evaluation_content_count(evaluation_count)
  puts "    if syllable_count(enclitic_part) #{evaluation_count}"
end

def print_validate_decomposition(xml_rules_file_name)

  rule_count = 1
  enclitic_verbs_rules_xml = REXML::Document.new(File.open(xml_rules_file_name))

  puts "  def validate_decomposition(verb_part, verb_tags, enclitic_part)"
  puts "  # validate_decomposition verb_part:\#{verb_part}, verb_tags:\#{verb_tags}, enclitic_part:\#{enclitic_part}"

  puts "    check_default = true"
  enclitic_verbs_rules_xml.elements.each("//rule") do |rule|
    puts "# before rule #{rule_count} verb_part:\#{verb_part}, verb_tags:\#{verb_tags}, enclitic_part:\#{enclitic_part}"
    puts "# RULE: #{rule_count}"
    condition = rule.get_elements("condition")[0]
    process_condition(condition, 1, rule_count, 1)
    rule_count = rule_count + 1
  end
  # default rule
  enclitic_verbs_rules_xml.elements.each("//default_rule") do |rule|
    puts "# before default rule #{rule_count} verb_part:\#{verb_part}, verb_tags:\#{verb_tags}, enclitic_part:\#{enclitic_part}"
    puts "#    DEFAULT RULE: #{rule_count}"
    condition = rule.get_elements("condition")[0]
    puts "    if check_default"
    process_condition(condition, 1, rule_count, 1)
    puts "    end # from default_rule"
  end
  puts "    if verb_tags == nil or verb_tags.empty?"
  puts "      result = [false, nil, nil, nil]"
  puts "      return result"
  puts "    else"
  puts "      result = [true, verb_part, enclitic_part, verb_tags]"
  puts "      return result"
  puts "    end"
  puts "  end # from def validate_decomposition"
end

# main


# This script replaces validate_decomposition function from text coming from STDIN.
# It prints the result to STDOUT.

# In its normal operation, text from STDIN must come from enclitics_processor.base.rb.

if ARGV.size == 1
  xml_rules_file_name = ARGV[0]
  while line = STDIN.gets
    line.chomp!
    if line =~ /def validate_decomposition/
      line = STDIN.gets
      print_validate_decomposition(xml_rules_file_name)
    else
      puts line
    end
  end
else
  puts "Usage:"
  puts "  cat enclitics_processor.base.rb | ruby enclitic_verbs_rules_compiler.rb <xml_rules_file>"
end


