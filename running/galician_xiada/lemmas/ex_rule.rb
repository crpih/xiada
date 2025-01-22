# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'
require_relative '../../bin/lemmas/utils'

module Lemmas
  class ExRule < Rule
    include Utils

    def initialize(all_possible_tags, adjective: 'A.*', noun_common: 'Sc.*')
      super(all_possible_tags)
      @tags = tags_for(adjective, noun_common)
    end

    def apply_query(query)
      return unless query.word.match(/\Aex-(.*)\z/)

      base = Regexp.last_match.captures.first
      query.copy(base, @tags)
    end

    def apply_result(result)
      result.copy(lemma: "ex-#{result.lemma}", hyperlemma: if_hyperlemma(result) { |v| "ex#{v}" })
    end
  end
end
