# frozen_string_literal: true

module Lemmas
  class Result
    attr_reader :query, :tag, :lemma, :hyperlemma, :log_b

    def initialize(query, tag, lemma, hyperlemma, log_b)
      @query = query
      @tag = tag
      @lemma = lemma
      @hyperlemma = hyperlemma
      @log_b = log_b
    end

    def copy(tag = nil, lemma = nil, hyperlemma = nil)
      Result.new(@query, tag || @tag, lemma || @lemma, hyperlemma || @hyperlemma, @log_b)
    end

    def to_a
      [@tag, @lemma, @hyperlemma, @log_b]
    end
  end
end
