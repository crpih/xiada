# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class MacroRule < Rule
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

      if hyphen.empty? && result.lemma.start_with?('o')
        result.copy(nil, "macr#{result.lemma}", "macro#{result.hyperlemma}")
      elsif result.lemma.start_with?('r')
        result.copy(nil, "macro#{hyphen}#{result.lemma}", "macror#{result.hyperlemma}")
      else
        result.copy(nil, "macro#{hyphen}#{result.lemma}", "macro#{result.hyperlemma}")
      end
    end
  end
end
