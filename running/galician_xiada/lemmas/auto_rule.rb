# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'

module Lemmas
  class AutoRule < Rule
    def initialize(all_possible_tags)
      super(all_possible_tags)
      @tags = tags_for('A.*', 'S.*', 'W.*', 'V.*')
    end

    def apply_query(query)
      return unless query.word.match(/\Aauto(-?)(.*)\z/)

      _hyphen, base = Regexp.last_match.captures

      if base.start_with?('rr')
        # autorreflexión => reflexión
        query.copy(base.delete_prefix('r'), @tags)
      else
        # TODO: Documented case wrong, real transformation was: auto-axudas => axudas
        # auto-axudas => axuda
        # autoxestión => xestión
        query.copy(base, @tags)
      end
    end

    def apply_result(query, result)
      hyphen = query.prev.word.match(/\Aauto(-?)/).captures.first

      if result.lemma.start_with?('r') && hyphen.empty?
        # autorreflexión => reflexión => autorreflexión
        lemma = "autor#{hyphen}#{result.lemma}"
        result.copy(nil, lemma, lemma)
      else
        # TODO: Documented case wrong, real transformation was: auto-axudas => axudas => auto-axuda
        # auto-axudas => axuda => auto-axuda
        # autoxestión => xestión => autoxestión
        lemma = "auto#{hyphen}#{result.lemma}"
        result.copy(nil, lemma, lemma)
      end
    end
  end
end
