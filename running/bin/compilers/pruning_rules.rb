require "stringio"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/string/indent"

module Compilers
  module PruningRules
    def self.build_module(module_name)
      <<~RUBY
        module #{module_name}
          class PruningSystem
            def initialize; end

            def process(window)
        #{yield.indent(6)}
              return 0
            end

            private

            def match_some_lemma (lemmas, string) = lemmas.any? { |l| l =~ /^(\#{string})$/ }

            def print_window(window)
              window.each do |element|
                if element != nil
                  STDERR.print "(\#{element[0]}/\#{element[1]}/\#{element[2]}/\#{element[3]})"
                else
                  STDERR.print "(empty/empty/empty/empty)"
                end
              end
              STDERR.puts ""
            end
          end
        end
      RUBY
    end

    def self.print_pruning_rule(line, output)
      output.puts "\# RULE: #{line}"
      output.print "if "
      index_breaking_point = 0
      line.split(/\t/).each_with_index do |component, index|
        output.print " and " unless index == 0
        breaking_point = print_component_condition(component, index, output)
        index_breaking_point = index + 1 if breaking_point
      end
      if index_breaking_point == 0
        STDERR.puts "index_breaking_point = 0!!! for rule #{line}"
        exit 1
      end
      output.print "\n"
      # puts "STDERR.puts \"rejected by RULE #{line}\"" # Important line for debugging
      output.puts "return #{index_breaking_point}"
      output.puts "end"
    end

    private_class_method def self.adapt_word_or_lemma(word_or_lemma) = word_or_lemma.gsub("*", ".*").gsub("?", ".?").gsub("$", "\\$")

    private_class_method def self.get_condition_string(value)
      return if value == "_"

      value.start_with?("!") ? yield(true, value[1..-1]) : yield(false, value)
    end

    private_class_method def self.get_word_condition_string(value, index)
      get_condition_string(value) do |negation, extracted_value|
        if negation
          "(window[#{index}][0] !~ /^(#{adapt_word_or_lemma(extracted_value)})$/)"
        else
          "(window[#{index}][0] =~ /^(#{adapt_word_or_lemma(extracted_value)})$/)"
        end
      end
    end

    private_class_method def self.get_lemma_condition_string(value, index)
      get_condition_string(value) do |negation, extracted_value|
        if negation
          "(!match_some_lemma(window[#{index}][2],\"#{extracted_value}\"))"
        else
          "(match_some_lemma(window[#{index}][2],\"#{extracted_value}\"))"
        end
      end
    end

    private_class_method def self.get_unit_condition_string(value, index)
      get_condition_string(value) do |negation, extracted_value|
        if negation
          "(window[#{index}][3] !~ /^(#{adapt_word_or_lemma(extracted_value)})$/)"
        else
          "(window[#{index}][3] =~ /^(#{adapt_word_or_lemma(extracted_value)})$/)"
        end
      end
    end

    private_class_method def self.adapt_tag(tag) = tag.gsub("*", ".*").gsub("?", ".?")

    private_class_method def self.get_tag_condition_string(tag, index)
      get_condition_string(tag) do |negation, extracted_value|
        if negation
          "(window[#{index}][1] !~ /^(#{adapt_tag(extracted_value)})$/)"
        else
          "(window[#{index}][1] =~ /^(#{adapt_tag(extracted_value)})$/)"
        end
      end
    end

    private_class_method def self.print_component_condition(component, index, output)
      word, tag, lemma, unit, breaking_point, *_ = component.split(/,/)

      # puts "\n\nword:#{word}, tag:#{tag}, lemma:#{lemma}, unit:#{unit}"

      word_string = get_word_condition_string(word, index)
      tag_string = get_tag_condition_string(tag, index)
      lemma_string = get_lemma_condition_string(lemma, index)
      unit_string = get_unit_condition_string(unit, index)

      # puts "\n\nword_string: #{word_string}, tag_string: #{tag_string}, lemma_string: #{lemma_string}, unit_string: #{unit_string}"

      first_element = false
      if word_string
        output.print word_string
        first_element = true
      end
      if tag_string
        output.print " and " if first_element
        output.print tag_string
        first_element = true
      end
      if lemma_string
        output.print " and " if first_element
        output.print lemma_string
        first_element = true
      end
      if unit_string
        output.print " and " if first_element
        output.print unit_string
      end

      breaking_point != nil
    end
  end
end

if __FILE__ == $0
  profile = ARGV[0]
  rules_lines = File.read("#{__dir__}/../../#{profile}/pruning_rules.txt")
                    .split("\n")
                    .reject { |line| line.start_with?("#") || line.empty? }

  module_content = Compilers::PruningRules.build_module(profile.camelize) do
    rules_output = StringIO.new
    rules_lines.each { |l| Compilers::PruningRules.print_pruning_rule(l, rules_output) }
    rules_output.string
  end

  File.write("#{__dir__}/../../#{profile}/pruning_system.rb", module_content)
end
