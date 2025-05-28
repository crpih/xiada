# frozen_string_literal: true
require_relative "../bin/lemmas/query"
require_relative "../bin/lemmas/result"
require_relative "../bin/lemmas/utils"
require_relative "lemmas/isimo_rule"
require_relative "lemmas/mente_rule"
require_relative "lemmas/inho_rule"
require_relative "lemmas/ex_rule"
require_relative "lemmas/ex_proper_rule"
require_relative "lemmas/prefix_vowel"
require_relative "lemmas/prefix_parens"

module GalicianXiada
  class Lemmatizer
    include Lemmas::Utils

    def initialize(tagger_config)
      @tagger_config = tagger_config
      @tags = @tagger_config.dw.get_possible_tags([ "*" ]).split(",").map { |t| t.delete_prefix("'").delete_suffix("'") }

      @mente_rule = Lemmas::MenteRule.new(@tags)
      @isimo_rule = Lemmas::IsimoRule.new(@tags)
      @inho_rule = Lemmas::InhoRule.new(@tags)
      @ex_proper_rule = Lemmas::ExProperRule.new(@tags)
      @ex_rule = Lemmas::ExRule.new(@tags)

      @prefix_rules = [
        # Prefixes that end in a vowel
        Lemmas::PrefixVowel::AutoRule.new(@tags),
        Lemmas::PrefixVowel::MetaRule.new(@tags),
        Lemmas::PrefixVowel::EtnoRule.new(@tags),
        Lemmas::PrefixVowel::MacroRule.new(@tags),
        Lemmas::PrefixVowel::MicroRule.new(@tags),
        Lemmas::PrefixVowel::XeoRule.new(@tags),
        Lemmas::PrefixVowel::MultiRule.new(@tags),
        Lemmas::PrefixVowel::TeleRule.new(@tags),
        # Prefixes with parens
        Lemmas::PrefixParens::DesRule.new(@tags),
        Lemmas::PrefixParens::ExRule.new(@tags),
        Lemmas::PrefixParens::MacroRule.new(@tags),
        Lemmas::PrefixParens::MicroRule.new(@tags),
        Lemmas::PrefixParens::PreRule.new(@tags),
        Lemmas::PrefixParens::ReRule.new(@tags),
        Lemmas::PrefixParens::Semi.new(@tags),
        Lemmas::PrefixParens::SubRule.new(@tags),
      ]
    end

    def lemmatize(document_config, word, tags)
      result = call(document_config, word, tags)
      result&.any? ? result.map { |r| [ r.tag, r.lemma, r.hyperlemma, r.log_b ] } : []
    end

    # Function which is called before accessing emission frequencies for verbs with enclitics pronouns.
    # All enclitics processing needs a refactor to work well with the new lemmatizer.
    def lemmatize_verb_with_enclitics(document_config, left_part)
      gheada_variants(left_part).flat_map do |gh_variant|
        ss_variants = seseo_variants(gh_variant)
        # Keep only the literal word (first) unless seseo
        ss_variants = ss_variants.take(1) unless document_config.seseo
        ss_variants.map { |s| enclitics_auto_rule(s) }
      end
    end

    def call(document_config, word, tags)
      # If tags are not provided, use all possible tags
      tags = tags.nil? || tags.empty? ? @tags : tags

      q = Lemmas::Query.new(nil, word, tags)
      unaccented_queries(q) do |q|
        gheada_queries(document_config, q) do |q|
          seseo_queries(document_config, q) do |q|
            # LemmatizerCorga#lemmatizer won't be called if the term exists literally
            # So this is useful only for gheada and seseo variants: gherra => guerra and ghitarra => guitarra
            literal_result = find(q)
            return literal_result if literal_result.any?

            # Try prefix and suffix first
            prefix_suffix_result = prefix_suffix_rules(q)
            return prefix_suffix_result if prefix_suffix_result.any?

            # Try accented variants with all rules
            try_accented_variants_rules(q)
          end
        end
      end
    end

    private

    # Simplified auto rule that only works with strings
    # Proper way to do it will be to use the same rules as in the lemmatizer, but this will require a huge refactor
    def enclitics_auto_rule(left_part)
      return left_part.delete_prefix("autor") if left_part.start_with?("autorr")
      return left_part.delete_prefix("auto-") if left_part.start_with?("auto-")
      return left_part.delete_prefix("auto") if left_part.start_with?("auto")

      left_part
    end

    def unaccented_queries(query)
      unaccented_variants(query.word).flat_map { |v| yield query.copy(v) }
    end

    def accented_queries(query)
      tilde_variants(query.word).flat_map { |v| yield query.copy(v) }
    end

    def gheada_queries(document_config, query)
      return yield query unless document_config.gheada

      gheada_variants(query.word).flat_map { |v| yield query.copy(v) }
    end

    def seseo_queries(document_config, query)
      return yield query unless document_config.seseo

      seseo_variants(query.word).flat_map { |v| yield query.copy(v) }
    end

    # For each accented variant try all the rules except ex-proper, -ísimo, -iño and -mente
    def try_accented_variants_rules(query)
      accented_queries(query) do |q|
        literal_result = find(q)
        return literal_result if literal_result.any?

        @prefix_rules.flat_map { |rule| rule.(q) { accented_suffix_rules(it) } }
      end
    end

    # All suffix rules except "mente" that manages the accented variants itself and it will interfere
    def accented_suffix_rules(query)
      literal_result = find(query)
      return literal_result if literal_result.any?

      [
        *@isimo_rule.(query) { |qa| find(qa) },
        *@inho_rule.(query) { |qa| find(qa) },
      ]
    end

    def prefix_suffix_rules(query)
      [
        # Ex and ExProper are different to other prefix rules
        *@ex_proper_rule.(query) { proper_noun(it) },
        *@ex_rule.(query) { suffix_rules(it) },
        # General prefix rules
        *@prefix_rules.flat_map { |rule| rule.(query) { suffix_rules(it) } },
        # Use only suffix rules as fallback if no prefix rule matches
        *suffix_rules(query),
      ]
    end

    def suffix_rules(query)
      literal_result = find(query)
      return literal_result if literal_result.any?

      [
        *@mente_rule.(query) { |qa| find_guesser("mente", qa) },
        *@isimo_rule.(query) { |qa| find(qa) },
        *@inho_rule.(query) { |qa| find(qa) },
      ]
    end

    def find(query)
      @tagger_config.dw.get_emissions_info(query.word, query.tags)
                    .map { |tag, lemma, hyperlemma, lob_b| Lemmas::Result.new(query, nil, tag, lemma, hyperlemma, lob_b) }
    end

    def find_guesser(suffix, query)
      @tagger_config.dw.get_guesser_result("'#{suffix}'", query.word, query.tags)
                    .map { |tag, lemma, hyperlemma, lob_b| Lemmas::Result.new(query, nil, tag, lemma, hyperlemma, lob_b) }
    end

    def proper_noun(query)
      [ Lemmas::Result.new(query, nil, "Sp00", query.word, query.word, 0.0) ]
    end
  end
end
