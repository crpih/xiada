# -*- coding: utf-8 -*-
require_relative "../../lib/string_utils.rb"

module LemmatizerGalicianXiada

  def lemmatize(word, tags)
    # mente suffix treatment
    return replace_hiperlemmas(@dw.get_guesser_result("'mente'", word, ['W*']), nil, word) if word =~ /mente$/

    # ísimo/a/os/as suffix treatment

    # amabilísimo => amable
    if word =~ /bilísim[oa]s?$/
      new_word = word.gsub(/bilísim[oa](s)?$/,'ble\1')
      return replace_tags(@dw.get_emissions_info(new_word, ['A*f*']),"^A0","As") if word =~ /as?$/

      return replace_tags(@dw.get_emissions_info(new_word, ['A*m*']),"^A0","As") if word =~ /os?$/

    end
    # riquísimo => rico
    if word =~ /quísim[oa]s?$/
      new_word = word.gsub(/bilísim([oa]s?$)/,'c\1')
      return replace_tags(@dw.get_emissions_info(new_word, ['A*']),"^A0","As")

    end
    # vaguísimo => vago
    if word =~ /guísim[oa]s?$/
      new_word = word.gsub(/guísim([oa]s?)$/,'g\1')
      return replace_tags(@dw.get_emissions_info(new_word, ['A*']),"^A0","As")

    end
    # ambigüísimo => ambiguo / pingüísimo => pingüe
    if word =~ /güísim[oa]s?$/
      new_word = word.gsub(/güísim([oa]s?)$/,'gu\1')
      result = replace_tags(@dw.get_emissions_info(new_word, ['A*']),"^A0","As")
      if result.empty?
        new_word = word.gsub(/güísim[oa](s?)$/,'güe\1')
        return replace_tags(@dw.get_emissions_info(new_word, ['A*f*']),"^A0","As") if word =~/as?$/
        return replace_tags(@dw.get_emissions_info(new_word, ['A*m*']),"^A0","As") if word =~ /os?$/

      end
      return result

    end
    # friísimo => frío
    if word =~ /iísim[oa]s?$/
      new_word = word.gsub(/iísim([oa]s?)$/,'í\1')
      return replace_tags(@dw.get_emissions_info(new_word, ['A*']),"^A0","As")

    end
    # virtualísimo => virtual
    # facilísimo => fácil
    if word =~ /lísim[oa]s?$/
      new_word = word.gsub(/lísim[oa]s?$/,'l')
      new_word << "es" if word =~/s$/
      StringUtils.tilde_combinations(new_word).each do |combination|
        result = replace_tags(@dw.get_emissions_info(combination, ['A*f*']),"^A0","As") if word =~ /as?$/
        result = replace_tags(@dw.get_emissions_info(combination, ['A*m*']),"^A0","As") if word =~ /os?$/
        return result unless result.empty?
      end
    end

    # ferocísimo => feroz
    # docísimo => doce
    if word =~ /císim[oa]s?$/
      new_word = word.gsub(/císim([oa]$)/,'z') if word =~ /[oa]$/
      new_word = word.gsub(/císim([oa]s$)/,'ces') if word =~ /s$/
      result = replace_tags(@dw.get_emissions_info(new_word, ['A*f*']),"^A0","As") if word =~ /as?$/
      result = replace_tags(@dw.get_emissions_info(new_word, ['A*m*']),"^A0","As") if word =~ /os?$/
      return result unless result.empty?

      new_word = word.gsub(/císim[oa](s?)$/,'ce\1')
      return replace_tags(@dw.get_emissions_info(new_word, ['A*f*']),"^A0","As") if word =~ /as?$/
      return replace_tags(@dw.get_emissions_info(new_word, ['A*m*']),"^A0","As") if word =~ /os?$/

    end

    # ísimo (default rule)
    # listísimo => listo
    # gravísimo => grave
    if word =~ /ísim[oa]s?$/
      new_word = word.gsub(/ísim([oa]s?)$/,'\1')
      result = replace_tags(@dw.get_emissions_info(new_word, ['A*']),"^A0","As")
      return result unless result.empty?
      if result.empty?
        new_word = word.gsub(/ísim[oa](s?)$/,'e\1')
        return replace_tags(@dw.get_emissions_info(new_word, ['A*f*']),"^A0","As") if word =~ /as?$/
        return replace_tags(@dw.get_emissions_info(new_word, ['A*m*']),"^A0","As") if word =~ /os?$/
      end
    end

    # auto-
    # auto-axudas => auto-axuda
    if word =~/^auto-/
      new_word = word.gsub(/^auto-/, "")
      result = @dw.get_emissions_info(new_word, ['A*','S*','W*', 'V*'])
      unless result.empty?
        result = replace_lemmas(result, "^(.)", 'auto-\1')
        result = replace_hiperlemmas(result, "^(.)", 'auto-\1')
        return result
      end
    elsif word =~/^auto/
      # auto
      # autoxestión => autoxestión
      # autorreflexión => autorreflexión
      double_r = false
      new_word = word.gsub(/^auto/, "")
      if new_word =~ /^rr/
        new_word = word.gsub(/^autor/, "")
        double_r = true
      end
      result = @dw.get_emissions_info(new_word, ['A*','S*','W*', 'V*'])
      if double_r
        unless result.empty?
          result = replace_lemmas(result, "^(.)", 'autor\1')
          result = replace_hiperlemmas(result, "^(.)", 'autor\1')
        end
      else
        unless result.empty?
          result = replace_lemmas(result, "^(.)", 'auto\1')
          result = replace_hiperlemmas(result, "^(.)", 'auto\1')
        end
      end
      return result unless result.empty?
    end

    # gh treatment
    if word =~ /gh/
      new_word = word.gsub(/gh/,'g')
      return @dw.get_emissions_info(new_word, ['Sc*','A*','V*','W*','N*','Y*','Z*','I*'])
    end

    # iño/a/os/as
    # process only simple words (the ones that don't have - or /)
    if word =~ /iñ[oa]s?$/ and word !~ /[-\/]/

      if word =~ /guiñ[oa]s?$/
        # guiño/a/os/as
        # amiguiño => amigo
        # enruguiñas => enruga
        # albondiguiñas => albóndiga
        # estomaguiño => estómago
        new_word = word.gsub(/guiñ([oa]s?)$/,'g\1')
        result = @dw.get_emissions_info(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'])
        return result unless result.empty?
        if new_word !~/áéíóú/
          new_word = set_tilde(new_word, 3) # Maybe this doesn't cover all the casuistic
          result = @dw.get_emissions_info(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'])
          return result unless result.empty?
        end
      end

      if word =~ /lciñ[oa]s?$/
        # lciño/a/os/as
        # solciño => sol
        # animalciños => animal
        # descalciña => descalzo
        new_word = word.gsub(/(l)ciñ[oa]s?$/,'\1')
        result = @dw.get_emissions_info(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'])
        return result unless result.empty?
        new_word = word.gsub(/(l)ciñ([oa]s?)$/,'\1z\2')
        result = @dw.get_emissions_info(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'])
        return result unless result.empty?
      end
    end

    []
  end

  # Function which is called before accessing emission frequencies for verbs with enclitics pronouns.
  def lemmatize_verb_with_enclitics(left_part)
    # gh treatment
    if left_part =~ /gh/
      new_left_part = left_part.gsub(/gh/,'g')
      return new_left_part
    # auto treatment
    elsif left_part =~ /^autor/
      new_left_part = left_part.gsub(/^autor/,'')
      return new_left_part
    elsif left_part =~ /^auto-?/
      new_left_part = left_part.gsub(/^auto-?/,'')
      return new_left_part
    end
    left_part
  end

  # Function to tranform the word part when restoring a verb form with enclitics.
  def lemmatize_verb_with_enclitics_reverse_word(original_left_part, left_part)
    # gh treatment
    if original_left_part =~ /gh/
      new_left_part = left_part.gsub(/g/,'gh')
      return new_left_part
    # auto treatment
    elsif original_left_part =~/^autor/
      new_left_part = left_part.gsub(/^(.)/,'autor\1')
      return new_left_part
    elsif original_left_part =~/^(auto-?)/
      new_left_part = left_part.gsub(/^(.)/,"#{$1}\\1")
      return new_left_part
    end
    left_part
  end

  # Function to tranform the lemma part when restoring a verb form with enclitics.
  def lemmatize_verb_with_enclitics_reverse_lemma(original_left_part, left_part)
    if original_left_part =~/^(auto-?)/
      new_left_part = left_part.gsub(/^(.)/,"#{$1}\\1")
      return new_left_part
    end
    left_part
  end

  # Function to tranform the hiperlemma part when restoring a verb form with enclitics.
  def lemmatize_verb_with_enclitics_reverse_hiperlemma(original_left_part, left_part)
    if original_left_part =~/^(auto-?)/
      new_left_part = left_part.gsub(/^(.)/,"#{$1}\\1")
      return new_left_part
    end
    left_part
  end

  # Function which replace a vowel by the corresponding tilde one.
  # position is the vowel order from the end.

  def set_tilde(word, position)
    characters = word.each_grapheme_cluster.to_a
    vowel_positions = characters.each_with_index
                                .select { |c, _| %w[a e i o u].include?(c) }
                                .map(&:last)
    vowel_index = vowel_positions[-position]
    characters[vowel_index] = "#{characters[vowel_index]}\u0301".unicode_normalize
    characters.join
  end

end

# periodico => vowel + vowel does not work

def set_tilde(word, vowel_position)
  case vowel_position
  when 2
    word.gsub(/([^aeiou]+[aeiou][^aeiou]+)([aeiou])([^aeiou]+[aeiou]s?$)/) { $1+"-"+$3 }
  when 3
    word.gsub(/([^aeiou]+)([aeiou])([^aeiou]+[aeiou][^aeiou]+[aeiou]s?$)/) { $1+"-"+$3 }
  when 4
    word.gsub(/([^aeiou]+)([aeiou])([^aeiou]+[aeiou][^aeiou]+[aeiou][^aeiou]+[aeiou]s?$)/) { $1+"-"+$3 }
  else
    word
  end
end