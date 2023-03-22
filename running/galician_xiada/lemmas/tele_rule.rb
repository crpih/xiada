# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'
require_relative 'prefix_vowel_rule'

module Lemmas
  class TeleRule < PrefixVowelRule
    attr_reader :tags

    def initialize(all_possible_tags)
      super(all_possible_tags, 'tele')
      @tags = tags_for('A.*', 'Sc.*', 'V.*', 'W.*')
    end
  end
end
