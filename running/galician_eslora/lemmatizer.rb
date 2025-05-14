# -*- coding: utf-8 -*-
require_relative "../galician_xiada/lemmatizer"
require_relative "../galician_xiada/lemmas/mente_rule"
require_relative "../galician_xiada/lemmas/auto_rule"
require_relative "../galician_xiada/lemmas/isimo_rule"
require_relative "../galician_xiada/lemmas/inho_rule"
require_relative "../galician_xiada/lemmas/ex_rule"
require_relative "../galician_xiada/lemmas/ex_proper_rule"
require_relative "../galician_xiada/lemmas/meta_rule"
require_relative "../galician_xiada/lemmas/etno_rule"
require_relative "../galician_xiada/lemmas/macro_rule"
require_relative "../galician_xiada/lemmas/micro_rule"
require_relative "../galician_xiada/lemmas/xeo_rule"
require_relative "../galician_xiada/lemmas/multi_rule"
require_relative "../galician_xiada/lemmas/tele_rule"

module GalicianEslora
  class Lemmatizer < GalicianXiada::Lemmatizer

    def initialize(tagger_config)
      @tagger_config = tagger_config
      @tags = @tagger_config.dw.get_possible_tags([ '*' ]).split(',').map { |t| t.delete_prefix("'").delete_suffix("'") }

      # CORGA rules adapted to ESLORA tags
      @mente_rule = Lemmas::MenteRule.new(@tags, adverb: 'W')
      @auto_rule = Lemmas::AutoRule.new(@tags, adjective: "A.*", noun: "N.*", adverb: "W", verb: "V.*")
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
      @meta_rule = Lemmas::MetaRule.new(@tags, adjective: "A.*", noun_common: "NC.*")
      @etno_rule = Lemmas::EtnoRule.new(@tags, adjective: "A.*", noun_common: "NC.*")
      @macro_rule = Lemmas::MacroRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*")
      @micro_rule = Lemmas::MicroRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*")
      @xeo_rule = Lemmas::XeoRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*")
      @multi_rule = Lemmas::MultiRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*", adverb: "W")
      @tele_rule = Lemmas::TeleRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*", adverb: "W")
    end
  end
end
