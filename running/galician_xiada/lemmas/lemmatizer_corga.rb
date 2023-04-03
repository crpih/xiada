# frozen_string_literal: true
require_relative '../../bin/lemmas/query'
require_relative '../../bin/lemmas/result'
require_relative 'utils'
require_relative 'auto_rule'
require_relative 'isimo_rule'
require_relative 'mente_rule'
require_relative 'inho_rule'
require_relative 'ex_rule'
require_relative 'ex_proper_rule'
require_relative 'meta_rule'
require_relative 'etno_rule'
require_relative 'macro_rule'
require_relative 'micro_rule'
require_relative 'xeo_rule'
require_relative 'multi_rule'
require_relative 'tele_rule'

module Lemmas
  class LemmatizerCorga
    include Utils

    def initialize(database_wrapper, gheada: true, seseo: true)
      @dw = database_wrapper
      @gheada = gheada
      @seseo = seseo
      @tags = @dw.get_possible_tags(['*']).split(',').map { |t| t.delete_prefix("'").delete_suffix("'") }

      @mente_rule = MenteRule.new(@tags)
      @auto_rule = AutoRule.new(@tags)
      @isimo_rule = IsimoRule.new(@tags)
      @inho_rule = InhoRule.new(@tags)
      @ex_rule = ExRule.new(@tags)
      @ex_proper_rule = ExProperRule.new(@tags)
      @meta_rule = MetaRule.new(@tags)
      @etno_rule = EtnoRule.new(@tags)
      @macro_rule = MacroRule.new(@tags)
      @micro_rule = MicroRule.new(@tags)
      @xeo_rule = XeoRule.new(@tags)
      @multi_rule = MultiRule.new(@tags)
      @tele_rule = TeleRule.new(@tags)
    end

    def call(word)
      gheada_queries(Query.new(nil, word, @tags)) do |q|
        seseo_queries(q) do |q|
          [
            *@auto_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@ex_proper_rule.(q) do |q|
              proper_noun(q)
            end,
            *@ex_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@meta_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@etno_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@macro_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@micro_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@xeo_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@multi_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *@tele_rule.(q) do |q|
              [*suffix_rules(q), *find(q)]
            end,
            *suffix_rules(q),
            # LemmatizerCorga#lemmatizer won't be called if the term exists literally
            # So this is useful only for gheada variants: gherra => guerra and ghitarra => guitarra
            *find(q)
          ]
        end
      end
    end

    private

    def gheada_queries(query)
      return yield query unless @gheada

      gheada_variants(query.word).flat_map { |v| yield query.copy(v) }
    end

    def seseo_queries(query)
      return yield query unless @seseo

      seseo_variants(query.word).flat_map { |v| yield query.copy(v) }
    end

    def suffix_rules(query)
      [
        *@mente_rule.(query) { |qa| find_guesser('mente', qa) },
        *@isimo_rule.(query) { |qa| find(qa) },
        *@inho_rule.(query) { |qa| find(qa) },
      ]
    end

    def find(query)
      @dw.get_emissions_info(query.word, query.tags)
         .map { |tag, lemma, hyperlemma, lob_b| Result.new(query, tag, lemma, hyperlemma, lob_b) }
    end

    def find_guesser(suffix, query)
      @dw.get_guesser_result("'#{suffix}'", query.word, query.tags)
         .map { |tag, lemma, hyperlemma, lob_b| Result.new(query, tag, lemma, hyperlemma, lob_b) }
    end

    def proper_noun(query)
      [Result.new(query, 'Sp00', query.word, query.word, 0.0)]
    end
  end
end
