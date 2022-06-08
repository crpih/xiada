# -*- coding: utf-8 -*-

module LemmatizerSpanishEslora
  def lemmatize(word, tags)
    # STDERR.puts "(lemmatize) word: #{word}"
    # ito/ita/itos/itas suffix treatment
#    if word != /áéíóú/ and word =~ /it([oa]s?)$/
##      # cito/cita/citos/citas
#      new_word = word.gsub(/(cit[oa]s?)$/,'')
#      return @dw.get_emissions_info(new_word, ['NC*','A*','VP*','PQMS']) if new_word != word

 #     # ito/ita/itos/itas
 #     new_word = word.gsub(/it([oa]s?)$/,'\1')
 #     return @dw.get_emissions_info(new_word, ['N*','A*','VP*','PQMS']) if new_word != word
 #   end

    # super + ísimo: TODO

    # super prefix treatment

    if word =~ /^super/
      new_word = word.gsub(/^super/,'')
      return @dw.get_emissions_info(new_word, ['A*','W']) if new_word != word
    end

    # hiper + ísimo: TODO

    # hiper prefix treatment

    if word =~ /^hiper/
      new_word = word.gsub(/^hiper/,'')
      return @dw.get_emissions_info(new_word, ['A*','W']) if new_word != word
    end

    # ísimo/ísima/ísimos/ísimas treatment

    # ísimo/a/os/as suffix treatment

    # amabilísimo => amable
    if word =~ /bilísim[oa]s?$/
      new_word = word.gsub(/bilísim[oa](s)?$/,'ble\1')
      return @dw.get_emissions_info(new_word, ['AF*']) if word =~ /as?$/
      return @dw.get_emissions_info(new_word, ['AM*','AN*','AA*']) if word =~ /os?$/

    end
    # riquísimo => rico
    if word =~ /quísim[oa]s?$/
      new_word = word.gsub(/bilísim([oa]s?$)/,'c\1')
      return @dw.get_emissions_info(new_word, ['A*'])

    end
    # vaguísimo => vago
    if word =~ /guísim[oa]s?$/
      new_word = word.gsub(/guísim([oa]s?)$/,'g\1')
      return @dw.get_emissions_info(new_word, ['A*'])

    end
    # ambigüísimo => ambiguo / pingüísimo => pingüe
    if word =~ /güísim[oa]s?$/
      new_word = word.gsub(/güísim([oa]s?)$/,'gu\1')
      result = @dw.get_emissions_info(new_word, ['A*'])
      if result.empty?
        new_word = word.gsub(/güísim[oa](s?)$/,'güe\1')
        return @dw.get_emissions_info(new_word, ['AF*']) if word =~/as?$/
        return @dw.get_emissions_info(new_word, ['AM*','AN*','AA*']) if word =~ /os?$/

      end
      return result

    end
    # friísimo => frío
    if word =~ /iísim[oa]s?$/
      new_word = word.gsub(/iísim([oa]s?)$/,'í\1')
      return @dw.get_emissions_info(new_word, ['A*'])

    end
    # virtualísimo => virtual
    # facilísimo => fácil
    if word =~ /lísim[oa]s?$/
      new_word = word.gsub(/lísim[oa]$/,'l')
      new_word << "es" if word =~/s$/
      StringUtils.tilde_combinations(new_word).each do |combination|
        result = @dw.get_emissions_info(combination, ['AF*']) if word =~/as?$/
        result = @dw.get_emissions_info(combination, ['AM*','AN*','AA*']) if word =~ /os?$/
        return result unless result.empty?

      end
    end

    # ferocísimo => feroz
    # dulcísimo => dulce
    if word =~ /císim[oa]s?$/
      new_word = word.gsub(/císim([oa]$)/,'z') if word =~ /[oa]$/
      new_word = word.gsub(/císim([oa]s$)/,'ces') if word =~ /s$/
      result = @dw.get_emissions_info(new_word, ['AF*']) if word =~ /as?$/
      result = @dw.get_emissions_info(new_word, ['AM*','AN*','AA*']) if word =~ /os?$/
      return result unless result.empty?

      new_word = word.gsub(/císim[oa](s?)$/,'ce\1')
      return @dw.get_emissions_info(new_word, ['AF*']) if word =~ /as?$/
      return @dw.get_emissions_info(new_word, ['AM*','AN*','AA*']) if word =~ /os?$/

    end

    # ísimo (default rule)
    # listísimo => listo
    # gravísimo => grave
    if word =~ /ísim[oa]s?$/
      new_word = word.gsub(/ísim([oa]s?)$/,'\1')
      result = @dw.get_emissions_info(new_word, ['A*'])
      return result unless result.empty?
      if result.empty?
        new_word = word.gsub(/ísim[oa](s?)$/,'e\1')
        return @dw.get_emissions_info(new_word, ['AF*']) if word =~ /as?$/
        return @dw.get_emissions_info(new_word, ['AM*','AN*','AA*']) if word =~ /os?$/
      end
    end

    # ito/a/os/as
    # process only simple words (the ones that don't have - or /)
    if word =~ /it[oa]s?$/ and word !~ /[-\/]/
      if word =~ /guit[oa]s?$/
        # amiguito => amigo
        # albondiguitas => albóndiga
        # estomaguito => estómago
        new_word = word.gsub(/guit([oa]s?)$/,'g\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
        return result unless result.empty?
        if new_word !~/áéíóú/
          new_word = set_tilde(new_word, 3) # Maybe this doesn't cover all the casuistic
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
          return result unless result.empty?
        end
      end
      if word =~ /lcit[oa]s?$/
        # solcito => sol (Scms)
        # descalcita => descalzo
        new_word = word.gsub(/(l)cit[oa]$/,'\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
        return result unless result.empty?
        new_word = word.gsub(/(l)cit[oa]s$/,'\1es')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
        return result unless result.empty?
        new_word = word.gsub(/(l)cit([oa])$/,'\1z\2')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
        return result unless result.empty?
        new_word = word.gsub(/(l)cit([oa])s$/,'\1z\2s')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
        return result unless result.empty?
      end
      if word =~ /quit[oa]s?$/ and word != "quito"
        # fresquito/a/os/as
        # plaquitas => placas
        # retaquitos => retacos
        new_word = word.gsub(/quit([oa]s?)$/,'c\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
        return result unless result.empty?
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['VI*','VS*','VMP*']))
        unless result.empty?
          if new_word !~ /áéíóú/
            new_word_2 = set_tilde(new_word, 3) # Maybe this doesn't cover all the casuistic
            # musiquita => música / musiquito => músico
            result = @dw.get_emissions_info(new_word_2, ['NC*','A*','VP*','VGP','W','DI*'])
            return result unless result.empty?
          end
        end
        if new_word !~ /áéíóú/
          new_word_2 = set_tilde(new_word, 3) # Maybe this doesn't cover all the casuistic
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word_2, ['NC*','A*','VP*','VGP','W','DI*']))
          # periodiquitos => periódicos / politiquitas => políticas
          return result unless result.empty?
          new_word_2 = set_tilde(new_word, 2) # Maybe this doesn't cover all the casuistic
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word_2, ['NC*','A*','VP*','VGP','W','DI*']))
          return result unless result.empty?         
        end
        new_word = word.gsub(/quit[oa](s?)$/,'que\1')
        # ???
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
        return result unless result.empty?
      end
      if word =~ /ncit[oa]s?$/
        if word =~ /oncitos?$/
          # algodoncito => algodón
          # cartoncitos => cartóns
          new_word = word.gsub(/oncito(s?)$/,'ón\1')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
          return result unless result.empty?
        end
        if word =~ /oncitas?$/
          # cancioncita => canción
          new_word = word.gsub(/oncita(s?)$/,'ón\1')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NCF*','AF*']))
          return result unless result.empty?
          # chaponcitas => chaponas
          new_word = word.gsub(/oncita(s?)$/,'ona\1')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NCF*','AF*']))
          return result unless result.empty?          
        end
        if word =~ /ancit[oa]s?$/
          # garvancito => garavanzo
          new_word = word.gsub(/ancit([oa]s?)$/,'anz\1')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
          return result unless result.empty?
          # guardiancito => guardián
          new_word = word.gsub(/ancit[oa](s?)$/,'án\1')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
          return result unless result.empty?
          # ???
          new_word = word.gsub(/ancit[oa](s?)$/,'an\1')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
          return result unless result.empty?
        end
        if word =~ /encitas?$/
          # trencitas => trenzas
          new_word = word.gsub(/encit(as?)$/,'enz\1')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
          return result unless result.empty?
        end
        if word =~ /incit[oa]s?$/
          # pincitas => pinzas
          new_word = word.gsub(/incit([oa]s?)$/,'inz\1')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
          return result unless result.empty?
          # jardincito => jardín
          new_word = word.gsub(/incit[oa]$/,'ín')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
          return result unless result.empty?
          # jardincitos => jardines
          new_word = word.gsub(/incit[oa]s$/,'ines')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
          return result unless result.empty?
        end
      end
      if word =~ /ndit[oa]s?$/
        # segundito => segundo
        # blanditos => blandos
        new_word = word.gsub(/ndit([oa]s?)$/,'nd\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
        return result unless result.empty?
      end
      if word =~ /rcit[oa]s?$/
        # cogorcita => cogorza
        # almuercito => almuerzo
        new_word = word.gsub(/rcit([oa]s?)$/,'rz\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*']))
        return result unless result.empty?

        # calorcito => calor
        # altarcito => altar
        # amorcito => amor
        # calamarcitos => calamares
        if word =~ /rcit[oa]$/
          new_word = word.gsub(/rcit[oa]$/,'r')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['A*','N*']))
          return result unless result.empty?
        end
        if word =~ /rcit[oa]s$/
          new_word = word.gsub(/rcit[oa]s$/,'res')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['A*','N*']))
          return result unless result.empty?
        end
      end
      if word =~ /[fmvj]it[oa]s?$/
        # huevitos => huevos
        # brujitas => brujas
        # dibujitos => dibujos
        new_word = word.gsub(/([fmvx])it([oa]s?)$/,'\1\2')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','DI*']))
        return result unless result.empty?
        # jefito => xefe
        # suavitas => suaves
        new_word = word.gsub(/([fmvj])it([oa]s?)$/,'\1e')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','DI*']))
        return result unless result.empty?
      end
      if word =~ /tit[oa]s?$/
        # gatitos => gatos
        new_word = word.gsub(/tit([oa]s?)$/,'t\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','W','DI*']))
        return result unless result.empty?
        # tomatitos => tomates
        # amantitas => amantes
        new_word = word.gsub(/tit[oa](s?)$/,'te\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
        return result unless result.empty?
        # disgustito
        new_word = word.gsub(/tit[oa](s?)$/,'to\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
        return result unless result.empty?
      end
      if word =~ /[bpñ]it[oa]s?$/
        # trapito => trapo
        # castañitas => castañas
        # barbita => barba
        new_word = word.gsub(/([bpñ])it([oa]s?)$/,'\1\2')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
        return result unless result.empty?
      end
      if word =~ /bit[oa]s?$/
        # nubitas => nubes
        new_word = word.gsub(/bit[oa]s?$/,'be')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
        return result unless result.empty?
      end
      if word =~ /chit[oa]s?$/
        # estuchito => estuche
        new_word = word.gsub(/chit[oa]s?$/,'che')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
        return result unless result.empty?
      end
      #if word =~ /llit[oa]s?$/
      #  # ovellitas => ovellas
      #  new_word = word.gsub(/(ll)it([oa]s?)$/,'\1\2')
      #  result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
      #  return result unless result.empty?
      #end
      if word =~ /rrit[oa]s?$/
        # ahorritos => ahorros
        # churritos => churros
        new_word = word.gsub(/(rr)it([oa]s?)$/,'\1\2')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
        return result unless result.empty?
      end
      if word =~ /chit[oa]s?$/
        # bichitos => bichos
        new_word = word.gsub(/(ch)it([oa]s?)$/,'\1\2')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
        return result unless result.empty?
      end
      #if word =~ /ghit[oa]s?$/
      #  # amighitas => amigas
      result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
      ##  new_word = word.gsub(/ghit([oa]s?)$/,'g\1')
      #  return result unless result.empty?
      #end
      if word =~ /dit[oa]s?$/ and word !~ /ndit[oa]s?$/
        # cuadraditos => cuadrados
        # toditas => todas
        new_word = word.gsub(/dit([oa]s?)$/,'d\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','DI*','VP*']))
        return result unless result.empty?
      end
      if word =~ /dit[oa]s?$/ and word !~ /ndit[oa]s?$/
        # humildito => humilde
        new_word = word.gsub(/dit[oa](s?)$/,'de\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','DI*','VP*']))
        return result unless result.empty?
      end
      if word =~ /uesit[oa]s?$/
        if word =~/uesito$/
          # marquesito => marqués
          new_word = word.gsub(/uesito$/,'ués')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
          return result unless result.empty?
        end
        if word =~/uesita$/
          # marquesita => marquesa
          new_word = word.gsub(/uesita$/,'uesa')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
          return result unless result.empty?
        end
        if word =~/uesitos$/
          # marquesitos => marqueses
          new_word = word.gsub(/uesitos$/,'ueses')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
          return result unless result.empty?
        end
        if word =~/uesitas$/
          # marquesitas => marquesas
          new_word = word.gsub(/uesitas$/,'uesas')
          result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
          return result unless result.empty?
        end
      end
      if word =~ /sit[oa]s?$/ and word !~ /uesit[oa]s?$/
        # camisitas => camisas
        new_word = word.gsub(/sit([oa]s?)$/,'s\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
        return result unless result.empty?
      end
      if word =~ /sit[oa]s?$/ and word !~ /uesit[oa]s?$/
        # tosita => tos
        new_word = word.gsub(/sit[oa](s?)$/,'s\1')
        result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['N*','A*','VP*']))
        return result unless result.empty?
      end
      # Regra por defecto
      # horita, pelitos, etc.
      new_word = word.gsub(/it([oa]s?)$/,'\1')
      result = gender_number_force_matching(word, @dw.get_emissions_info(new_word, ['NC*','A*','VP*','VGP','W','DI*']))
      return result unless result.empty?
    end

    # mente suffix treatment
    return @dw.get_guesser_result("'mente'", word, ['W']) if word =~ /mente$/
    []

  end

  # Function to force gender and number in a result. This function may be removed if we split each iño/a/os/as rules into four (using gender and number specification in tags when calling to get_emissions_info)
  def gender_number_force_matching (word, result)
    # STDERR.puts "(gener_number_force_matching) word: #{word}"
    return result if result.empty?
    return replace_tags(result, "[MFE][SPL]$","MS") if word =~/o$/
    return replace_tags(result, "[MFE][SPL]$","FS") if word =~/a$/
    return replace_tags(result, "[MFE][SPL]$","MP") if word =~/os$/
    return replace_tags(result, "[MFE][SPL]$","FP") if word =~/as$/
    []
  end
end
