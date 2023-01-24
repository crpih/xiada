# frozen_string_literal: true

module Lemmas
  class TildeTransform < Rule
    VOWELS = { 'a' => 'á', 'e' => 'é', 'i' => 'í', 'o' => 'ó', 'u' => 'ú' }.freeze

    def apply_query(query)
      tildes = query.search_word.each_char.with_index.filter_map do |char, i|
        next unless VOWELS.keys.include?(char)

        tilde_search_word = query.search_word.dup.tap { |w| w[i] = VOWELS[w[i]] }
        query.copy(tilde_search_word)
      end
      [query, *tildes]
    end
  end
end
