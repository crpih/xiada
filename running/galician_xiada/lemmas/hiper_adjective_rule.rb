# frozen_string_literal: true
require_relative "../../bin/lemmas/rule"
require_relative "../../bin/lemmas/utils"

module Lemmas
  class HiperAdjectiveRule < Rule
    include Utils

    attr_reader :tags

    def initialize(all_possible_tags, adjective: "A.*", superlative: ->(t) { "#{t[0]}s#{t[2..]}" })
      super(all_possible_tags)
      @tags = tags_for(adjective)
      @superlative = superlative
    end

    def apply_query(query)
      return unless query.word.match(/\Ahiper(-?)(.*)\z/)

      hyphen, base = Regexp.last_match.captures

      if hyphen.empty? && base.start_with?("rr")
        query.copy(base.delete_prefix("r"), tags)
      else
        query.copy(base, tags)
      end
    end

    def apply_result(result) = result.copy(tag: @superlative.(result.tag))
  end
end
