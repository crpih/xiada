# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class TeleRule < Rule
    include Utils

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('A.*', 'Sc.*', 'V.*', 'W.*')
    end

    def apply_query(query)
      return unless query.word.match(/\Atele(-?)(.*)\z/)

      hyphen, base = Regexp.last_match.captures

      if hyphen.empty?
        if base.start_with?('rr')
          query.copy(base.delete_prefix('r'), @tags)
        else
          [query.copy(base, @tags), query.copy("e#{base}", @tags)]
        end
      else
        query.copy(base, @tags)
      end
    end

    def apply_result(query, result)
      hyphen, base = query.prev.word.match(/\Atele(-?)(.*)/).captures

      if hyphen.empty? && base.start_with?('e')
        result.copy(nil, "tele#{result.lemma}", if_hyperlemma(result) { |v| "tele#{v}" })
      elsif hyphen.empty? && result.lemma.start_with?('e')
        result.copy(nil, "tel#{result.lemma}", if_hyperlemma(result) { |v| "tele#{v}" })
      elsif result.lemma.start_with?('r')
        result.copy(nil, "teler#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "teler#{v}" })
      else
        result.copy(nil, "tele#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "tele#{v}" })
      end
    end
  end
end
