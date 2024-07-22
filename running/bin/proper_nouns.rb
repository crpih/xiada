require 'csv'
require 'active_support/core_ext/range/overlap'
require 'active_support/core_ext/range/overlap'
require 'active_support/core_ext/module/delegation'

class ProperNouns

  Literal = Struct.new(:text, :tag_lemmas, :lexicon)

  class Segment
    attr_reader :range, :text, :tag_lemmas
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
      merged_range = [range.begin, other.begin].min...[range.end, other.end].max
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
        tag_lemmas.map { |t, _| [t, merge_text] }
      elsif other.lexicon? && other.range.cover?(range)
        other.tag_lemmas
      else # other.lexicon?
        other.tag_lemmas.map { |t, _| [t, merge_text] }
      end
    end

    def merge_tags_tie(other, merge_text)
      if range.cover?(other.range)
        tag_lemmas
      elsif other.range.cover?(range)
        other.tag_lemmas
      else
        [*tag_lemmas, *other.tag_lemmas].map(&:first).uniq.sort.map { |t| [t, merge_text] }
      end
    end
  end

  def self.parse_literals_file(file_path)
    CSV.read(file_path, col_sep: "\t").to_a.group_by(&:first).map do |text, elements|
      Literal.new(text, elements.map { |_, tag, lemma| [tag, lemma] }, true)
    end
  end

  def initialize(literal_proper_nouns, joiners, tags)
    @literal_proper_nouns = literal_proper_nouns
    @joiners = joiners
    @joiners_regex = /\A\p{Z}\z|\A\p{Z}?(?:#{joiners.map { |joiner| Regexp.escape(joiner) }.join('|')})\p{Z}?\z/
    @tags = tags
  end

  def with_trained(texts)
    trained_proper_nouns = texts.flat_map { |t| call(t).filter { |segment| segment.is_a?(Literal) } }
    self.class.new(@literal_proper_nouns + trained_proper_nouns, @joiners, @tags)
  end

  def call(text)
    literal_segments = literal_proper_nouns(text, @literal_proper_nouns)
    standard_segments = standard_proper_nouns(text)
    candidate_segments = [*literal_segments, *standard_segments]
    noun_ranges = join_proper_nouns(text, candidate_segments)
    split_text_by_proper_nouns(text, noun_ranges)
  end

  private

  def join_proper_nouns(text, segments)
    current_segment, *rest = segments.sort_by { |r| [r.begin, r.size] }
    return [] if current_segment.nil?

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
    return [text] if segments.empty?

    last_pos, all_ranges = segments.inject([0, []]) do |(i, result), segment|
      result << text[i...segment.begin] if i < segment.begin
      result << segment.to_literal
      [segment.end, result]
    end
    all_ranges << text[last_pos...text.size] if last_pos < text.size
    all_ranges
  end

  def literal_proper_nouns(text, literals)
    literals.filter_map do |literal|
      start_index = text.index(literal.text)
      next if start_index.nil?

      range = start_index...(start_index + literal.text.size)
      Segment.new(range, text[range], literal.tag_lemmas, literal.lexicon)
    end
  end

  def standard_proper_nouns(text)
    # Candidate proper noun positions are uppercase letters that are not at the beginning of the text
    candidate_starts = text.each_char.each_with_index.filter_map { |c, i| i if c.match?(/\p{Upper}/) && !i.zero? }
    ranges = candidate_starts.filter_map do |i|
      wrapped_proper_noun_range(i, text, '"', '"', true) ||
        wrapped_proper_noun_range(i, text, '\'', '\'', true) ||
        wrapped_proper_noun_range(i, text, '(', ')', false) ||
        unambiguous_proper_noun_range(i, text)
    end
    ranges.map { |r| Segment.new(r, text[r], @tags.map { |t| [t, text[r]] }.sort, false) }
  end

  def unambiguous_proper_noun_range(i, text)
    return unless text[(i - 2)..].match?(/\A[^!?.)]\p{Z}/)

    match_data = match_proper_noun(text[i..])
    return unless match_data && match_data[1].size > 1

    i...(i + match_data[1].size)
  end

  def wrapped_proper_noun_range(i, text, start_char, end_char, include_wrappers)
    return if i == 1 || text[i - 1] != start_char

    match_data = match_proper_noun(text[i..])
    return unless match_data && match_data[1].size > 1 && text[i + match_data[1].size] == end_char

    offset = include_wrappers ? 1 : 0
    (i - offset)...(i + match_data[1].size + offset)
  end

  def match_proper_noun(text)
    text.match(/
      \A(
        # Camel case (YouTube)
        \p{Upper}\p{Lower}+(?:\p{Upper}\p{Lower}+)+ |
        # Separated by one hyphen (Barcelona-Tarragona)
        \p{Upper}\p{Lower}+-\p{Upper}\p{Lower}+ |
        # With & in the middle (H&M)
        \p{Upper}\p{Lower}*&\p{Upper}\p{Lower}* |
        # With ' in the middle (L'Oréal)
        \p{Upper}\p{Lower}*'\p{Upper}\p{Lower}+ |
        # Road names (C-31)
        \p{Upper}+-\d+ |
        # Regular proper noun
        \p{Upper}\p{Lower}+
      )
    /x)
  end
end
