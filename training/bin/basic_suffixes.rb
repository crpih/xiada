class BasicSuffixes

  attr_reader :frequencies, :probabilities, :max_suffix_length, :max_occurrences

  def initialize(empty_word, max_suffix_length, max_occurrences, words, tags_info)
    # By now suffixes are stored always in memmory
    @words = words
    @empty_word = empty_word
    @max_suffix_length = max_suffix_length
    @max_occurrences = max_occurrences
    @frequencies = Array.new(@max_suffix_length) { Hash.new(0) }
    @tags_frequencies = Array.new(@max_suffix_length) { Hash.new(0) }
    @probabilities = Array.new(@max_suffix_length) { Hash.new }
    @forbidden_tag_prefixes = [*tags_info["proper_noun"], *tags_info["scientific"], *tags_info["closed"]]
  end

  def calculate_frequencies
    @words.frequencies
          .filter { |k, f| f <= @max_occurrences && !k.start_with?(@empty_word) }
          .map { |k, f| [*k.split(/&&&/), f] }
          .reject { |_, tag, _| proper_noun_or_scientific_or_closed?(tag) }
          .each { |word, tag, frequency| add_word(word, tag, frequency) }
  end

  def calculate_probabilities
    @frequencies.each_index do |length_index|
      @frequencies[length_index].each do |key, frequency|
        _suffix, tag = key.split("&&&")
        @probabilities[length_index][key] = Math.log(Float(frequency)/@tags_frequencies[length_index][tag])
      end
    end
  end

  def data
    @frequencies.each_index.flat_map do |length_index|
      @frequencies[length_index].map do |key, frequency|
        suffix, tag = key.split("&&&")
        [suffix, length_index + 1, tag, frequency, @probabilities[length_index][key]]
      end
    end
  end

  private

  def add_word(word, tag, frequency)
    return if proper_noun_or_scientific_or_closed?(tag)

    max_length = [@max_suffix_length, word.length - 1].min
    (1..max_length).each do |suffix_length|
      suffix = word[-suffix_length..]
      break if suffix.include?(" ")

      suffix_length_index = suffix.length - 1
      key = "#{suffix}&&&#{tag}"

      @frequencies[suffix_length_index][key] += frequency
      @tags_frequencies[suffix_length_index][tag] += frequency
    end
  end

  # Proper nouns are not good candidates for suffixes: "Ministro de Facenda"
  def proper_noun_or_scientific_or_closed?(tag) = @forbidden_tag_prefixes.any? { |c| tag.start_with?(c) }
end
