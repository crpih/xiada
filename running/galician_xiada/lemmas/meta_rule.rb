# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'
require_relative 'prefix_vowel_rule'

module Lemmas
  class MetaRule < PrefixVowelRule
    attr_reader :tags

    def initialize(all_possible_tags)
      super(all_possible_tags, 'meta')
      @tags = tags_for('A.*', 'Sc.*')
    end

    def apply_query(query)
      return if %w[meta-lo meta-la meta-los meta-las].include?(query.word)
      super(query)
    end
  end
end
