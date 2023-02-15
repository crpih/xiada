# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class EtnoRule < Rule
    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('A.*', 'Sc.*')
    end

    def apply_query(query)
      return unless query.word.match(/\Aetno(-?)(.*)\z/)

      hyphen, base = Regexp.last_match.captures

      if hyphen.empty? && base.start_with?('rr')
        query.copy(base.delete_prefix('r'), @tags)
      else
        query.copy(base, @tags)
      end
    end

    def apply_result(query, result)
      hyphen = query.prev.word.match(/\Aetno(-?)/).captures.first

      if result.lemma.start_with?('r')
        result.copy(nil, "etno#{hyphen}#{result.lemma}", "etnor#{result.hyperlemma}")
      else
        result.copy(nil, "etno#{hyphen}#{result.lemma}", "etno#{result.hyperlemma}")
      end
    end
  end
end
