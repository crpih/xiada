# frozen_string_literal: true
require_relative "../../bin/lemmas/rule"
require_relative "../../bin/lemmas/utils"

module Lemmas
  class HiperRule < Rule
    include Utils

    attr_reader :tags

    def initialize(all_possible_tags, not_adjective_and_not_proper_noun: "^(?!A|Sp).*")
      super(all_possible_tags)
      @tags = tags_for(not_adjective_and_not_proper_noun)
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

    def apply_result(result)
      result.copy(word: "hiper#{result.query.word}", lemma: "hiper#{result.lemma}", hyperlemma: if_hyperlemma(result) { |v| "hiper#{v}" })
    end
  end
end
