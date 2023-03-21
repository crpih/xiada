# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class MicroRule < Rule
    include Utils

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('A.*', 'Sc.*', 'V.*')
    end

    def apply_query(query)
      return unless query.word.match(/\Amicro(-?)(.*)\z/)

      hyphen, base = Regexp.last_match.captures

      if hyphen.empty?
        if base.start_with?('rr')
          query.copy(base.delete_prefix('r'), @tags)
        else
          [query.copy(base, @tags), query.copy("o#{base}", @tags)]
        end
      else
        query.copy(base, @tags)
      end
    end

    def apply_result(query, result)
      hyphen = query.prev.word.match(/\Amicro(-?)/).captures.first

      # Keep double 'o' in lemma in the case of 'microorganismo', remove it in 'microrganismo'
      if hyphen.empty? && result.lemma.start_with?('o') && !query.prev.word.match?(/\Amicro[oó]/)
        result.copy(nil, "micro#{result.lemma}", if_hyperlemma(result) { |v| "micro#{v}" })
      elsif hyphen.empty? && result.lemma.start_with?('r')
        result.copy(nil, "micror#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "micror#{v}" })
      elsif result.lemma.start_with?('r')
        result.copy(nil, "micro#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "micror#{v}" })
      else
        result.copy(nil, "micro#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "micro#{v}" })
      end
    end
  end
end
