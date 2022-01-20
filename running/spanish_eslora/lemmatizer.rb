# -*- coding: utf-8 -*-

module LemmatizerSpanishEslora
  def lemmatize(word, tags)
    # ito/ita/itos/itas suffix treatment
    if word != /áéíóú/ and word =~ /it([oa]s?)$/
      # cito/cita/citos/citas
      new_word = word.gsub(/(cit[oa]s?)$/,'')
      return @dw.get_emissions_info(new_word, ['NC*','A*','VP*','PQMS']) if new_word != word

      # ito/ita/itos/itas
      new_word = word.gsub(/it([oa]s?)$/,'\1')
      return @dw.get_emissions_info(new_word, ['N*','A*','VP*','PQMS']) if new_word != word
    end

    # super + ísimo: TODO

    # super prefix treatment

    if word =~ /^super/
      new_word = word.gsub(/^super/,'')
      return @dw.get_emissions_info(new_word, ['A*','W*']) if new_word != word
    end

    # hiper + ísimo: TODO

    # hiper prefix treatment

    if word =~ /^hiper/
      new_word = word.gsub(/^hiper/,'')
      return @dw.get_emissions_info(new_word, ['A*','W*']) if new_word != word
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

    # mente suffix treatment
    return @dw.get_guesser_result("'mente'", word, ['W*']) if word =~ /mente$/
    []

  end
end
