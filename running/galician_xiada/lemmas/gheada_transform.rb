# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class GheadaTransform < Rule
    GHEADA_REPLACEMENTS = { 'gha' => 'ga', 'ghe' => 'gue', 'ghi' => 'gui', 'gho' => 'go', 'ghu' => 'gu' }.freeze

    def apply_query(query)
      return query unless GHEADA_REPLACEMENTS.keys.any? { |k| query.search_word.include?(k) }

      query.copy(query.search_word.gsub(/gh[aeiou]/, GHEADA_REPLACEMENTS))
    end
  end
end
