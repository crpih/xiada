# -*- coding: utf-8 -*-
require_relative "../../lib/string_utils"

# Output rules that need the selected analysis instead of the source form belong here.
# Keep analysis-time normalization in Sentence: processors such as contractions
# depend on it. This stage decides only how the final selected path is rendered.
class Postprocessor
  def initialize(sentence, tagger_config)
    @sentence = sentence
    @tagger_config = tagger_config
  end

  def call(tags)
    normalize_initial_token(tags)
    tags
  end

  private

  def normalize_initial_token(tags)
    first_tag = tags.find { |tag| first_lexical_token?(tag.token) }
    return unless first_tag
    return if preserve_initial_capitalization?(first_tag)

    first_tag.token.replace_text(StringUtils.first_to_lower(first_tag.token.text))
  end

  def first_lexical_token?(token)
    return false unless token.token_type == :standard

    !StringUtils.initial_ignorable_token?(token.text)
  end

  def preserve_initial_capitalization?(tag)
    tag.value.match?(@tagger_config.keep_uppercase_tokens_for) ||
      @sentence.acronym_or_abbreviation?(tag.token.text)
  end
end
