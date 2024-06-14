require 'active_support/core_ext/range/overlap'

class ProperNouns

  def initialize(lexicon_proper_nouns, trained_proper_nouns, joiners)
    @literal_proper_nouns = lexicon_proper_nouns + trained_proper_nouns
    @joiners_regex = /\A\p{Z}?(?:#{joiners.map { |joiner| Regexp.escape(joiner) }.join('|')}\p{Z})?\z/
  end

  def call(text)
    literal_ranges = literal_proper_nouns(text, @literal_proper_nouns)
    standard_ranges = standard_proper_nouns(text)
    candidate_ranges = [*literal_ranges, *standard_ranges].sort_by(&:begin)
    join_proper_nouns(text, candidate_ranges)
  end

  private

  def literal_proper_nouns(text, proper_nouns)
    proper_nouns.filter_map do |proper_noun|
      start_index = text.index(proper_noun)
      next if start_index.nil?

      start_index...(start_index + proper_noun.size)
    end
  end

  def join_proper_nouns(text, noun_ranges)
    result = noun_ranges.each_with_index.filter_map do |current, i|
      previous = i.zero? ? nil : noun_ranges[i - 1]
      following = noun_ranges[i + 1]
      # Skip current range if it is included in the previous range
      next if previous && previous.begin <= current.begin && previous.end >= current.end
      # Return current range if is the last one
      next current if following.nil?
      # Return current range if it includes the following range
      next current if current.begin <= following.begin && current.end >= following.end
      # Skip current range if it is included in the following range
      next if current.begin >= following.begin && current.end <= following.end

      # Concatenate ranges if they are adjacent or separated by a joiner
      current.begin...following.end if current.end == following.begin || text[current.end...following.begin].match?(@joiners_regex)
    end

    # Continue joining proper nouns until no more can be joined
    result.size == noun_ranges.size ? result : join_proper_nouns(text, result)
  end

  def standard_proper_nouns(text)
    candidate_starts = text.each_char.each_with_index.filter_map { |c, i| i if c.match?(/\p{Upper}/) && !i.zero? }
    candidate_starts.map do |i|
      match_data = text[i..].match(/([^\p{Z}|\p{P}]+)(:?\p{Z}|\p{P}|\z)/)
      next if match_data.nil?

      i...(i + match_data[1].size) if match_data[1].size > 1
    end
  end
end
