# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class MenteRule < Rule

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('W.*')
    end
    def apply_query(query)
      return if !query.word.end_with?('mente') || !query.tags.any? { |t| t.start_with?('Sp') }

      query.copy(query.word, @tags)
    end

    def apply_result(result)
      result.copy(nil, nil, result.query.word)
    end
  end
end
