# frozen_string_literal: true
require_relative '../../bin/lemmas/query'
require_relative '../../bin/lemmas/result'
require_relative 'gheada_transform'
require_relative 'auto_rule'
require_relative 'isimo_rule'
require_relative 'mente_rule'
require_relative 'inho_rule'

module Lemmas
  class LemmatizerCorga
    def initialize(database_wrapper)
      @dw = database_wrapper
      @tags = @dw.get_possible_tags(['*']).split(',').map { |t| t.delete_prefix("'").delete_suffix("'") }
      @mente_rule = MenteRule.new(@tags)
      @auto_rule = AutoRule.new(@tags)
      @isimo_rule = IsimoRule.new(@tags)
      @gheada_transform = GheadaTransform.new(@tags)
    end

    def call(word)
      query = Query.new(word, @tags)
      [
        *@mente_rule.(query) do |qa|
          find_guesser('mente', qa)
        end,
        *@gheada_transform.(query) do |qa|
          @isimo_rule.(qa) do |qb|
            find(qb)
          end
        end,
        *@auto_rule.(query) do |qa|
          find(qa)
        end
      ]
    end

    private

    def find(query)
      @dw.get_emissions_info(query.search_word, query.tags)
         .map { |tag, lemma, hyperlemma, lob_b| Result.new(query, tag, lemma, hyperlemma, lob_b) }
    end

    def find_guesser(suffix, query)
      @dw.get_guesser_result("'#{suffix}'", query.search_word, query.tags)
         .map { |tag, lemma, hyperlemma, lob_b| Result.new(query, tag, lemma, hyperlemma, lob_b) }
    end
  end
end
