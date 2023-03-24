# frozen_string_literal: true
require_relative '../../bin/lemmas/rule'
require_relative 'utils'

module Lemmas
  class PrefixVowelRule < Rule
    include Utils

    def initialize(all_possible_tags, prefix)
      super(all_possible_tags)
      @prefix = prefix
      @base_prefix = prefix[0...-1]
      @vowel = prefix[-1]
    end

    def tags
      raise NotImplementedError
    end

    def apply_query(query)
      return unless query.word.match(/\A#{@prefix}(-?)(.*)\z/)

      hyphen, base = Regexp.last_match.captures

      if hyphen.empty?
        if base.start_with?('rr')
          query.copy(base.delete_prefix('r'), tags)
        else
          [query.copy(base, tags), query.copy("#{@vowel}#{base}", tags)]
        end
      else
        query.copy(base, tags)
      end
    end

    def apply_result(query, result)
      hyphen, base = query.prev.word.match(/\A#{@prefix}(-?)(.*)\z/).captures

      if hyphen.empty? && base.start_with?(@vowel)
        # Preserve double vowel in lemma and hyperlemma if it is also present in base.
        # E.g: microorganismo => microorganismo / microorganismo
        result.copy(nil, "#{@prefix}#{result.lemma}", if_hyperlemma(result) { |v| "#{@prefix}#{v}" })
      elsif hyphen.empty? && result.lemma.start_with?(@vowel)
        # If lemma starts with the last prefix vowel, remove double vowel in lemma but keep it io hyperlemma.
        # E.g: microrganismo => microrganismo / microorganismo
        result.copy(nil, "#{@base_prefix}#{result.lemma}", if_hyperlemma(result) { |v| "#{@prefix}#{v}" })
      elsif hyphen.empty? && base.start_with?('rr')
        # If there is a 'rr' after the prefix and there is no hyphen, 'rr' must be also present in lemma and hyperlemma
        # microrredada => microrredada / microrredada
        result.copy(nil, "#{@prefix}r#{result.lemma}", if_hyperlemma(result) { |v| "#{@prefix}r#{v}" })
      elsif hyphen.empty? && result.lemma.start_with?('r')
        # If lemma starts with 'r', there is no hyphen but there is a single 'r' after the prefix, 'rr' must be present
        # in hyperlemma, but single 'r' must be used in lemma
        # microrepetidor => microrepetidor / microrrepetidores
        result.copy(nil, "#{@prefix}#{result.lemma}", if_hyperlemma(result) { |v| "#{@prefix}r#{v}" })
      elsif result.lemma.start_with?('r')
        # If lemma starts with 'r', but there is an hyphen after the prefix, remove the hyphen and duplicate 'r' in hyperlemma
        # micro-relato => micro-relato / microrrelatos
        result.copy(nil, "#{@prefix}#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "#{@prefix}r#{v}" })
      else
        # Otherwise recompose prefix and hyphen (if present) in lemma and prefix in hyperlemma.
        result.copy(nil, "#{@prefix}#{hyphen}#{result.lemma}", if_hyperlemma(result) { |v| "#{@prefix}#{v}" })
      end
    end
  end
end