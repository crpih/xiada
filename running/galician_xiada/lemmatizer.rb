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
        # solciño => sol (Scms)
        # animalciños => animal (Scmp)
        # descalciña => descalzo
        new_word = word.gsub(/(l)ciñ[oa]$/,'\1')
        result = @dw.get_emissions_info(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'])
        return result unless result.empty?
        new_word = word.gsub(/(l)ciñ[oa]s$/,'\1es')
        result = @dw.get_emissions_info(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'])
        return result unless result.empty?
        new_word = word.gsub(/(l)ciñ([oa])$/,'\1z\2')
        result = @dw.get_emissions_info(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'])
        return result unless result.empty?
        new_word = word.gsub(/(l)ciñ([oa])s$/,'\1z\2s')
        result = @dw.get_emissions_info(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'])
        return result unless result.empty?
      end
      if word =~ /quiñ[oa]s?$/
        # quiño/a/os/as
        # plaquiñas => placas
        # retaquiños => retacos
        new_word = word.gsub(/quiñ([oa]s?)$/,'c\1')
        result = @dw.get_emissions_info(new_word, ['Sc*','A0*','V0p0*','W*','I*'])
        return result unless result.empty?
        result = @dw.get_emissions_info(new_word, ['V?i*','V?s','V0m*'])
        unless result.empty?
          if new_word !~ /áéíóú/
            new_word = set_tilde(new_word, 3) # Maybe this doesn't cover all the casuistic
            # musiquiña => música / musiquiño => músico
            result = @dw.get_emissions_info(new_word, [])
            return result unless result.empty?
          end
        end
        if new_word !~ /áéíóú/
          new_word = set_tilde(new_word, 3) # Maybe this doesn't cover all the casuistic
          result = @dw.get_emissions_info(new_word, ['Sc*','A0*','V0p0*','W*','I*'])
          # faisquiñas => faíscas / periodiquiños => periódicos / politiquiñas =>> políticas
          return result unless result.empty?
        end
        new_word = word.gsub(/quiñ[oa](s?)$/,'que\1')
        # bosquiños => bosques
        result = @dw.get_emissions_info(new_word, ['Sc*','A0*','V0p0*','W*','I*'])
        return result unless result.empty?
      end
      if word =~ /nciñ[oa]s?$/
        if word =~ /onciños?$/
          # algodonciño => algodón
          # cartonciños => cartóns
          new_word = word.gsub(/onciño(s?)$/,'ón\1')
          result = @dw.get_emissions_info(new_word, [])
          return result unless result.empty?
        end
        if word =~ /onciñas?$/
          # cancionciña => canción
          new_word = word.gsub(/onciña(s?)$/,'ón\1')
          result = @dw.get_emissions_info(new_word, ['Scf*','A0f*'])
          return result unless result.empty?
          # chaponciñas => chaponas
          new_word = word.gsub(/onciña(s?)$/,'ona\1')
          result = @dw.get_emissions_info(new_word, ['Scf*','A0f*'])
          return result unless result.empty?          
        end
        if word =~ /anciñ[oa]s?$/
          # garavanciño => garavanzo
          # crianciñas => crianzas
          new_word = word.gsub(/anciñ([oa]s?)$/,'anz\1')
          result = @dw.get_emissions_info(new_word, [])
          return result unless result.empty?
          # mazanciña => mazán
          new_word = word.gsub(/anciñ[oa](s?)$/,'án\1')
          result = @dw.get_emissions_info(new_word, [])
          return result unless result.empty?
          # vranciño => vran
          new_word = word.gsub(/anciñ[oa](s?)$/,'an\1')
          result = @dw.get_emissions_info(new_word, [])
          return result unless result.empty?
        end
        if word =~ /enciñas?$/
          # trenciñas => tranzas
          # fervenciña => fervenza
          new_word = word.gsub(/enciñ(as?)$/,'enz\1')
          result = @dw.get_emissions_info(new_word, [])
          return result unless result.empty?
        end
        if word =~ /inciñ[oa]s?$/
          # pinciñas => pinzas
          new_word = word.gsub(/inciñ([oa]s?)$/,'inz\1')
          result = @dw.get_emissions_info(new_word, [])
          return result unless result.empty?
          # xardinciños => xardíns
          new_word = word.gsub(/inciñ[oa](s?)$/,'ín\1')
          result = @dw.get_emissions_info(new_word, [])
          return result unless result.empty?
        end
      end
      if word =~ /ndiñ[oa]s?$/
        # segundiño => segundo
        # brandiños => brandos
        # pasandiño => pasando
        new_word = word.gsub(/ndiñ([oa]s?)$/,'nd\1')
        result = @dw.get_emissions_info(new_word, [])
        return result unless result.empty?
      end
      if word =~ /rciñ[oa]s?$/
        # cogorciña => cogorza
        # verciñas => verzas
        # almorciño => almorzo
        new_word = word.gsub(/rciñ([oa]s?)$/,'rz\1')
        result = @dw.get_emissions_info(new_word, ['S*','A*'])
        return result unless result.empty?

        # calorciño => calor
        # altarciño => altar
        # amorciño => amor
        # calamarciños => calamares
        if word =~ /rciño$/
          new_word = word.gsub(/rciño$/,'r')
          result =  replace_tags(@dw.get_emissions_info(new_word, ['A*','S*']),"(..)..","\\1ms") if word =~ /o$/
          return result unless result.empty?
        end
        if word =~ /rciños$/
          new_word = word.gsub(/rciños$/,'res')
          result =  replace_tags(@dw.get_emissions_info(new_word, ['A*','S*']),"(..)..","\\1mp") if word =~ /os$/
          return result unless result.empty?
        end
        if word =~ /rciña$/
          new_word = word.gsub(/rciña$/,'r')
          result =  replace_tags(@dw.get_emissions_info(new_word, ['A*','S*']),"(..)..","\\1fs") if word =~ /a$/
          return result unless result.empty?
        end
        if word =~ /rciñas$/
          new_word = word.gsub(/rciñas$/,'res')
          result =  replace_tags(@dw.get_emissions_info(new_word, ['A*','S*']),"(..)..","\\1fp") if word =~ /as$/
          return result unless result.empty?
        end
      end
      if word =~ /[fmvx]iñ[oa]s?$/
        # orfiños => orfos
        # demiños => demos
        # oviños => ovos
        # bruxiñas => bruxas
        # debuxiños => debuxos
        new_word = word.gsub(/([fmvx])iñ([oa]s?)$/,'\1\2')
        result = @dw.get_emissions_info(new_word, ['S*','A*','I*'])
        return result unless result.empty?
        # xefiño => xefe
        # lumiño => lume
        # suaviñas => suaves
        # traxiños => traxes
        new_word = word.gsub(/([fmvx])iñ([oa]s?)$/,'\1e')
        result = @dw.get_emissions_info(new_word, ['S*','A*','I*'])
        return result unless result.empty?
      end
      if word =~ /tiñ[oa]s?$/
        # gatiños => gatos
        # azoutiña => azouta
        new_word = word.gsub(/tiñ([oa]s?)$/,'t\1')
        result = @dw.get_emissions_info(new_word, ['S*','A*','W*','I*'])
        return result unless result.empty?
        # tomatiños => tomates
        # amantiñas => amantes
        new_word = word.gsub(/tiñ[oa](s?)$/,'te\1')
        result = @dw.get_emissions_info(new_word, ['S*','A*'])
        return result unless result.empty?
      end
      if word =~ /[bpñ]iñ[oa]s?$/
        # trapiño => trapo
        # castañiñas => castañas
        # viñiño => viño
        # barbiña => barba
        # xoubiñas => xouba
        new_word = word.gsub(/([bpñ])iñ([oa]s?)$/,'\1\2')
        result = @dw.get_emissions_info(new_word, ['S*','A*'])
        return result unless result.empty?
      end
      if word =~ /biñ[oa]s?$/
        # nubiñas => nubes
        new_word = word.gsub(/biñ[oa]s?$/,'be')
        result = @dw.get_emissions_info(new_word, ['S*','A*'])
        return result unless result.empty?
      end
      if word =~ /chiñ[oa]s?$/
        # estuchiño => estuche
        new_word = word.gsub(/chiñ[oa]s?$/,'che')
        result = @dw.get_emissions_info(new_word, ['S*','A*'])
        return result unless result.empty?
      end
      if word =~ /lliñ[oa]s?$/
        # ovelliñas => ovellas
        new_word = word.gsub(/(ll)iñ([oa]s?)$/,'\1\2')
        result = @dw.get_emissions_info(new_word, ['S*','A*'])
        return result unless result.empty?
      end
      if word =~ /rriñ[oa]s?$/
        # aforriños => aforros
        # churriñas => churras
        new_word = word.gsub(/(rr)iñ([oa]s?)$/,'\1\2')
        result = @dw.get_emissions_info(new_word, ['S*','A*'])
        return result unless result.empty?
      end
      if word =~ /chiñ[oa]s?$/
        # aforriños => aforros
        # churriñas => churras
        new_word = word.gsub(/(ch)iñ([oa]s?)$/,'\1\2')
        result = @dw.get_emissions_info(new_word, ['S*','A*'])
        return result unless result.empty?
      end
      if word =~ /ghiñ[oa]s?$/
        # amighiñas => amigas
        new_word = word.gsub(/ghiñ([oa]s?)$/,'g\1')
        result = @dw.get_emissions_info(new_word, ['S*','A*'])
        return result unless result.empty?
      end
      if word =~ /diñ[oa]s?$/ and word !~ /ndiñ[oa]s?$/
        # cadradiños => cadrados
        # todiñas => todas
        new_word = word.gsub(/diñ([oa]s?)$/,'d\1')
        result = @dw.get_emissions_info(new_word, ['S*','A*','I*'])
        return result unless result.empty?
      end
      if word =~ /diñ[oa]s?$/ and word !~ /ndiñ[oa]s?$/
        # bidogiño => bigode
        # meirandiño => meirande
        # humildiño => humilde
        new_word = word.gsub(/diñ[oa](s?)$/,'de\1')
        result = @dw.get_emissions_info(new_word, ['S*','A*','I*'])
        return result unless result.empty?
      end
      if word =~ /uesiñ[oa]s?$/
        if word =~/uesiño$/
          # marquesiño => marqués
          new_word = word.gsub(/uesiño$/,'ués')
          result = @dw.get_emissions_info(new_word, ['S*','A*'])
          return result unless result.empty?
        end
        if word =~/uesiña$/
          # marquesiña => marquesa
          new_word = word.gsub(/uesiña$/,'uesa')
          result = @dw.get_emissions_info(new_word, ['S*','A*'])
          return result unless result.empty?
        end
        if word =~/uesiños$/
          # marquesiños => marqueses
          new_word = word.gsub(/uesiños$/,'ueses')
          result = @dw.get_emissions_info(new_word, ['S*','A*'])
          return result unless result.empty?
        end
        if word =~/uesiñas$/
          # marquesiñas => marquesas
          new_word = word.gsub(/uesiñas$/,'uesas')
          result = @dw.get_emissions_info(new_word, ['S*','A*'])
          return result unless result.empty?
        end
      end
      STDERR.puts "word:#{word}"
      if word =~ /siñ[oa]s?$/ and word !~ /uesiñ[oa]s?$/
        # tesiños => tesos
        # raposiña => raposa
        # camisiñas => camisas
        new_word = word.gsub(/siñ([oa]s?)$/,'s\1')
        result = @dw.get_emissions_info(new_word, ['S*','A*'])
        return result unless result.empty?
      end

      if word =~ /siñ[oa]s?$/ and word !~ /uesiñ[oa]s?$/
        # tesiña => tese
        # tosiña => tose
        new_word = word.gsub(/siñ[oa](s?)$/,'se\1')
        result = @dw.get_emissions_info(new_word, ['S*','A*'])
        return result unless result.empty?
      end






      # gh treatment
      if word =~ /gh/
        new_word = word.gsub(/gh/,'g')
        return @dw.get_emissions_info(new_word, ['Sc*','A*','V*','W*','N*','Y*','Z*','I*'])
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
    if position <= vowel_positions.size
      vowel_index = vowel_positions[-position]
      characters[vowel_index] = "#{characters[vowel_index]}\u0301".unicode_normalize
      characters.join
    else
      return word
    end
  end

end