# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'
require_relative 'prefix_vowel_rule'

module Lemmas
  class MultiRule < PrefixVowelRule
  attr_reader :tags

    def initialize(all_possible_tags, adjective: 'A.*', noun_common: 'Sc.*', verb: 'V.*', adverb: 'W.*')
      super(all_possible_tags, 'multi')
      @tags = tags_for(adjective, noun_common, verb, adverb)
    end

    def apply_query(query)
      return if %w[multidade multidude].include?(query.word)

      super(query)
    end
  end
end
