# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class MacroRule < Rule
    include Utils

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('A.*', 'Sc.*', 'V.*')
    end

    def apply_query(query)
      return unless query.word.match(/\Amacro(-?)(.*)\z/)

      hyphen, base = Regexp.last_match.captures

      if hyphen.empty? && base.start_with?('rr')
        query.copy(base.delete_prefix('r'), @tags)
      else
        query.copy(base, @tags)
      end
    end

    def apply_result(query, result)
      hyphen = query.prev.word.match(/\Amacro(-?)/).captures.first

      # Keep double 'o' in lemma in the case of 'macroorganismo', remove it in 'macrorganismo'
      if hyphen.empty? && result.lemma.start_with?('o') && !query.prev.word.match?(/\Amacro[oó]/)
        result.copy(nil, "macr#{result.lemma}", if_hyperlemma(result) { |v| "macro#{v}" })
      elsif hyphen.empty? && result.lemma.start_with?('r')
        result.copy(nil, "macror#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "macror#{v}" })
      elsif result.lemma.start_with?('r')
        result.copy(nil, "macro#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "macror#{v}" })
      else
        result.copy(nil, "macro#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "macro#{v}" })
      end
    end
  end
end
