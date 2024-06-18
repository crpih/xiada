# frozen_string_literal: true

module Lemmas
  class Rule
    TAG_GN_REPLACEMENTS = {
      'a' => { '' => 'fs', 's' => 'fp' }.freeze,
      'o' => { '' => 'ms', 's' => 'mp' }.freeze,
    }.freeze

    attr_reader :tags

    def initialize(all_possible_tags)
      @all_tags = all_possible_tags
    end

    def call(query)
      queries = Array(apply_query(query))

      # Keep result of first query that generates a non-empty result
      queries.each do |q|
        result = yield q
        return result.map { |r| apply_result(r) } if result&.any?
      end
      # If none of the generated queries returned a result, return empty array
      []
    end

    def apply_query(query)
      query
    end

    def apply_result(result)
      result
    end

    protected

    def tags_for(*patterns)
      patterns.flat_map { |p| @all_tags.filter { |t| t.match?(p) } }.uniq.freeze
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

    def replace_tag_gn(tag, g, n)
      # Exclude second and third levels of verbs and pronouns from replacement
      tag.sub(/(?<!\A[VR])[maf][spa]/, TAG_GN_REPLACEMENTS[g][n])
    end
  end
end
