# -*- coding: utf-8 -*-

module EncliticsProcessorCustomGalicianXiada
  def restore_source_form(verb_part, verb_tags, enclitic_part, enclitic_syllables_length, begin_alternative_token, end_alternative_token, token_from, token_to, token)
    #STDERR.puts "verb_part: #{verb_part}"
    final_recovery_words = Hash.new
    relevant_tokens = Array.new
    infos = @dw.get_enclitic_verb_roots_info(verb_part, verb_tags.split(" "))
    infos.each do |info|
      tag_value = info[0]
      lemma = info[1]
      hiperlemma = info[2]
      extra = info[3]
      results = @dw.get_recovery_info(verb_part, tag_value, lemma, true)
      if results.empty?
        results = @dw.get_recovery_info(verb_part, tag_value, lemma, false)
      end
      if results.empty?
        STDERR.puts "WARNING: Reverse info for tag:#{tag_value} and lemma:#{lemma} not found. Searching for verb_part: #{verb_part}"
      end
      max_p_score = 0
      final_recovery_word = String.new(verb_part)
      final_recovery_tag = String.new(tag_value)
      final_recovery_lemma = String.new(lemma)
      final_recovery_hiperlemma = String.new(hiperlemma)
      final_recovery_log_b = -100 # To be changed ??? TODO
      # STDERR.puts "results.size: #{results.size}"
      results.each do |result|
        recovery_word = result[0]
        recovery_tag = result[1]
        recovery_lemma = result[2]
        recovery_hiperlemma = result[3]
        recovery_log_b = Float(result[4])
        # If there are several entries for the same tag and lemma, we
        # choose the word with the greater proximity score.
        new_recovery_word = rule_matching(verb_part, tag_value, enclitic_part, enclitic_syllables_length, extra, recovery_word)
        unless recovery_word == new_recovery_word
          final_recovery_word = new_recovery_word
          final_recovery_tag = recovery_tag
          final_recovery_lemma = recovery_lemma
          final_recovery_hiperlemma = recovery_hiperlemma
          final_recovery_log_b = recovery_log_b
          break
        else
          p_score = proximity_score(recovery_word, verb_part)
          # STDERR.puts "recovery_word:#{recovery_word}"
          # STDERR.puts "p_score:#{p_score}"
          if p_score >= max_p_score
            max_p_score = p_score
            final_recovery_word = recovery_word
            final_recovery_tag = recovery_tag
            final_recovery_lemma = recovery_lemma
            final_recovery_hiperlemma = recovery_hiperlemma
            final_recovery_log_b = recovery_log_b
          end
        end
      end
      if final_recovery_words[final_recovery_word] == nil
        new_token = Token.new(@sentence.text, final_recovery_word, :standard, token_from, token_to)
        new_token.qualifying_info = token.qualifying_info.clone
        final_recovery_words[final_recovery_word] = new_token
        begin_alternative_token.add_next(new_token)
        new_token.add_prev(begin_alternative_token)
        new_token.add_next(end_alternative_token)
        end_alternative_token.add_prev(new_token)
        relevant_tokens << new_token
      end
      final_recovery_words[final_recovery_word].add_tag_lemma_emission(final_recovery_tag, final_recovery_lemma, final_recovery_hiperlemma, final_recovery_log_b, false)
    end
    return relevant_tokens
  end

  private

  def rule_matching(verb_part, tag_value, enclitic_part, enclitic_syllables_length, extra, recovery_word)
    # STDERR.puts "verb_part:#{verb_part}, tag_value:#{tag_value}, enclitic_part:#{enclitic_part}, enclitic_syllables_length:#{enclitic_syllables_length}, recovery_word:#{recovery_word}"

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo remata en -réi, e a etiqueta é de 1a persoa do futuro de indicativo, e se na parte dereita hai 2 ou máis clíticos silábicos, reconstrúe a forma verbal para -rei.

    if verb_part =~ /réi$/ and tag_value =~ /Vfi10s/ and enclitic_syllables_length > 1
      return recovery_word.gsub(/réi$/, "rei")
    end

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo remata en -réi, e a etiqueta é de 1a persoa do futuro de indicativo, e se na parte dereita hai 1 ou 2 clíticos pero que constitúen unha única sílaba, reconstrúe a forma verbal para -réi.

    # => Isto xa o fai el por defecto, xa que a forma en réi é máis próxima.

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo remata en -óu, e a etiqueta é de 3a persoa singular do pretérito de indicativo (Vei30s) ou 1º persoa do presente de indicativo (Vpi10s), e se na parte dereita hai 2 ou máis clíticos silábicos, reconstrúe a forma verbal para -ou. Isto reconstruiría "aclaróullelo" para "aclarou". "abaixouse" seguiría a norma actual existente, para a que o fai ben (estóullelo/dóullelo/vóullelo => estou/dou/vou)

    if verb_part =~ /óu$/ and tag_value =~ /Vei30s|Vpi10s/ and enclitic_syllables_length > 1
      return recovery_word.gsub(/óu$/, "ou")
    end

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo remata en -óu, e a etiqueta é de 3a persoa singular do pretérito de indicativo (Vei30s), e se na parte dereita hai 1 ou 2 clíticos pero que constitúen unha única sílaba, reconstrúe a forma verbal para -óu. Isto reconstruiría "abandonóuse" para "abandonóu", o que sería o correcto atendendo ó que está no texto. Neste momento non o recoñece porque non están metidas estas desinencias na conxugación con clíticos.

    # => Isto xa o fai por defecto.

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo remata en -éu, e a etiqueta é de 3a persoa singular do pretérito de indicativo (Vei30s), e se na parte dereita hai 2 ou máis clíticos silábicos, reconstrúe a forma verbal para -eu. Isto reconstruiría "acendéuselle" para "acendeu". "abateume" seguiría a norma actual existente, para a que o fai ben.

    if verb_part =~ /éu$/ and tag_value =~ /Vei30s/ and enclitic_syllables_length > 1
      return recovery_word.gsub(/éu$/, "eu")
    end

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo remata en -éu, e a etiqueta é de 3a persoa singular do pretérito de indicativo (Vei30s), e se na parte dereita hai 1 ou 2 clíticos pero que constitúen unha única sílaba, reconstrúe a forma verbal para -éu. Isto reconstruiría "batéume" para "batéu", o que sería o correcto atendendo ó que está no texto. Neste momento non o recoñece porque non están metidas estas desinencias na conxugación con clíticos.

    # => Isto xa o fai por defecto

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo remata en -éi, e a etiqueta é de 1a persoa do singular pretérito de indicativo (Vei10s) ou 1a persoa do presente de indicativo(Vpi10s), e se na parte dereita hai 2 ou máis clíticos silábicos, reconstrúe a forma verbal para -ei. Isto reconstruiría "cantéillelo" para "cantei". "abaixeime" seguiría a norma actual existente, para a que o fai ben (héivolo|séivolo => hei/sei).

    if verb_part =~ /éi$/ and tag_value =~ /Vei10s|Vpi10s/ and enclitic_syllables_length > 1
      return recovery_word.gsub(/éi$/, "ei")
    end

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo remata en -éi, e a etiqueta é de 1a persoa singular do pretérito de indicativo (Vei10s), e se na parte dereita hai 1 ou 2 clíticos pero que constitúen unha única silába, reconstrúe a forma verbal para -éi. Isto reconstruiría "acheguéime" para "acheguéi", o que sería o correcto atendendo ó que está no texto. Neste momento non o recoñece porque non están metidas estas desinencias na conxugación con clíticos.

    # => Isto xa o fai por defecto.

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo, remata en -áche, e a etiqueta é de 2ª persoa do singular pretérito de indicativo (Vei20s), e se na parte dereita o clítico é lo, la, los ou las ou o artigo -lo, -la, -los, -las, reconstrúe a forma verbal para -aches. Isto reconstruiría "cantáchelas" ou “cantáche-la” para “cantaches”.

    if verb_part =~ /áche$/ and enclitic_part =~ /lo$|la$|los$|las$|-lo$|-la$|-los$|-las$/ and tag_value =~ /Vei20s/
      return recovery_word.gsub(/ache$/, "aches")
    end

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo, remata en -áche, e a etiqueta é de 2ª persoa do singular pretérito de indicativo (Vei20s), e se na parte dereita o clítico, un ou máis, dunha sílaba ou de varias, pero que non é lo, la, los ou las ou o artigo -lo, -la, -los, -las, reconstrúe a forma verbal para -ache. Isto reconstruiría "alentácheme" para “alentache” e “me”, ou “contáchemo” para “contache” e mais “me” e “o”.

    # => Isto xa o fai por defecto

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo, remata en -éche, e a etiqueta é de 2ª persoa do singular pretérito de indicativo (Vei20s), e se na parte dereita o clítico é lo, la, los ou las ou o artigo -lo, -la, -los, -las, reconstrúe a forma verbal para -eches. Isto reconstruiría "perdéchelas" ou “perdéche-lo” para “perdeches”.

    if verb_part =~ /éche$/ and enclitic_part =~ /lo$|la$|los$|las$|-lo$|-la$|-los$|-las$/ and tag_value =~ /Vei20s/
      return recovery_word.gsub(/eche$/, "eches")
    end

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo, remata en -éche, e a etiqueta é de 2ª persoa do singular pretérito de indicativo (Vei20s), e se na parte dereita o clítico, un ou máis, dunha sílaba ou de varias, pero que non é lo, la, los ou las ou o artigo -lo, -la, -los, -las, reconstrúe a forma verbal para -eche. Isto reconstruiría "metéchete" para “meteche” e “me”, ou “contáchemo” para “contache” e mais “me” e “o”.

    # => Isto xa o fai por defecto

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo, remata en -íche, e a etiqueta é de 2ª persoa do singular pretérito de indicativo (Vei20s), e se na parte dereita o clítico é lo, la, los ou las ou o artigo -lo, -la, -los, -las, reconstrúe a forma verbal para -iches. Isto reconstruiría "perdíchelas" ou “perdíche-lo” para “perdiches”.

    if verb_part =~ /íche$/ and enclitic_part =~ /lo$|la$|los$|las$|-lo$|-la$|-los$|-las$/ and tag_value =~ /Vei20s/
      return recovery_word.gsub(/iche$/, "iches")
    end

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo, remata en -íche, e a etiqueta é de 2ª persoa do singular pretérito de indicativo (Vei20s), e se na parte dereita o clítico, un ou máis, dunha sílaba ou de varias, pero que non é lo, la, los ou las ou o artigo -lo, -la, -los, -las, reconstrúe a forma verbal para -iche. Isto reconstruiría "prometíchemo" para “prometiche” e “me” e “o”.

    # => Isto xa o fai por defecto

    # Se na parte esquerda a forma verbal, unha vez eliminada a parte dereita correspondente ós clíticos ou clíticos e artigo remata en -íu, e a etiqueta é de 3a persoa singular do pretérito de indicativo (Vei30s), se o grupo de derivación é o V3, e se na parte dereita hai 2 ou máis clíticos silábicos, reconstrúe a forma verbal para -iu. Isto reconstruiría "abríuno-la" para "abriu" e “abríu”, pero non recoñecería "abríume" porque non están metidas estas desinencias na conxugación con clíticos.

    if verb_part =~ /íu$/ and tag_value =~ /Vei30s/ and enclitic_syllables_length > 1 and extra =~ /Vc3/
      return recovery_word.gsub(/íu$/, "iu")
    end

    return recovery_word
  end
end
