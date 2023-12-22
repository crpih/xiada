# frozen_string_literal: true

module Lemmas
  class Result
    attr_reader :query, :word, :tag, :lemma, :hyperlemma, :log_b

    def initialize(query, word, tag, lemma, hyperlemma, log_b)
      @query = query
      @word = word || query.each { |q| break q.word if q.prev.nil? }
      @tag = tag
      @lemma = lemma
      @hyperlemma = hyperlemma
      @log_b = log_b
    end

    def copy(word: nil, tag: nil, lemma: nil, hyperlemma: nil)
      Result.new(@query, word || @word, tag || @tag, lemma || @lemma, hyperlemma || @hyperlemma, @log_b)
    end

    def to_a
      [@tag, @lemma, @hyperlemma, @log_b]
    end
  end
end
