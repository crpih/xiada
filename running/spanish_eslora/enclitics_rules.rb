module SpanishEslora
  class EncliticsRules
    # No rules
    def rule_matching(verb_part, tag_value, enclitic_part, enclitic_syllables_length, extra, recovery_word) = recovery_word

    # Function which determines if a verb_part/enclitic_part decomposition is valid
    # It returns an array of four elements:
    # 1) Boolean which indicates if it is a valid verb_part/enclitic_part decomposition
    # 2) verb_part
    # 3) enclitic_part
    # 4) A string with space separated valid verb tags
    def validate_decomposition(verb_part, verb_tags, enclitic_part, &syllable_count)
      # validate_decomposition verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
      check_default = true
      if verb_tags == nil or verb_tags.empty?
        result = [false, nil, nil, nil]
        return result
      else
        result = [true, verb_part, enclitic_part, verb_tags]
        return result
      end
    end # from def validate_decomposition

    # Function which filters the tags of an enclitic within a decomposition sequence
    # It return an array of three elements:
    # 1) The form of the enclitic, which could be changed.
    # 2) A string with space separated valid enclitic tags
    # 3) A string with space separated corresponding lemmas
    def filter_tags_enclitic(verb_part, enclitics, enclitic, enclitic_tags, enclitic_lemmas, index)
      if enclitic_tags == nil or enclitic_tags.empty?
        result = [nil, nil]
      else
        result = [enclitic, enclitic_tags, enclitic_lemmas]
      end
      return result
    end # from def filter_tags_enclitic
  end
end
