# frozen_string_literal: true
require_relative "../../bin/lemmas/rule"
require_relative "prefix_vowel_rule"

module Lemmas
  class AutoRule < PrefixVowelRule
    attr_reader :tags

    def initialize(all_possible_tags, adjective: "A.*", noun: "S.*", adverb: "W.*", verb: "V.*")
      super(all_possible_tags, "auto")
      @tags = tags_for(adjective, noun, adverb, verb)
    end
  end
end
