# -*- coding: utf-8 -*-
require_relative "../spanish_eslora/lemmatizer"
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

class LemmatizerMultilingualEslora

  class AdaptedLemmatizerCorga < Lemmas::LemmatizerCorga
    def initialize(database_wrapper, gheada: true, seseo: false)
      super

      # CORGA rules adapted to ESLORA tags
      @mente_rule = MenteRule.new(@tags, adverb: 'W')
      @auto_rule = AutoRule.new(@tags, adjective: "A.*", noun: "N.*", adverb: "W", verb: "V.*")
      @isimo_rule = IsimoRule.new(@tags, adjective: "A.*", verb_participle: "VP.*")
      @inho_rule = InhoRule.new(
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
      @ex_rule = ExRule.new(@tags, adjective: "A.*", noun_common: "NC.*")
      @ex_proper_rule = ExProperRule.new(@tags, noun_propers: "NP.*")
      @meta_rule = MetaRule.new(@tags, adjective: "A.*", noun_common: "NC.*")
      @etno_rule = EtnoRule.new(@tags, adjective: "A.*", noun_common: "NC.*")
      @macro_rule = MacroRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*")
      @micro_rule = MicroRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*")
      @xeo_rule = XeoRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*")
      @multi_rule = MultiRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*", adverb: "W")
      @tele_rule = TeleRule.new(@tags, adjective: "A.*", noun_common: "NC.*", verb: "V.*", adverb: "W")
    end
  end

  def initialize(database_wrapper)
    @dw = database_wrapper
    @eslora_lemmatizer = LemmatizerSpanishEslora.new(@dw)
    @corga_lemmatizer = Lemmas::LemmatizerCorga.new(@dw, seseo: true)
  end

  def lemmatize(word, tags)
    result = @eslora_lemmatizer.lemmatize(word, tags)
    result = @corga_lemmatizer.lemmatize(word, tags) if result.empty?
    result
  end

  def lemmatize_verb_with_enclitics(left_part)
    result = @eslora_lemmatizer.lemmatize_verb_with_enclitics(left_part)
    result = @corga_lemmatizer.lemmatize_verb_with_enclitics(left_part) if result.empty?
    result
  end
end
