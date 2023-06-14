# frozen_string_literal: true
require_relative '../../bin/lemmas/query'
require_relative '../../bin/lemmas/result'
require_relative 'utils'
require_relative 'auto_rule'
require_relative 'ex_rule'
require_relative 'meta_rule'
require_relative 'etno_rule'
require_relative 'macro_rule'
require_relative 'micro_rule'
require_relative 'xeo_rule'
require_relative 'multi_rule'
require_relative 'tele_rule'

module Lemmas
  class EncliticsLemmatizerResult < Result
    attr_reader :group

    def initialize(query, tag, lemma, hyperlemma, group)
      super(query, tag, lemma, hyperlemma, nil)
      @group = group
    end
  end

  class EncliticsVerbPrefixerCorga
    include Utils
    class Result < Lemmas::Result
      attr_reader :group

      def initialize(query, tag, lemma, hyperlemma, group)
        super(query, tag, lemma, hyperlemma, nil)
        @group = group
      end

      def prefix
        # Since this lemmatizer has only prefix rules, the difference between previous word and word is the prefix.
        query.prev.word.sub(/\A#{Regexp.escape(query.word)}/, '')
      end
    end

    def initialize(database_wrapper, gheada: true, seseo: false)
      @dw = database_wrapper
      @gheada = gheada
      @seseo = seseo

      # Only Verb tags are relevant for this lemmatizer
      @tags = @dw.get_possible_tags(['V*']).split(',').map { |t| t.delete_prefix("'").delete_suffix("'") }

      # Only prefix rules are relevant for this lemmatizer
      @auto_rule = AutoRule.new(@tags)
      @ex_rule = ExRule.new(@tags)
      @meta_rule = MetaRule.new(@tags)
      @etno_rule = EtnoRule.new(@tags)
      @macro_rule = MacroRule.new(@tags)
      @micro_rule = MicroRule.new(@tags)
      @xeo_rule = XeoRule.new(@tags)
      @multi_rule = MultiRule.new(@tags)
      @tele_rule = TeleRule.new(@tags)
    end

    def call(verbal_part)
      results = lemmatize(verbal_part)
      return ['', nil, []] if results.empty?

      # Since this lemmatizer has only prefix rules, the difference between previous word and word is the prefix.
      prefix = results.first.query.prev.word.sub(/#{Regexp.escape(results.first.query.word)}\z/, '')
      [prefix, verbal_part.delete_prefix(prefix), results.map(&:tag)]
    end

    def lemmatize(verb_part)
      gheada_queries(Query.new(nil, verb_part, @tags)) do |q|
        seseo_queries(q) do |q|
          [
            *find(q),
            *@auto_rule.(q) do |q|
              find(q)
            end,
            *@ex_rule.(q) do |q|
              find(q)
            end,
            *@meta_rule.(q) do |q|
              find(q)
            end,
            *@etno_rule.(q) do |q|
              find(q)
            end,
            *@macro_rule.(q) do |q|
              find(q)
            end,
            *@micro_rule.(q) do |q|
              find(q)
            end,
            *@xeo_rule.(q) do |q|
              find(q)
            end,
            *@multi_rule.(q) do |q|
              find(q)
            end,
            *@tele_rule.(q) do |q|
              find(q)
            end
          ]
        end
      end
    end

    private

    def find(query)
      @dw.get_verb_roots(query.word)
         .map { |tag, lemma, hyperlemma| Result.new(query, tag, lemma, hyperlemma, nil) }
    end

    def gheada_queries(query)
      return yield query unless @gheada

      gheada_variants(query.word).flat_map { |v| yield query.copy(v) }
    end

    def seseo_queries(query)
      return yield query unless @seseo

      seseo_variants(query.word).flat_map { |v| yield query.copy(v) }
    end
  end
end