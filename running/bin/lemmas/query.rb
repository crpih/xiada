# frozen_string_literal: true

module Lemmas
  class Query
    attr_reader :prev, :word, :tags
    def initialize(prev, word, tags)
      @prev = prev
      @word = word
      @tags = tags
    end

    def copy(word, tags = nil)
      valid_tags = tags.nil? ? @tags : @tags & tags
      Query.new(self, word, valid_tags)
    end
  end
end
