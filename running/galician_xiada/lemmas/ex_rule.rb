# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class ExRule < Rule
    include Utils

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('A.*', 'Sc.*')
    end

    def apply_query(query)
      return unless query.word.match(/\Aex-(.*)\z/)

      base = Regexp.last_match.captures.first
      query.copy(base, @tags)
    end

    def apply_result(query, result)
      result.copy(nil, "ex-#{result.lemma}", if_hyperlemma(result) { |v| "ex#{v}" })
    end
  end
end
