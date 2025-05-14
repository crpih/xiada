require_relative "../galician_xiada/enclitics_rules"

module GalicianPalmed
  class EncliticsRules < GalicianXiada::EncliticsRules

    # Ignore galician_xiada rules
    def rule_matching(verb_part, tag_value, enclitic_part, enclitic_syllables_length, extra, recovery_word) = recovery_word
  end
end
