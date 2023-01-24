# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class MenteRule < Rule

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @w_tags = tags_for('W.*')
    end
    def apply_query(query)
      return unless query.search_word.end_with?('mente')

      query.copy(query.search_word, @w_tags)
    end

    def apply_result(result)
      result.copy(nil, nil, result.query.word)
    end
  end
end
