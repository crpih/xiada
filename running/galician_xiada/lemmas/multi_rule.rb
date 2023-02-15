# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class MultiRule < Rule
    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('A.*', 'Sc.*', 'V.*', 'W.*')
    end

    def apply_query(query)
      return unless query.word.match(/\Amulti(-?)(.*)\z/)

      hyphen, base = Regexp.last_match.captures

      if hyphen.empty?
        return if %w[multidade multidude].include?(query.word) # Exceptions

        if base.start_with?('rr')
          query.copy(base.delete_prefix('r'), @tags)
        else
          [query.copy(base, @tags), query.copy("i#{base}", @tags)]
        end
      else
        query.copy(base, @tags)
      end
    end

    def apply_result(query, result)
      hyphen = query.prev.word.match(/\Amulti(-?)/).captures.first

      if hyphen.empty? && result.lemma.start_with?('i')
        result.copy(nil, "mult#{result.lemma}", "multi#{result.hyperlemma}")
      elsif result.lemma.start_with?('r')
        result.copy(nil, "multir#{hyphen}#{result.lemma}", "multir#{result.hyperlemma}")
      else
        result.copy(nil, "multi#{hyphen}#{result.lemma}", "multi#{result.hyperlemma}")
      end
    end
  end
end
