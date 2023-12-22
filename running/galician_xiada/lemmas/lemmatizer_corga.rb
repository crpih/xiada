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

    module ClassMethods
      include Utils

      def lemmatize(word, tags)
        @lemmatizer ||= LemmatizerCorga.new(@dw, seseo: !ENV['XIADA_SESEO'].nil?)
        result = @lemmatizer.call(word, tags)
        result&.any? ? result.map { |r| [r.tag, r.lemma, r.hyperlemma, r.log_b] } : []
      end

      # Function which is called before accessing emission frequencies for verbs with enclitics pronouns.
      # Since this is a class method, we have to check the ENV variable again.
      # All enclitics processing needs a refactor to work well with the new lemmatizer.
      def lemmatize_verb_with_enclitics(left_part)
        gheada_variants(left_part).flat_map do |gh_variant|
          ss_variants = seseo_variants(gh_variant)
          # Keep only the literal word (first) if XIADA_SESEO is not set
          ss_variants = ss_variants.take(1) if ENV['XIADA_SESEO'].nil?
          ss_variants.map { |s| enclitics_auto_rule(s) }
        end
      end

      # Simplified auto rule that only works with strings
      # Proper way to do it will be to use the same rules as in the lemmatizer, but this will require a huge refactor
      def enclitics_auto_rule(left_part)
        return left_part.delete_prefix('autor') if left_part.start_with?('autorr')
        return left_part.delete_prefix('auto-') if left_part.start_with?('auto-')
        return left_part.delete_prefix('auto') if left_part.start_with?('auto')

        left_part
      end
    end

    def initialize(database_wrapper, gheada: true, seseo: false)
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

    def call(word, tags)
      gheada_queries(Query.new(nil, word, tags)) do |q|
        seseo_queries(q) do |q|
          # LemmatizerCorga#lemmatizer won't be called if the term exists literally
          # So this is useful only for gheada and seseo variants: gherra => guerra and ghitarra => guitarra
          literal_result = find(q)
          return literal_result if literal_result.any?

          [
            *@auto_rule.(q) do |q|
              suffix_rules(q)
            end,
            *@ex_proper_rule.(q) do |q|
              proper_noun(q)
            end,
            *@ex_rule.(q) do |q|
              suffix_rules(q)
            end,
            *@meta_rule.(q) do |q|
              suffix_rules(q)
            end,
            *@etno_rule.(q) do |q|
              suffix_rules(q)
            end,
            *@macro_rule.(q) do |q|
              suffix_rules(q)
            end,
            *@micro_rule.(q) do |q|
              suffix_rules(q)
            end,
            *@xeo_rule.(q) do |q|
              suffix_rules(q)
            end,
            *@multi_rule.(q) do |q|
              suffix_rules(q)
            end,
            *@tele_rule.(q) do |q|
              suffix_rules(q)
            end,
            *suffix_rules(q),
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
      literal_result = find(query)
      return literal_result if literal_result.any?

      [
        *@mente_rule.(query) { |qa| find_guesser('mente', qa) },
        *@isimo_rule.(query) { |qa| find(qa) },
        *@inho_rule.(query) { |qa| find(qa) },
      ]
    end

    def find(query)
      @dw.get_emissions_info(query.word, query.tags)
         .map { |tag, lemma, hyperlemma, lob_b| Result.new(query, nil, tag, lemma, hyperlemma, lob_b) }
    end

    def find_guesser(suffix, query)
      @dw.get_guesser_result("'#{suffix}'", query.word, query.tags)
         .map { |tag, lemma, hyperlemma, lob_b| Result.new(query, nil, tag, lemma, hyperlemma, lob_b) }
    end

    def proper_noun(query)
      [Result.new(query, nil, 'Sp00', query.word, query.word, 0.0)]
    end
  end
end
