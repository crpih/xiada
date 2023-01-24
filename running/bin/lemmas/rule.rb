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

      # Keep result of  first query that generates a non-empty result
      Array(queries).each do |q|
        result = yield q
        return result.map { |r| apply_result(r) } if result&.any?
      end
      nil
    end

    def apply_query(query)
      query
    end

    def apply_result(result)
      result
    end

    protected

    def tags_for(*patterns)
      patterns.flat_map { |p| @tags.filter { |t| t.match?(p) } }.uniq.freeze
    end

    def tags_by_gn(*patterns)
      tags = tags_for(*patterns)
      m_tags = tags.filter { |t| t.match?(/m.\z/) }
      f_tags = tags.filter { |t| t.match?(/f.\z/) }
      {
        'a' => {
          '' => f_tags.filter { |t| t.end_with?('s') }.freeze,
          's' => f_tags.filter { |t| t.end_with?('p') }.freeze,
        }.freeze,
        'o' => {
          '' => m_tags.filter { |t| t.end_with?('s') }.freeze,
          's' => m_tags.filter { |t| t.end_with?('p') }.freeze,
        }.freeze
      }.freeze
    end
  end
end
