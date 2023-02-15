# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class MicroRule < Rule
    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('A.*', 'Sc.*', 'V.*')
    end

    def apply_query(query)
      return unless query.word.match(/\Amicro(-?)(.*)\z/)

      hyphen, base = Regexp.last_match.captures

      if hyphen.empty?
        if base.start_with?('rr')
          query.copy(base.delete_prefix('r'), @tags)
        else
          [query.copy(base, @tags), query.copy("o#{base}", @tags)]
        end
      else
        query.copy(base, @tags)
      end
    end

    def apply_result(query, result)
      hyphen = query.prev.word.match(/\Amicro(-?)/).captures.first

      if hyphen.empty? && result.lemma.start_with?('o')
        result.copy(nil, "micro#{result.lemma}", "micro#{result.hyperlemma}")
      elsif result.lemma.start_with?('r')
        result.copy(nil, "micror#{hyphen}#{result.lemma}", "micror#{result.hyperlemma}")
      else
        result.copy(nil, "micro#{hyphen}#{result.lemma}", "micro#{result.hyperlemma}")
      end
    end
  end
end
