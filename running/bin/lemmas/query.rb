# frozen_string_literal: true

module Lemmas
  class Query
    attr_reader :word, :search_word, :tags
    def initialize(word, tags, search_word = nil)
      @word = word
      @search_word = search_word || word
      @tags = tags
    end

    def copy(search_word, tags = nil)
      valid_tags = tags.nil? ? @tags : @tags & tags
      Query.new(@word, valid_tags, search_word)
    end
  end
end
