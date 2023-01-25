# frozen_string_literal: true

module Utils
  VOWELS = { 'a' => 'á', 'e' => 'é', 'i' => 'í', 'o' => 'ó', 'u' => 'ú' }.freeze
  GHEADA_REPLACEMENTS = { 'gha' => 'ga', 'ghe' => 'gue', 'ghi' => 'gui', 'gho' => 'go', 'ghu' => 'gu' }.freeze

  def tilde_variants(word)
    variants = word.each_char.with_index.filter_map do |char, i|
      next unless VOWELS.keys.include?(char)

      word.dup.tap { |w| w[i] = VOWELS[w[i]] }
    end
    [word, *variants]
  end

  def gheada_variants(word)
    has_gheada = GHEADA_REPLACEMENTS.keys.any? { |k| word.include?(k) }
    variant = has_gheada ? word.gsub(/gh[aeiou]/, GHEADA_REPLACEMENTS) : nil
    [word, *variant]
  end
end
