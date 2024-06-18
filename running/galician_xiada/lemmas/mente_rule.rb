# frozen_string_literal: true
require_relative '../../../lib/string_utils'
require_relative '../../bin/lemmas/rule'

module Lemmas
  class MenteRule < Rule

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('W.*')
    end
    def apply_query(query)
      return unless query.word.end_with?('mente')
      return if query.tags.any? && query.tags.all? { |t| t.start_with?('Sp') }

      query.copy(query.word, @tags)
    end

    def apply_result(result)
      hyperlemma = StringUtils.without_tilde(result.query.word)
      hyperlemma = "#{hyperlemma.delete_suffix('belmente')}blemente" if hyperlemma.end_with?('belmente')
      result.copy(hyperlemma:)
    end
  end
end
