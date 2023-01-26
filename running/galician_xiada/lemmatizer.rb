# -*- coding: utf-8 -*-
require_relative "../../lib/string_utils.rb"

module LemmatizerGalicianXiada

  def lemmatize(word, tags)
    #STDERR.puts "lemmatize:#{word}"

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
      new_word = word.gsub(/quísim([oa]s?$)/,'c\1')
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
    # Plural exception: cool
    if word =~ /lísim[oa]s?$/
      new_word = word.gsub(/lísim[oa]s?$/,'l')
      new_word << "es" if word =~/s$/ and new_word != 'cool'
      StringUtils.tilde_combinations(new_word).each do |combination|
        result = replace_tags(@dw.get_emissions_info(combination, ['A_fs']),"^A0fs","Asfs") if word =~ /a$/
        result = replace_tags(@dw.get_emissions_info(combination, ['A_fp']),"^A0fp","Asfp") if word =~ /as$/
        result = replace_tags(@dw.get_emissions_info(combination, ['A_ms']),"^A0ms","Asms") if word =~ /o$/
        result = replace_tags(@dw.get_emissions_info(combination, ['A_mp']),"^A0mp","Asmp") if word =~ /os$/
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

    # preparadísimo => preparado
    # convencidísimos => convencidos
    # extendidísima => extendida
    if word =~/[ai]dísim[oa]s?$/
      new_word = word.gsub(/([ai])dísim([oa]s?)$/,'\1d\2')
      result = replace_tags(@dw.get_emissions_info(new_word, ['V0p*', 'A*']),"^A0","As")
      return result unless result.empty?
    end

    if word =~ /[ts]ísim[oa]s?$/
      only_valids = [/abert[oa]s?/, /absolt[oa]s?/, /aces[oa]s?/, /acolleit[oa]s?/, /apres[oa]s?/, /avolt[oa]s?/, /colleit[oa]s?/, /comest[oa]s?/, /cubert[oa]s?/, /descrit[oa]s?/, /descubert[oa]s?/, /desenvolt[oa]s?/, /devolt[oa]s?/, /disolt[oa]s?/, /encolleit[oa]s?/, /encubert[oa]s?/, /entreabert[oa]s?/, /envolt[oa]s?/, /enxoit[oa]s?/, /ergueit[oa]s?/, /escolleit[oa]s?/, /escrit[oa]s?/, /frit[oa]s?/, /impres[oa]s?/, /mort[oa]s?/, /pres[oa]s?/, /prescrit[oa]s?/, /proscrit[oa]s?/, /provist[oa]s?/, /recolleit[oa]s?/, /recubert[oa]s?/, /resolt[oa]s?/, /revolt[oa]s?/]
      new_word = word.gsub(/([ts])ísim([oa]s?)$/,'\1\2')
      if only_valids.any? { |regex| regex.match?(new_word) }
        result = replace_tags(@dw.get_emissions_info(new_word, ['V0p*', 'A*']),"^A0","As")
        return result unless result.empty?
      end
    end

    # ísimo (default rule)
    # listísimo => listo
    # gravísimo => grave
    if word =~ /ísim[oa]s?$/
      new_word = word.gsub(/ísim([oa]s?)$/,'\1')
      variants = [gheada_to_cannonical(new_word)]
      result = replace_tags(@dw.get_emissions_info(new_word, ['A*']),"^A0","As")
      return result unless result.empty?
      if result.empty?
        variants = [gheada_to_cannonical(new_word)]
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
        # amiguiño => amigo
        # enruguiñas => enruga
        # albondiguiñas => albóndiga
        # estomaguiño => estómago
        new_word = word.gsub(/guiñ([oa]s?)$/,'g\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
        return result unless result.empty?
        if new_word !~/áéíóú/
          new_word = set_tilde(new_word, 3) # Maybe this doesn't cover all the casuistic
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
          return result unless result.empty?
        end
      end
      if word =~ /lciñ[oa]s?$/
        # solciño => sol (Scms)
        # animalciños => animal (Scmp)
        # descalciña => descalzo
        new_word = word.gsub(/(l)ciñ[oa]$/,'\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
        return result unless result.empty?
        new_word = word.gsub(/(l)ciñ[oa]s$/,'\1es')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
        return result unless result.empty?
        new_word = word.gsub(/(l)ciñ([oa])$/,'\1z\2')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
        return result unless result.empty?
        new_word = word.gsub(/(l)ciñ([oa])s$/,'\1z\2s')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
        return result unless result.empty?
      end
      if word =~ /quiñ[oa]s?$/
        # quiño/a/os/as
        # plaquiñas => placas
        # retaquiños => retacos
        new_word = word.gsub(/quiñ([oa]s?)$/,'c\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
        return result unless result.empty?
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['V?i*','V?s','V0m*'], variants))
        unless result.empty?
          if new_word !~ /áéíóú/
            new_word_2 = set_tilde(new_word, 3) # Maybe this doesn't cover all the casuistic
            # musiquiña => música / musiquiño => músico
            variants = [gheada_to_cannonical(new_word_2)]
            result = @dw.get_emissions_info_variants(new_word_2, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants)
            return result unless result.empty?
          end
        end
        if new_word !~ /áéíóú/
          new_word_2 = set_tilde(new_word, 3) # Maybe this doesn't cover all the casuistic
          variants = [gheada_to_cannonical(new_word_2)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word_2, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
          # faisquiñas => faíscas / periodiquiños => periódicos / politiquiñas =>> políticas
          return result unless result.empty?
          new_word_2 = set_tilde(new_word, 2) # Maybe this doesn't cover all the casuistic
          variants = [gheada_to_cannonical(new_word_2)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word_2, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
          return result unless result.empty?
        end
        new_word = word.gsub(/quiñ[oa](s?)$/,'que\1')
        # bosquiños => bosques
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
        return result unless result.empty?
      end
      if word =~ /nciñ[oa]s?$/
        if word =~ /onciños?$/
          # algodonciño => algodón
          # cartonciños => cartóns
          new_word = word.gsub(/onciño(s?)$/,'ón\1')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
          return result unless result.empty?
        end
        if word =~ /onciñas?$/
          # cancionciña => canción
          new_word = word.gsub(/onciña(s?)$/,'ón\1')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Scf*','A0f*'], variants))
          return result unless result.empty?
          # chaponciñas => chaponas
          new_word = word.gsub(/onciña(s?)$/,'ona\1')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Scf*','A0f*'], variants))
          return result unless result.empty?
        end
        if word =~ /anciñ[oa]s?$/
          # garavanciño => garavanzo
          # crianciñas => crianzas
          new_word = word.gsub(/anciñ([oa]s?)$/,'anz\1')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
          return result unless result.empty?
          # mazanciña => mazán
          new_word = word.gsub(/anciñ[oa](s?)$/,'án\1')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
          return result unless result.empty?
          # vranciño => vran
          new_word = word.gsub(/anciñ[oa](s?)$/,'an\1')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
          return result unless result.empty?
        end
        if word =~ /enciñas?$/
          # trenciñas => tranzas
          # fervenciña => fervenza
          new_word = word.gsub(/enciñ(as?)$/,'enz\1')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
          return result unless result.empty?
        end
        if word =~ /inciñ[oa]s?$/
          # pinciñas => pinzas
          new_word = word.gsub(/inciñ([oa]s?)$/,'inz\1')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
          return result unless result.empty?
          # xardinciños => xardíns
          new_word = word.gsub(/inciñ[oa](s?)$/,'ín\1')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
          return result unless result.empty?
        end
      end
      if word =~ /ndiñ[oa]s?$/
          # segundiño => segundo
          # brandiños => brandos
          # pasandiño => pasando
        new_word = word.gsub(/ndiñ([oa]s?)$/,'nd\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
        return result unless result.empty?
      end
      if word =~ /rciñ[oa]s?$/
        # cogorciña => cogorza
        # verciñas => verzas
        # almorciño => almorzo
        new_word = word.gsub(/rciñ([oa]s?)$/,'rz\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*'], variants))
        return result unless result.empty?

        # calorciño => calor
        # altarciño => altar
        # amorciño => amor
        # calamarciños => calamares
        if word =~ /rciñ[oa]$/
          new_word = word.gsub(/rciñ[oa]$/,'r')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['A*','S*'], variants))
          return result unless result.empty?
        end
        if word =~ /rciñ[oa]s$/
          new_word = word.gsub(/rciñ[oa]s$/,'res')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['A*','S*'], variants))
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
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','I*'],variants))
        return result unless result.empty?
        # xefiño => xefe
        # lumiño => lume
        # suaviñas => suaves
        # traxiños => traxes
        new_word = word.gsub(/([fmvx])iñ([oa]s?)$/,'\1e')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','I*'],variants))
        return result unless result.empty?
      end
      if word =~ /tiñ[oa]s?$/
        # gatiños => gatos
        # azoutiña => azouta
        new_word = word.gsub(/tiñ([oa]s?)$/,'t\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','W*','I*'], variants))
        return result unless result.empty?
        # tomatiños => tomates
        # amantiñas => amantes
        new_word = word.gsub(/tiñ[oa](s?)$/,'te\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
        return result unless result.empty?
      end
      if word =~ /[bpñ]iñ[oa]s?$/
        # trapiño => trapo
        # castañiñas => castañas
        # viñiño => viño
        # barbiña => barba
        # xoubiñas => xouba
        new_word = word.gsub(/([bpñ])iñ([oa]s?)$/,'\1\2')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
        return result unless result.empty?
      end
      if word =~ /biñ[oa]s?$/
        # nubiñas => nubes
        # FIXME: Real rule is: nubiñas => nube
        new_word = word.gsub(/biñ[oa]s?$/,'be')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
        return result unless result.empty?
      end
      if word =~ /chiñ[oa]s?$/
        # estuchiño => estuche
        new_word = word.gsub(/chiñ[oa]s?$/,'che')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
        return result unless result.empty?
      end
      if word =~ /lliñ[oa]s?$/
        # ovelliñas => ovellas
        new_word = word.gsub(/(ll)iñ([oa]s?)$/,'\1\2')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
        return result unless result.empty?
      end
      if word =~ /rriñ[oa]s?$/
        # aforriños => aforros
        # churriñas => churras
        new_word = word.gsub(/(rr)iñ([oa]s?)$/,'\1\2')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
        return result unless result.empty?
      end
      if word =~ /chiñ[oa]s?$/
        # aforriños => aforros
        # churriñas => churras
        new_word = word.gsub(/(ch)iñ([oa]s?)$/,'\1\2')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
        return result unless result.empty?
      end
      if word =~ /ghiñ[oa]s?$/
        # amighiñas => amigas
        new_word = word.gsub(/ghiñ([oa]s?)$/,'g\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['S*','A*','V0p0*']))
         return result unless result.empty?
      end
      if word =~ /diñ[oa]s?$/ and word !~ /ndiñ[oa]s?$/
        # cadradiños => cadrados
        # todiñas => todas
        new_word = word.gsub(/diñ([oa]s?)$/,'d\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','I*','V0p0*'], variants))
        return result unless result.empty?
      end
      if word =~ /diñ[oa]s?$/ and word !~ /ndiñ[oa]s?$/
        # bigodiño => bigode
        # humildiño => humilde
        new_word = word.gsub(/diñ[oa](s?)$/,'de\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','I*','V0p0*'], variants))
        return result unless result.empty?
      end
      if word =~ /diñ[oa]s?$/ and word =~ /ndiñ[oa]s?$/
        # meirandiño => meirande
        new_word = word.gsub(/diñ[oa](s?)$/,'de\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','I*','V0p0*'], variants))
        return result unless result.empty?
      end
      if word =~ /uesiñ[oa]s?$/
        if word =~/uesiño$/
          # marquesiño => marqués
          new_word = word.gsub(/uesiño$/,'ués')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
          return result unless result.empty?
        end
        if word =~/uesiña$/
          # marquesiña => marquesa
          new_word = word.gsub(/uesiña$/,'uesa')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
          return result unless result.empty?
        end
        if word =~/uesiños$/
          # marquesiños => marqueses
          new_word = word.gsub(/uesiños$/,'ueses')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
          return result unless result.empty?
        end
        if word =~/uesiñas$/
          # marquesiñas => marquesas
          new_word = word.gsub(/uesiñas$/,'uesas')
          variants = [gheada_to_cannonical(new_word)]
          result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
          return result unless result.empty?
        end
      end
      if word =~ /siñ[oa]s?$/ and word !~ /uesiñ[oa]s?$/
        # tesiños => tesos
        # raposiña => raposa
        # camisiñas => camisas
        new_word = word.gsub(/siñ([oa]s?)$/,'s\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
        return result unless result.empty?
      end
      if word =~ /siñ[oa]s?$/ and word !~ /uesiñ[oa]s?$/
        # tesiña => tese
        # tosiña => tose
        new_word = word.gsub(/siñ[oa](s?)$/,'se\1')
        variants = [gheada_to_cannonical(new_word)]
        result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['S*','A*','V0p0*'], variants))
        return result unless result.empty?
      end
      # Regra por defecto
      # horiña, peliños, groliño, etc.
      new_word = word.gsub(/iñ([oa]s?)$/,'\1')
      variants = [gheada_to_cannonical(new_word)]
      result = gender_number_force_matching(word, @dw.get_emissions_info_variants(new_word, ['Sc*','A*','V0p0*','V0x000','W*','I*'], variants))
      return result unless result.empty?
    end

    # gh treatment
    if word =~ /gh/
      if word =~ /gh[aou]/
        new_word = word.gsub(/gh/,'g')
        return @dw.get_emissions_info(new_word, ['Sc*','A*','V*','W*','N*','Y*','I*','R*'])
      elsif word =~ /gh[ei]/
        new_word = word.gsub(/gh/,'gu')
        return @dw.get_emissions_info(new_word, ['Sc*','A*','V*','W*','N*','Y*','I*','R*'])
      end
    end

    []
  end

  def gheada_to_cannonical(word)
    new_word = nil
    if word =~ /gh[aou]/
      new_word = word.gsub(/gh/,'g')
    elsif word =~ /gh[ei]/
      new_word = word.gsub(/gh/,'gu')
    end
    return new_word
  end

  # Function to force gender and number in a result. This function may be removed if we split each iño/a/os/as rules into four (using gender and number specification in tags when calling to get_emissions_info)
  def gender_number_force_matching (word, result)
    return result if result.empty?
    return replace_tags(result, "[mfa][spa]$","ms") if word =~/o$/
    return replace_tags(result, "[mfa][spa]$","fs") if word =~/a$/
    return replace_tags(result, "[mfa][spa]$","mp") if word =~/os$/
    return replace_tags(result, "[mfa][spa]$","fp") if word =~/as$/
    []
  end

  # Function which is called before accessing emission frequencies for verbs with enclitics pronouns.
  def lemmatize_verb_with_enclitics(left_part)
    #STDERR.puts "lemmatize_verb_with_enclitics: #{left_part}"
    # gh treatment
    if left_part =~ /gh/
      if left_part =~ /gh[aou]/
        new_left_part = left_part.gsub(/gh/,'g')
        return new_left_part
      elsif left_part =~/gh[ei]/
        new_left_part = left_part.gsub(/gh/,'gu')
        return new_left_part
      end
    # auto treatment
    elsif left_part =~ /^autorr/
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
    #STDERR.puts "original_left_part:#{original_left_part}, left_part:#{left_part}"
    # gh treatment
    if original_left_part =~ /gh/
      if left_part =~ /gh[aou]/
        new_left_part = left_part.gsub(/gh/,'g')
        return new_left_part
      elsif left_part =~/gh[ei]/
        new_left_part = left_part.gsub(/gh/,'gu')
        return new_left_part
      end
    # auto treatment
    elsif original_left_part =~/^autorr/
      new_left_part = left_part.gsub(/^(.)/,'autor\1')
      return new_left_part unless new_left_part =~ /^autor?auto/
    elsif original_left_part =~/^(auto-?)/
      new_left_part = left_part.gsub(/^(.)/,"#{$1}\\1")
      return new_left_part unless new_left_part =~ /^autor?auto/
    end
    left_part
  end

  # Function to tranform the lemma part when restoring a verb form with enclitics.
  def lemmatize_verb_with_enclitics_reverse_lemma(original_left_part, left_part)
    if original_left_part =~/^(auto-?)/
      new_left_part = left_part.gsub(/^(.)/,"#{$1}\\1")
      return new_left_part unless new_left_part =~ /^autor?auto/
    end
    left_part
  end

  # Function to tranform the hiperlemma part when restoring a verb form with enclitics.
  def lemmatize_verb_with_enclitics_reverse_hiperlemma(original_left_part, left_part)
    if original_left_part =~/^(auto-?)/
      new_left_part = left_part.gsub(/^(.)/,"#{$1}\\1")
      return new_left_part  unless new_left_part =~ /^autor?auto/
    end
    left_part
  end

  # Function which replace a vowel by the corresponding tilde one.
  # position is the vowel order from the end.
  def set_tilde(word, position)
    characters = word.each_grapheme_cluster.to_a
    vowel_positions = characters.each_with_index
                                .select { |c, _| %w[a e i o u á é í ó ú].include?(c) }
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
