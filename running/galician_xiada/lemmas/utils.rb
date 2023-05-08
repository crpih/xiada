# frozen_string_literal: true

module Utils
  VOWELS = { 'a' => 'á', 'e' => 'é', 'i' => 'í', 'o' => 'ó', 'u' => 'ú' }.freeze
  GHEADA_REPLACEMENTS = {
    'gha' => 'ga',
    'ghá' => 'gá',
    'ghe' => 'gue',
    'ghé' => 'gué',
    'ghi' => 'gui',
    'ghí' => 'guí',
    'gho' => 'go',
    'ghó' => 'gó',
    'ghu' => 'gu',
    'ghú' => 'gú'
  }.freeze
  SESEO_REPLACEMENTS = {
    'sa' => 'za',
    'sá' => 'zá',
    'se' => 'ce',
    'sé' => 'cé',
    'si' => 'ci',
    'sí' => 'cí',
    'so' => 'zo',
    'só' => 'zó',
    'su' => 'zu',
    'sú' => 'zú'
  }.freeze

  def tilde_variants(word)
    variants = word.each_char.with_index.filter_map do |char, i|
      next unless VOWELS.keys.include?(char)

      word.dup.tap { |w| w[i] = VOWELS[w[i]] }
    end
    [word, *variants]
  end

  def gheada_variants(word)
    has_gheada = GHEADA_REPLACEMENTS.keys.any? { |k| word.include?(k) }
    variant = has_gheada ? word.gsub(/gh[aáeéiíoóuú]/, GHEADA_REPLACEMENTS) : nil
    [word, *variant]
  end

  def seseo_variants(word)
    has_seseo = SESEO_REPLACEMENTS.keys.any? { |k| word.include?(k) }
    variant = has_seseo ? word.gsub(/s[aáeéiíoóuú]/, SESEO_REPLACEMENTS) : nil
    [word, *variant]
  end

  def if_hyperlemma(result)
    return result.hyperlemma if result.hyperlemma.nil? || result.hyperlemma.empty?

    yield result.hyperlemma
  end
end
