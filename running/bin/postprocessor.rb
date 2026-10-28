# -*- coding: utf-8 -*-
require_relative "../../lib/string_utils"

# Output rules that need the selected analysis instead of the source form belong here.
# Keep analysis-time normalization in Sentence: processors such as contractions
# depend on it. This stage decides only how the final selected path is rendered.
class Postprocessor
  PROPER_NOUN_TAG = /\ASp([mf0])([sp0])\z/
  AGREEMENT_TAG = /\A(?:A|D|E|I|M|N).*([mf])([sp])\z/
  CLOSING_CONTEXT_WRAPPERS = %w[" ' ( _].freeze

  def initialize(sentence, tagger_config)
    @sentence = sentence
    @tagger_config = tagger_config
  end

  def call(tags)
    infer_proper_noun_agreement(tags)
    normalize_initial_token(tags)
    normalize_after_closing_punctuation(tags)
    tags
  end

  private

  def infer_proper_noun_agreement(tags)
    tags.each_with_index do |tag, index|
      proper_noun_match = tag_value_match(tag)
      next unless proper_noun_match

      gender, number = preceding_agreement(tags, index)
      next unless gender && number

      replacement = agreement_tag(proper_noun_match, gender, number)
      tags[index] = tag.replace_value(replacement) if replacement
    end
  end

  def tag_value_match(tag)
    tag.token.proper_noun && tag.value.match(PROPER_NOUN_TAG)
  end

  def agreement_tag(match, gender, number)
    current_gender, current_number = match.captures
    return if current_gender == gender && current_number == number

    "Sp#{gender}#{number}"
  end

  def preceding_agreement(tags, index)
    # Concordance is deliberately local. Looking farther back would let an
    # article leak through punctuation, coordination, or an intervening
    # preposition and manufacture an agreement for an unrelated proper noun.
    previous_tag = tags[index - 1]
    return unless previous_tag
    return unless previous_tag.token.token_type == :standard

    match = previous_tag.value.match(AGREEMENT_TAG)
    match && match.captures
  end

  def normalize_initial_token(tags)
    first_tag = tags.find { |tag| first_lexical_token?(tag.token) }
    return unless first_tag
    return if preserve_token_capitalization?(first_tag)

    first_tag.token.replace_text(StringUtils.first_to_lower(first_tag.token.text))
  end

  def first_lexical_token?(token)
    return false unless token.token_type == :standard

    !StringUtils.initial_ignorable_token?(token.text)
  end

  def normalize_after_closing_punctuation(tags)
    tags.each_with_index do |tag, index|
      next if index.zero?

      next unless closing_punctuation_before?(tags, index)
      next unless first_lexical_token?(tag.token)
      next if preserve_token_capitalization?(tag)

      tag.token.replace_text(StringUtils.first_to_lower(tag.token.text))
    end
  end

  def closing_punctuation_before?(tags, index)
    previous_index = index - 1
    while previous_index >= 0 && CLOSING_CONTEXT_WRAPPERS.include?(tags[previous_index].token.text)
      previous_index -= 1
    end

    previous_tag = tags[previous_index]
    previous_tag && previous_tag.token.token_type == :standard && %w[? !].include?(previous_tag.token.text)
  end

  def preserve_token_capitalization?(tag)
    tag.value.match?(@tagger_config.keep_uppercase_tokens_for) ||
      @sentence.acronym_or_abbreviation?(tag.token.text) ||
      oral_forced_proper_noun?(tag)
  end

  def oral_forced_proper_noun?(tag)
    @tagger_config.profile == 'galician_xiada_oral' &&
      @tagger_config.force_proper_nouns &&
      tag.token.proper_noun
  end
end
