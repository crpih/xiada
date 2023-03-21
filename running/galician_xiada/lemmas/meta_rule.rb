# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class MetaRule < Rule
    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('A.*', 'Sc.*')
    end

    def apply_query(query)
      return unless query.word.match(/\Ameta(-?)(.*)\z/)
      return if %w[meta-lo meta-la meta-los meta-las].include?(query.word)

      hyphen, base = Regexp.last_match.captures

      if hyphen.empty?
        if base.start_with?('rr')
          query.copy(base.delete_prefix('r'), @tags)
        else
          [query.copy(base, @tags), query.copy("a#{base}", @tags)]
        end
      else
        query.copy(base, @tags)
      end
    end

    def apply_result(query, result)
      hyphen = query.prev.word.match(/\Ameta(-?)/).captures.first

      # Keep double 'a' in lemma in the case of 'metaanalise', remove it in 'metanálise'
      if hyphen.empty? && result.lemma.start_with?('a') && !query.prev.word.match?(/\Ameta[aá]/)
        result.copy(nil, "met#{result.lemma}", "meta#{result.hyperlemma}")
      elsif result.lemma.start_with?('r')
        result.copy(nil, "metar#{hyphen}#{result.lemma}", "metar#{result.hyperlemma}")
      else
        result.copy(nil, "meta#{hyphen}#{result.lemma}", "meta#{result.hyperlemma}")
      end
    end
  end
end
