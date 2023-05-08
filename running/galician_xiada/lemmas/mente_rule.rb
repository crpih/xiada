# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class MenteRule < Rule

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @w_tags = tags_for('W.*')
    end
    def apply_query(query)
      return unless query.word.end_with?('mente')

      query.copy(query.word, @w_tags)
    end

    def apply_result(query, result)
      result.copy(nil, nil, query.word)
    end
  end
end
