# -*- coding: utf-8 -*-
require_relative "../galician_xiada/lemmatizer"
require_relative "../galician_xiada/lemmas/mente_rule"
require_relative "../galician_xiada/lemmas/isimo_rule"
require_relative "../galician_xiada/lemmas/inho_rule"
require_relative "../galician_xiada/lemmas/ex_rule"
require_relative "../galician_xiada/lemmas/ex_proper_rule"
require_relative "../galician_xiada/lemmas/prefix_vowel"
require_relative "../galician_xiada/lemmas/prefix_parens"

module GalicianEslora
  class Lemmatizer < GalicianXiada::Lemmatizer

    def initialize(tagger_config)
      @tagger_config = tagger_config
      @tags = @tagger_config.dw.get_possible_tags([ '*' ]).split(',').map { |t| t.delete_prefix("'").delete_suffix("'") }

      # CORGA rules adapted to ESLORA tags
      @mente_rule = Lemmas::MenteRule.new(@tags, adverb: 'W')
      @isimo_rule = Lemmas::IsimoRule.new(@tags, adjective: "A.*", verb_participle: "VP.*")
      @inho_rule = Lemmas::InhoRule.new(
        @tags,
        noun: "N.*",
        noun_common: "NC.*",
        noun_common_feminine: "NCF.*",
        adjective: "A.*",
        adjective_feminine: "AF.*",
        verb_infinitive: "VI.*",
        verb_participle: "VP.*",
        verb_gerund: "VG.*",
        verb_imperative: "VMI.*",
        verb_indicative: "VII.*",
        verb_subjunctive: "VSI.*",
        adverb: "W",
        indefinite: "[PD]N.*"
      )
      @ex_rule = Lemmas::ExRule.new(@tags, adjective: "A.*", noun_common: "NC.*")
      @ex_proper_rule = Lemmas::ExProperRule.new(@tags, noun_propers: "NP.*")

      @prefix_rules = [
        # Prefixes that end in a vowel
        Lemmas::PrefixVowel::AutoRule.new(@tags, adjective: "A.*", noun: "N.*", adverb: "W", verb: "V.*"),
        Lemmas::PrefixVowel::MetaRule.new(@tags, adjective: "A.*", noun_common: "NC.*"),
        Lemmas::PrefixVowel::EtnoRule.new(@tags, adjective: "A.*", noun_common: "NC.*"),
        Lemmas::PrefixVowel::MacroRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*"),
        Lemmas::PrefixVowel::MicroRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*"),
        Lemmas::PrefixVowel::XeoRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*"),
        Lemmas::PrefixVowel::MultiRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*", adverb: "W"),
        Lemmas::PrefixVowel::TeleRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*", adverb: "W"),
        # Prefixes with parens
        Lemmas::PrefixParens::DesRule.new(@tags),
        Lemmas::PrefixParens::ExRule.new(@tags),
        Lemmas::PrefixParens::MacroRule.new(@tags),
        Lemmas::PrefixParens::MicroRule.new(@tags),
        Lemmas::PrefixParens::PreRule.new(@tags),
        Lemmas::PrefixParens::ReRule.new(@tags),
        Lemmas::PrefixParens::Semi.new(@tags),
        Lemmas::PrefixParens::SubRule.new(@tags),
      ]
    end
  end
end
