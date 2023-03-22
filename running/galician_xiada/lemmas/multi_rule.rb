# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'
require_relative 'prefix_vowel_rule'

module Lemmas
  class MultiRule < PrefixVowelRule
  attr_reader :tags

    def initialize(all_possible_tags)
      super(all_possible_tags, 'multi')
      @tags = tags_for('A.*', 'Sc.*', 'V.*', 'W.*')
    end

    def apply_query(query)
      return if %w[multidade multidude].include?(query.word)

      super(query)
    end
  end
end
