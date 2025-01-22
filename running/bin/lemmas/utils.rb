# frozen_string_literal: true

module Lemmas
  module Utils
    # NOTE: This function breaks statistical model in some way
    def replace_tags(dw_result, search_exp, replace_exp)
      result = Array.new
      dw_result.each do |row|
        row[0].gsub!(/#{search_exp}/,"#{replace_exp}")
        result << row
      end
      return result
    end

    # NOTE: This function breaks statistical model in some way
    def replace_lemmas(dw_result, search_exp, replace_exp)
      result = Array.new
      dw_result.each do |row|
        row[1].gsub!(/#{search_exp}/,"#{replace_exp}")
        result << row
      end
      return result
    end

    def replace_hiperlemmas(dw_result, search_exp, replace_exp)
      result = Array.new
      dw_result.each do |row|
        if search_exp && replace_exp
          row[2].gsub!(/#{search_exp}/,"#{replace_exp}") if row[2]
        else
          row[2]="#{replace_exp}" unless search_exp
        end
        result << row
      end
      return result
    end

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
      'ghú' => 'gú',
      'ghra' => 'gra',
      'ghrá' => 'grá',
      'ghre' => 'gre',
      'ghré' => 'gré',
      'ghri' => 'gri',
      'ghrí' => 'grí',
      'ghro' => 'gro',
      'ghró' => 'gró',
      'ghru' => 'gru',
      'ghrú' => 'grú',
      'ghla' => 'gla',
      'ghlá' => 'glá',
      'ghle' => 'gle',
      'ghlé' => 'glé',
      'ghli' => 'gli',
      'ghlí' => 'glí',
      'ghlo' => 'glo',
      'ghló' => 'gló',
      'ghlu' => 'glu',
      'ghlú' => 'glú',
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
      'sú' => 'zú',
    }.freeze

    def unaccent_variants(word)
      unaccent = word.unicode_normalize(:nfd).gsub(/\p{Mn}/, '').unicode_normalize(:nfc)
      word == unaccent ? [word] : [word, unaccent]
    end

    def tilde_variants(word)
      variants = word.each_char.with_index.filter_map do |char, i|
        next unless VOWELS.keys.include?(char)

        word.dup.tap { |w| w[i] = VOWELS[w[i]] }
      end
      [word, *variants]
    end

    def gheada_variants(word)
      has_gheada = GHEADA_REPLACEMENTS.keys.any? { |k| word.include?(k) }
      variant = has_gheada ? word.gsub(/gh[rl]?[aáeéiíoóuú]/, GHEADA_REPLACEMENTS) : nil
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
end
