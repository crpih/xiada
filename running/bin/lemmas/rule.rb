# frozen_string_literal: true

module Lemmas
  class Rule
    attr_reader :tags

    def initialize(all_possible_tags)
      @tags = all_possible_tags
    end

    def call(query)
      queries = apply_query(query)
      return if queries.nil?

      results = Array(queries).flat_map { |q| yield q }.compact
      results.map { |r| apply_result(r) }
    end

    def apply_query(query)
      query
    end

    def apply_result(result)
      result
    end

    def tags_for(*patterns)
      patterns.flat_map { |p| @tags.filter { |t| t.match?(p) } }.uniq
    end
  end
end
