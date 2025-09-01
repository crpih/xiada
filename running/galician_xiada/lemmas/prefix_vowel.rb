# frozen_string_literal: true
require_relative "../../bin/lemmas/rule"
require_relative "../../bin/lemmas/utils"

module Lemmas
  module PrefixVowel
    class PrefixVowelRule < Rule
      include Utils

      attr_reader :tags

      def initialize(all_possible_tags, prefix, *patterns)
        super(all_possible_tags)
        @prefix = prefix
        @base_prefix = prefix[0...-1]
        @vowel = prefix[-1]
        @tags = tags_for(*patterns)
      end

      def apply_query(query)
        return unless query.word.match(/\A#{@prefix}(-?)(.*)\z/)

        hyphen, base = Regexp.last_match.captures
        return if base.length < 2 # Exclude empty or single character bases

        if hyphen.empty?
          if base.start_with?("rr")
            query.copy(base.delete_prefix("r"), tags)
          else
            [query.copy(base, tags), query.copy("#{@vowel}#{base}", tags)]
          end
        else
          query.copy(base, tags)
        end
      end

      def apply_result(result)
        hyphen, base = result.query.each { |q| break Regexp.last_match.captures if q.word.match(/\A#{@prefix}(-?)(.*)\z/) }
        word = result.query.word

        if hyphen.empty? && base.start_with?(@vowel)
          # Preserve double vowel in lemma and hyperlemma if it is also present in base.
          # E.g: microorganismo => microorganismo / microorganismo
          result.copy(word: "#{@prefix}#{word}", lemma: "#{@prefix}#{result.lemma}", hyperlemma: if_hyperlemma(result) { |v| "#{@prefix}#{v}" })
        elsif hyphen.empty? && result.lemma.start_with?(@vowel)
          # If lemma starts with the last prefix vowel, remove double vowel in lemma but keep it io hyperlemma.
          # E.g: microrganismo => microrganismo / microorganismo
          result.copy(word: "#{@base_prefix}#{word}", lemma: "#{@base_prefix}#{result.lemma}", hyperlemma: if_hyperlemma(result) { |v| "#{@prefix}#{v}" })
        elsif hyphen.empty? && base.start_with?("rr")
          # If there is a "rr" after the prefix and there is no hyphen, "rr" must be also present in lemma and hyperlemma
          # microrredada => microrredada / microrredada
          result.copy(word: "#{@prefix}r#{word}", lemma: "#{@prefix}r#{result.lemma}", hyperlemma: if_hyperlemma(result) { |v| "#{@prefix}r#{v}" })
        elsif hyphen.empty? && result.lemma.start_with?("r")
          # If lemma starts with "r", there is no hyphen but there is a single "r" after the prefix, "rr" must be present
          # in hyperlemma, but single "r" must be used in lemma
          # microrepetidor => microrepetidor / microrrepetidores
          result.copy(word: "#{@prefix}#{word}", lemma: "#{@prefix}#{result.lemma}", hyperlemma: if_hyperlemma(result) { |v| "#{@prefix}r#{v}" })
        elsif result.lemma.start_with?("r")
          # If lemma starts with "r", but there is an hyphen after the prefix, remove the hyphen and duplicate "r" in hyperlemma
          # micro-relato => micro-relato / microrrelatos
          result.copy(word: "#{@prefix}#{hyphen}#{word}", lemma: "#{@prefix}#{hyphen}#{result.lemma}", hyperlemma: if_hyperlemma(result) { |v| "#{@prefix}r#{v}" })
        else
          # Otherwise recompose prefix and hyphen (if present) in lemma and prefix in hyperlemma.
          result.copy(word: "#{@prefix}#{hyphen}#{word}", lemma: "#{@prefix}#{hyphen}#{result.lemma}", hyperlemma: if_hyperlemma(result) { |v| "#{@prefix}#{v}" })
        end
      end
    end


    class AutoRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun: "S.*", adverb: "W.*", verb: "V.*")
        super(all_possible_tags, "auto", adjective, noun, adverb, verb)
      end
    end

    class EtnoRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*")
        super(all_possible_tags, "etno", adjective, noun_common)
      end
    end

    class MacroRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*")
        super(all_possible_tags, "macro", adjective, noun_common, verb)
      end
    end

    class MetaRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*")
        super(all_possible_tags, "meta", adjective, noun_common)
      end

      def apply_query(query) = %w[meta-lo meta-la meta-los meta-las].include?(query.word) ? nil : super(query)
    end

    class MicroRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*")
        super(all_possible_tags, "micro", adjective, noun_common, verb)
      end
    end

    class MultiRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "multi", adjective, noun_common, verb, adverb)
      end

      def apply_query(query) = %w[multidade multidude].include?(query.word) ? nil : super(query)
    end

    class TeleRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "tele", adjective, noun_common, verb, adverb)
      end
    end

    class XeoRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*")
        super(all_possible_tags, "xeo", adjective, noun_common, verb)
      end
    end

    class NanoRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "nano", adjective, noun_common, verb, adverb)
      end
    end

    class NarcoRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "narco", adjective, noun_common, verb, adverb)
      end
    end

    class ExtraRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "extra", adjective, noun_common, verb, adverb)
      end
    end

    class IntraRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "intra", adjective, noun_common, verb, adverb)
      end
    end

    class InfraRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "infra", adjective, noun_common, verb, adverb)
      end
    end

    class SupraRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "supra", adjective, noun_common, verb, adverb)
      end
    end

    class ContraRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "contra", adjective, noun_common, verb, adverb)
      end
    end

    class HeteroRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "hetero", adjective, noun_common, verb, adverb)
      end
    end

    class PaleoRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "paleo", adjective, noun_common, verb, adverb)
      end
    end

    class VideoRule < PrefixVowelRule
      def initialize(all_possible_tags, adjective: "A.*", noun_common: "Sc.*", verb: "V.*", adverb: "W.*")
        super(all_possible_tags, "video", adjective, noun_common, verb, adverb)
      end
    end
  end
end
