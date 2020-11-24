# -*- coding: utf-8 -*-

module LemmatizerSpanishEslora
  def lemmatize(word, tags)
    # ito/ita/itos/itas suffix treatment
    if word != /áéíóú/ and word =~ /it([oa]s?)$/
      # cito/cita/citos/citas
      new_word = word.gsub(/(cit[oa]s?)$/, '')
      return @dw.get_emissions_info(new_word, ['NC*','A*','VP*','PQMS']) if new_word != word

      # ito/ita/itos/itas
      new_word = word.gsub(/it([oa]s?)$/, '\1')
      return @dw.get_emissions_info(new_word, ['N*','A*','VP*','PQMS']) if new_word != word
    end

    # super + ísimo

    # super prefix treatment

    if word =~ /^super/
      new_word = word.gsub(/^super/, '')
      return @dw.get_emissions_info(new_word, ['A*','W*']) if new_word != word
    end

    # hiper + ísimo

    # hiper prefix treatment

    if word =~ /^hiper/
      new_word = word.gsub(/^hiper/, '')
      return @dw.get_emissions_info(new_word, ['A*','W*']) if new_word != word
    end

    # ísimo/ísima/ísimos/ísimas treatment
    # grandísimo => grande
    # grandísima => grande
    # altísima => alta
    # altísimo => alto

    if word =~ /ísim[oa]s?$/
      new_word = word.gsub(/ísim[oa]s?/, 'e')
      result = @dw.get_emissions_info(new_word, ['A*','W*'])
      return result if new_word != word and !result.empty?

      new_word = word.gsub(/ísim([oa]s?)/, '\1')
      return @dw.get_emissions_info(new_word, ['A*','W*']) if new_word != word
    end

    # mente suffix treatment
    return @dw.get_guesser_result("'mente'", word, ['W*']) if word =~ /mente$/
    []

  end
end
