# frozen_string_literal: true
require_relative "../../bin/lemmas/rule"
require_relative "../../bin/lemmas/utils"

module Lemmas
  module PrefixParens
    class PrefixParensRule < Rule
      include Utils

      attr_reader :tags

      def initialize(all_possible_tags, prefix, *patterns)
        super(all_possible_tags)
        @prefix = prefix
        @tags = tags_for(*patterns)
      end

      def apply_query(query) = query.word.match(/\A\(#{@prefix}\)(.*)\z/) ? query.copy($1, tags) : nil

      def apply_result(result)
        word = result.query.word
        result.copy(word: "(#{@prefix})#{word}", lemma: "(#{@prefix})#{result.lemma}", hyperlemma: if_hyperlemma(result) { |v| "(#{@prefix})#{v}" })
      end
    end

    class DesRule < PrefixParensRule
      def initialize(all_possible_tags) = super(all_possible_tags, "des", ".*")
    end

    class ExRule < PrefixParensRule
      def initialize(all_possible_tags) = super(all_possible_tags, "ex", ".*")
    end

    class MacroRule < PrefixParensRule
      def initialize(all_possible_tags) = super(all_possible_tags, "macro", ".*")
    end

    class MicroRule < PrefixParensRule
      def initialize(all_possible_tags) = super(all_possible_tags, "micro", ".*")
    end

    class PreRule < PrefixParensRule
      def initialize(all_possible_tags) = super(all_possible_tags, "pre", ".*")
    end

    class ReRule < PrefixParensRule
      def initialize(all_possible_tags) = super(all_possible_tags, "re", ".*")
    end

    class Semi < PrefixParensRule
      def initialize(all_possible_tags) = super(all_possible_tags, "semi", ".*")
    end

    class SubRule < PrefixParensRule
      def initialize(all_possible_tags) = super(all_possible_tags, "sub", ".*")
    end
  end
end
