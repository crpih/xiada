require 'active_support/core_ext/range/overlap'
require 'active_support/core_ext/range/overlap'
require 'active_support/core_ext/module/delegation'

class ProperNouns

  Literal = Struct.new(:text, :tag_lemmas)

  class Segment
    attr_reader :range, :text, :tag_lemmas
    delegate :begin, :end, :size, to: :range

    def initialize(range, text, tag_lemmas)
      @range = range
      @text = text
      @tag_lemmas = tag_lemmas
    end

    def overlaps?(other) = range.overlaps?(other.range)

    def merge(source_text, other)
      merged_range = [range.begin, other.begin].min...[range.end, other.end].max
      merge_text = source_text[merged_range]
      merged_tag_lemmas = if range.cover?(other.range)
                            tag_lemmas
                          elsif other.range.cover?(range)
                            other.tag_lemmas
                          else
                            [*tag_lemmas, *other.tag_lemmas].map(&:first).uniq.map { |t| [t, merge_text] }.sort
                          end
      Segment.new(merged_range, merge_text, merged_tag_lemmas)
    end

    def to_literal = Literal.new(text, tag_lemmas)

    def to_s = inspect

    def inspect = "<#{self.class} #{range.inspect} #{text.inspect} #{tag_lemmas.inspect}>"

    def ==(other)
      other.is_a?(Segment) && range == other.range && text == other.text && tag_lemmas == other.tag_lemmas
    end
  end

  def self.parse_literals_file(file_path)
    CSV.read(file_path, col_sep: "\t").to_a.group_by(&:first).map do |text, elements|
      Literal.new(text, elements.map { |_, tag, lemma| [tag, lemma] })
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
      Segment.new(range, text[range], literal.tag_lemmas)
    end
  end

  def standard_proper_nouns(text)
    # Candidate proper noun positions are uppercase letters that are not at the beginning of the text
    candidate_starts = text.each_char.each_with_index.filter_map { |c, i| i if c.match?(/\p{Upper}/) && !i.zero? }
    ranges = candidate_starts.filter_map do |i|
      # Special case: quoted uppercase word not at the beginning: nave "Soyuz" Bill Shepherd
      quotes_match_data = text[(i - 1)..].match(/\A["']([^\p{Z}|\p{P}]+)["'](:?\p{Z}|\p{P}|\z)/)
      next (i - 1)...(i + quotes_match_data[1].size + 1) if quotes_match_data && i >= 1

      # Special case: road names
      road_match_data = text[i..].match(/[A-Z]+-\d+/)
      next i...(i + road_match_data[0].size) if road_match_data

      # Check two previous characters before candidate uppercase letter
      # If the previous character is not a close punctuation and the one before is a space, it is a proper noun
      # Proper noun is captured until the next punctuation or space
      match_data = text[(i - 2)..].match(/\A[^!?.)]\p{Z}([^\p{Z}|\p{P}]+)(:?\p{Z}|\p{P}|\z)/)
      next if match_data.nil?

      i...(i + match_data[1].size) if match_data[1].size > 1
    end
    ranges.map { |r| Segment.new(r, text[r], @tags.map { |t| [t, text[r]] }.sort) }
  end
end
