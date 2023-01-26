# frozen_string_literal: true
require_relative '../../bin/lemmas/query'
require_relative '../../bin/lemmas/result'
require_relative 'utils'
require_relative 'auto_rule'
require_relative 'isimo_rule'
require_relative 'mente_rule'
require_relative 'inho_rule'

module Lemmas
  class LemmatizerCorga
    include Utils

    def initialize(database_wrapper)
      @dw = database_wrapper
      @tags = @dw.get_possible_tags(['*']).split(',').map { |t| t.delete_prefix("'").delete_suffix("'") }
      @mente_rule = MenteRule.new(@tags)
      @auto_rule = AutoRule.new(@tags)
      @isimo_rule = IsimoRule.new(@tags)
      @inho_rule = InhoRule.new(@tags)
    end

    def call(word)
      query = Query.new(nil, word, @tags)
      gheada_variants(query.word).flat_map do |variant|
        gh_query = query.copy(variant)
        [
          *@mente_rule.(gh_query) do |qa|
            find_guesser('mente', qa)
          end,
          *@isimo_rule.(gh_query) do |qb|
            find(qb)
          end,
          *@auto_rule.(gh_query) do |qa|
            find(qa)
          end,
          *@inho_rule.(gh_query) do |qa|
            find(qa)
          end
        ]
      end
    end

    private

    def find(query)
      @dw.get_emissions_info(query.word, query.tags)
         .map { |tag, lemma, hyperlemma, lob_b| Result.new(query, tag, lemma, hyperlemma, lob_b) }
    end

    def find_guesser(suffix, query)
      @dw.get_guesser_result("'#{suffix}'", query.word, query.tags)
         .map { |tag, lemma, hyperlemma, lob_b| Result.new(query, tag, lemma, hyperlemma, lob_b) }
    end
  end
end
