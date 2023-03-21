# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class XeoRule < Rule
    include Utils

    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('A.*', 'Sc.*', 'V.*')
    end

    def apply_query(query)
      return unless query.word.match(/\Axeo(-?)(.*)\z/)

      hyphen, base = Regexp.last_match.captures

      if hyphen.empty? && base.start_with?('rr')
        query.copy(base.delete_prefix('r'), @tags)
      else
        query.copy(base, @tags)
      end
    end

    def apply_result(query, result)
      hyphen, base = query.prev.word.match(/\Axeo(-?)(.*)/).captures

      if hyphen.empty? && base.start_with?('rr')
        result.copy(nil, "xeor#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "xeor#{v}" })
      elsif result.lemma.start_with?('r')
        result.copy(nil, "xeo#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "xeor#{v}" })
      else
        result.copy(nil, "xeo#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "xeo#{v}" })
      end
    end
  end
end
