# -*- coding: utf-8 -*-

module LemmatizerGalicianXiada

  def lemmatize(word, tags)
    # mente suffix treatment
    return @dw.get_guesser_result("'mente'", word, ['W*']) if word =~ /mente$/

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
      new_word = word.gsub(/lísim[oa]$/,'l')
      new_word << "es" if word =~/s$/
      StringUtils.tilde_combinations(new_word).each do |combination|
        result = replace_tags(@dw.get_emissions_info(combination, ['A*']),"^A0","As")
        return result unless result.empty?

      end
    end

    # ferocísimo => feroz
    # docísimo => doce
    if word =~ /císim[oa]s?$/
      new_word = word.gsub(/císim([oa]s?$)/,'z') # TODO ??? (feroces)
      result = replace_tags(@dw.get_emissions_info(new_word, ['A*']),"^A0","As")
      return result unless result.empty?

      new_word = word.gsub(/císim[oa](s?)$/,'ce\1')
      return replace_tags(@dw.get_emissions_info(new_word, ['A*f*']),"^A0","As") if word =~ /as?$/
      return replace_tags(@dw.get_emissions_info(new_word, ['A*m*']),"^A0","As") if word =~ /os?$/

    end

    # ísimo (default rule)
    # listísimo => listo
    # gravísimo => grave
    if word =~ /ísim[oa]s?$/ # TODO ??? (revisar)
      new_word = word.gsub(/iísim([oa]s?)$/,'\1')
      result = replace_tags(@dw.get_emissions_info(new_word, ['A*']),"^A0","As")
      if result.empty?
        new_word = word.gsub(/iísim[oa](s?)$/,'e\1')
        return replace_tags(@dw.get_emissions_info(new_word, ['A*f*']),"^A0","As") if word =~ /as?$/
        return replace_tags(@dw.get_emissions_info(new_word, ['A*m*']),"^A0","As") if word =~ /os?$/
      end
      return result

    end

    # gh treatment
    if word =~ /gh/
      new_word = word.gsub(/gh/,'g')
      return @dw.get_emissions_info(new_word, ['Sc*','A*','V*','W*','N*','Y*','Z*'])
    end
    []
  end
end
