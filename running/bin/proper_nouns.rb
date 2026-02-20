require 'set'
require 'csv'
require 'active_support/core_ext/range/overlap'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/enumerable'

class ProperNouns

  Literal = Struct.new(:text, :tag_lemmas, :lexicon)

  WRAPPER_START_CHARS = %w[" ' (].freeze

  class Segment
    attr_reader :range, :text, :tag_lemmas, :lexicon
    delegate :begin, :end, :size, to: :range

    def initialize(range, text, tag_lemmas, lexicon)
      @range = range
      @text = text
      @tag_lemmas = tag_lemmas
      @lexicon = lexicon
    end

    def lexicon? = @lexicon

    def overlaps?(other) = range.overlaps?(other.range)

    def merge(source_text, other)
      merged_range = [ range.begin, other.begin ].min...[ range.end, other.end ].max
      merge_text = source_text[merged_range]
      Segment.new(merged_range, merge_text, merge_tag_lemmas(other, merge_text), lexicon? || other.lexicon?)
    end

    def to_literal = Literal.new(text, tag_lemmas, @lexicon)

    def to_s = inspect

    def inspect = "<#{self.class} #{range.inspect} #{text.inspect} #{tag_lemmas.inspect}>"

    def ==(other)
      other.is_a?(Segment) && range == other.range && text == other.text && tag_lemmas == other.tag_lemmas
    end

    private

    # Lexicon has priority always. In case of tie, merge all tags and set lemma to the merge text
    def merge_tag_lemmas(other, merge_text)
      if lexicon? && other.lexicon? || !lexicon? && !other.lexicon?
        merge_tags_tie(other, merge_text)
      elsif lexicon? && range.cover?(other.range)
        tag_lemmas
      elsif lexicon?
        tag_lemmas.map { |t, _| [ t, merge_text ] }
      elsif other.lexicon? && other.range.cover?(range)
        other.tag_lemmas
      else
        # other.lexicon?
        other.tag_lemmas.map { |t, _| [ t, merge_text ] }
      end
    end

    def merge_tags_tie(other, merge_text)
      if range.cover?(other.range)
        tag_lemmas
      elsif other.range.cover?(range)
        other.tag_lemmas
      else
        # TODO: Union
        # - keep only tags with gender and number
        # - if empty, keep only gender
        # - if still empty, keep only number
        # - if still empty, keep all tags
        [ *tag_lemmas, *other.tag_lemmas ].map(&:first).uniq.sort.map { |t| [ t, merge_text ] }
      end
    end
  end

  def self.parse_literals_file(file_path)
    CSV.read(file_path, col_sep: "\t").to_a.group_by(&:first).map do |text, elements|
      Literal.new(text, elements.map { |_, tag, lemma| [ tag, lemma ] }.uniq, true)
    end
  end

  def self.parse_main_lexicon(file_path)
    parse_literals_file(file_path).index_by(&:text)
  end

  attr_reader :force_proper_nouns

  def initialize(
    main_lexicon,
    literal_proper_nouns,
    ambiguous_literal_proper_nouns,
    joiners,
    tags,
    trained_proper_nouns: [],
    acronyms: Set.new,
    abbreviations: Set.new,
    force_proper_nouns: false)
    @main_lexicon = main_lexicon
    @literal_proper_nouns = literal_proper_nouns
    @ambiguous_literal_proper_nouns = ambiguous_literal_proper_nouns
    @trained_proper_nouns = trained_proper_nouns
    @joiners = joiners
    @joiners_regex = /\A\p{Z}\z|\A\p{Pd}\z|\A\p{Z}?(?:#{joiners.map { |joiner| Regexp.escape(joiner) }.join('|')})\p{Z}?\z/
    @tags = tags
    @acronyms = acronyms
    @abbreviations = abbreviations
    # If true, uppercase words at the start of the text are also considered proper noun candidates
    @force_proper_nouns = force_proper_nouns
  end

  # Create a new ProperNouns instance with the trained proper nouns from the given texts.
  # The trained proper nouns are the standard proper nouns detected in the texts that are not ambiguous and not in lexicon.
  def with_trained(texts)
    trained_proper_nouns = texts.flat_map { |t| standard_proper_nouns(t).map(&:to_literal) }
                                .uniq.reject { @main_lexicon.include?(it.text) }
    self.class.new(
      @main_lexicon,
      @literal_proper_nouns,
      @ambiguous_literal_proper_nouns,
      @joiners,
      @tags,
      trained_proper_nouns:,
      acronyms: @acronyms,
      abbreviations: @abbreviations,
      force_proper_nouns: @force_proper_nouns
    )
  end

  def call(text)
    literal_segments = literal_proper_nouns(text, @literal_proper_nouns)
    ambiguous_segments = ambiguous_literal_proper_nouns(text, @ambiguous_literal_proper_nouns)
    standard_segments = standard_proper_nouns(text)
    trained_segments = trained_proper_nouns(text)
    candidate_segments = [ *literal_segments, *ambiguous_segments, *standard_segments, *trained_segments ]
    noun_ranges = join_proper_nouns(text, candidate_segments)
    result = split_text_by_proper_nouns(text, noun_ranges)
    add_main_lexicon_tags_to_first_proper_noun!(result)
    result
  end

  private

  def join_proper_nouns(text, segments)
    current_segment, *rest = segments.sort_by { |r| [ r.begin, r.size ] }
    return [] if current_segment.nil?

    # Expand the first segment if it is the second word and the first word starts with uppercase
    proper_noun_is_second_word = current_segment.begin > 0 && !text[...current_segment.begin - 1].include?(" ")
    text_begins_with_upper = text.match?(/\A\p{Upper}/)
    text_beginning_is_unknown_word = !@main_lexicon.include?(text[0...current_segment.begin].downcase.strip)
    if proper_noun_is_second_word && text_begins_with_upper && text_beginning_is_unknown_word
      with_start = text[0...current_segment.end]
      tag_lemmas = current_segment.tag_lemmas.map { |t, _| [ t, with_start ] }
      current_segment = Segment.new(0...current_segment.end, with_start, tag_lemmas, current_segment.lexicon)
    end

    result = []
    rest.each do |segment|
      if current_segment.overlaps?(segment) ||
        current_segment.end == segment.begin ||
        text[current_segment.end...segment.begin].match?(@joiners_regex)
        # Merge overlapping, adjacent and ranges separated by a joiner
        current_segment = current_segment.merge(text, segment)
      else
        # No more ranges to merge, add current range to result and start a new one
        result << current_segment
        current_segment = segment
      end
    end
    result << current_segment
    result
  end

  def split_text_by_proper_nouns(text, segments)
    return [ text ] if segments.empty?

    last_pos, all_ranges = segments.inject([ 0, [] ]) do |(i, result), segment|
      result << text[i...segment.begin] if i < segment.begin
      result << segment.to_literal
      [ segment.end, result ]
    end
    all_ranges << text[last_pos...text.size] if last_pos < text.size
    all_ranges
  end

  def add_main_lexicon_tags_to_first_proper_noun!(segmented_text)
    first_element = segmented_text.first
    return unless first_element.is_a?(Literal)

    word = first_element.text
    word_first_lowercase = "#{word[0].downcase}#{word[1..]}"
    first_element.tag_lemmas = [ first_element, @main_lexicon[word], @main_lexicon[word_first_lowercase] ].compact.flat_map(&:tag_lemmas).uniq
  end

  def literal_proper_nouns(text, literals)
    literals_in_text(text, literals) { |r, l| Segment.new(r, text[r], l.tag_lemmas, l.lexicon) }
  end

  def ambiguous_literal_proper_nouns(text, literals)
    literals_in_text(text, literals) do |range, literal|
      # Skip if the literal is at the beginning of the text or is preceded by a wrapper start char
      next if range.begin == 0
      next if range.begin == 1 && WRAPPER_START_CHARS.include?(text[0])

      Segment.new(range, text[range], literal.tag_lemmas, literal.lexicon)
    end
  end

  def trained_proper_nouns(text)
    result = []
    @trained_proper_nouns.each do |trained|
      each_substring_index(text, trained.text) do |start_index|
        next if start_index.nil?
        return if ambiguous_position?(text, start_index) && @main_lexicon.include?(text.downcase.strip)

        range = start_index...(start_index + trained.text.size)
        result << Segment.new(range, text[range], trained.tag_lemmas, trained.lexicon)
      end
    end
    result
  end

  def literals_in_text(text, literals)
    result = []
    literals.each do |literal|
      each_substring_index(text, literal.text) do |start_index|
        next if start_index.nil?
        next if start_index > 0 && text[start_index - 1].match?(/\p{L}|\p{N}|-/) # Ensure not part of a larger word

        end_index = start_index + literal.text.size
        next if end_index < text.size && text[end_index].match?(/\p{L}|\p{N}|-/) # Ensure not part of a larger word

        range = start_index...end_index

        segment = yield(range, literal)
        result << segment unless segment.nil?
      end
    end
    result
  end

  def standard_proper_nouns(text)
    # Candidate proper noun positions are uppercase letters that are not at the beginning of the text
    # If @force_proper_nouns is true then also consider uppercase letters at the beginning of the text
    candidate_starts = text.each_char.each_with_index.filter_map { |c, i| i if c.match?(/\p{Upper}/) && (@force_proper_nouns || !i.zero?) }
    ranges = candidate_starts.filter_map { |i| unambiguous_proper_noun_range(i, text) }
    ranges.map { |r| Segment.new(r, text[r], @tags.map { |t| [ t, text[r] ] }.sort, false) }
  end

  def unambiguous_proper_noun_range(i, text)
    # If all previous text before the candidate is punctuation and spaces, is a false positive
    return if text[...i].match?(/\A[\p{P}\p{Z}]+\z/)
    # If there is a letter before the candidate is a false positive (GZMúsica, position 1 "M")
    return if text[i - 1].match?(/\p{L}/)
    return if ambiguous_position?(text, i)

    match = match_proper_noun(text[i..])
    return unless match

    # If:
    # - the match text is after a wrapper char or is at the beginning of the text
    # - and lowercase match is in the main lexicon, is a false positive (e.g. "Non")
    return if (starts_with_wrapper?(text, i) || i.zero?) && @main_lexicon.include?(match.downcase.strip)

    i...(i + match.size)
  end

  def match_proper_noun(text)
    text.match(/
      \A(?:
        # Camel case (YouTube, UVigo)
        (\p{Upper}\p{Lower}*(?:\p{Upper}\p{Lower}+)+) |
        # Separated by one hyphen (Barcelona-Tarragona)
        (\p{Upper}\p{Lower}+-\p{Upper}\p{Lower}+) |
        # With & in the middle (H&M)
        (\p{Upper}\p{Lower}*&\p{Upper}\p{Lower}*) |
        # With ' in the middle (L'Oréal)
        (\p{Upper}\p{Lower}*'\p{Upper}\p{Lower}+) |
        # Road names (C-31)
        (\p{Upper}+-\d+) |
        # ADEGA-Coruña, CIG-Saúde, etc.
        (\p{Upper}{2,}-\p{Upper}\p{Lower}+) |
        # Xosé A.
        (\p{Upper}\p{Lower}+\s\p{Upper}\.) |
        # A. Dominguez
        (\p{Upper}\.\s\p{Upper}\p{Lower}+)
      )(?:[^\p{L}|\p{N}]|\z) # Ensure not part of a larger word
    /x)&.captures&.compact&.first || simple_proper_noun(text)
  end

  # Regular proper noun
  def simple_proper_noun(text)
    match = text.match(/\A(\p{Upper}\p{Lower}+)(?:[^\p{L}|\p{N}]|\z)/)&.captures&.compact&.first
    with_dot = "#{match}."
    # If the match is followed by a dot in the original text and is an acronym or abbreviation, is not a proper noun
    return if text.start_with?(with_dot) && (@acronyms.include?(with_dot) || @abbreviations.include?(with_dot))

    match
  end

  def each_substring_index(string, substring)
    pos = -1
    yield pos while (pos = string.index(substring, pos + 1))
  end

  def starts_with_wrapper?(text, i) = i > 0 && WRAPPER_START_CHARS.include?(text[i - 1])

  def ambiguous_position?(text, i)
    # Unambiguous proper nouns are not preceded by punctuation (dot is special case) followed by a separator (space usually).
    # If there is a wrapper char before the uppercase letter, then check the char before the wrapper.
    previous_two_positions = i - 2 - (starts_with_wrapper?(text, i) ? 1 : 0)
    return true if previous_two_positions.positive? && !text[previous_two_positions..].match?(/\A[^!?)]\p{Z}/)

    # If previous separator is dot + separator
    if previous_two_positions.positive? && text[previous_two_positions..].match?(/\A\.\p{Z}/)
      previous_separator_position = text[..previous_two_positions].rindex(/\p{Z}/)
      # If dot is the previous punctuation, but no previous word to check, then position is ambiguous
      return true unless previous_separator_position

      # If the previous word is an acronym or abbreviation the position is not ambiguous we can continue with regex detection.
      previous_word = text[(previous_separator_position + 1)..previous_two_positions]
      return true if !@acronyms.include?(previous_word) && !@abbreviations.include?(previous_word)
    end

    false
  end
end
