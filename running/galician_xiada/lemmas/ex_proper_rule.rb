# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class ExProperRule < Rule
    def initialize(_all_possible_tags, noun_proper = 'Sp00')
      @tags = [noun_proper]
    end

    def apply_query(query)
      return unless query.word.match(/\Aex-(\p{Lu}\p{Ll}{2,})\z/)

      base = Regexp.last_match.captures.first
      query.copy(base)
    end

    def apply_result(result)
      result.copy(lemma: "ex-#{result.lemma}", hyperlemma: '')
    end
  end
end
