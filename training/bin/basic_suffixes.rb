# -*- coding: utf-8 -*-
class BasicSuffixes

  attr_reader :frequencies, :max_suffix_length, :max_occurrences

  def initialize(empty_word, max_suffix_length, max_occurrences, words, tags_info)
    # By now suffixes are stored always in memmory
    @words = words
    @empty_word = empty_word
    @max_suffix_length = max_suffix_length
    @max_occurrences = max_occurrences
    @frequencies = Array.new(@max_suffix_length) {Hash.new}
    @probabilities = Array.new(@max_suffix_length) {Hash.new}
    @tags_freqs = Array.new(@max_suffix_length) {Hash.new}
    @tags_info = tags_info
    # STDERR.puts "tags_info: #{@tags_info}"
    @proper_noun_or_scientific_or_closed_regexp = proper_noun_or_scientific_or_closed_regexp
  end

  def calculate_frequencies
    @words.frequencies.each do |key, freq|
      word,tag = key.split(/&&&/)
      # STDERR.puts "word,tag:#{word},#{tag}"
      # STDERR.puts "word: #{word}, @empty_word: #{@empty_word}, frequency: #{@words.get_frequency(word, tag)}, max_ocurrences:#{@max_occurrences}"
      if (word != @empty_word) and (@words.get_frequency(word,tag) <= @max_occurrences)
        add_word(word, tag, freq)
      end
    end
  end

  def calculate_probabilities
    @frequencies.each_index do |length_index|
      @frequencies[length_index].each do |key, frequency|
        tag = get_tag_component(key)
        @probabilities[length_index][key] = Math.log(Float(frequency)/@tags_freqs[length_index][tag])
      end
    end
  end

  def get_suffix_component(key)
    suffix,tag = key.split(/&&&/)
    return suffix
  end

  def get_tag_component(key)
    suffix,tag = key.split(/&&&/)
    return tag
  end

  def get_frequency(length, suffix, tag)
    key = suffix + "&&&" + tag
    return @frequencies[length-1][key]
  end

  def get_probability(length, suffix, tag)
    key = suffix + "&&&" + tag
    return @probabilities[length-1][key]
  end

  private

  def add_word(word, tag, freq)
    # STDERR.puts "add_word(word, tag, freq): (#{word},#{tag},#{freq}) proper_noun_or_scientific_or_closed?:#{proper_noun_or_scientific_or_closed?(tag)}"
    unless proper_noun_or_scientific_or_closed?(tag)
      max_length = @max_suffix_length
      max_length = word.length-1 if (word.length-1) < @max_suffix_length
      (1..max_length).each do |suffix_length|
        suffix = word[word.length-suffix_length,suffix_length]
        break if suffix=~/ /
        add_suffix(suffix, tag, freq)
      end
    end
  end

  def add_suffix(suffix, tag, freq)
    suffix_length_index = suffix.length-1
    key = suffix+"&&&"+tag
    if @frequencies[suffix_length_index][key] == nil
      @frequencies[suffix_length_index][key] = freq
    else
      @frequencies[suffix_length_index][key] = @frequencies[suffix_length_index][key] + freq
    end

    if @tags_freqs[suffix_length_index][tag] == nil
      @tags_freqs[suffix_length_index][tag] = freq
    else
      @tags_freqs[suffix_length_index][tag] = @tags_freqs[suffix_length_index][tag] + freq
    end
  end

  # Proper nouns are not good candidates for suffixes: "Ministro de Facenda"
  def proper_noun_or_scientific_or_closed?(tag)
    # STDERR.puts "tag:#{tag}, @proper_noun_or_scientific_or_closed_regexp:#{@proper_noun_or_scientific_or_closed_regexp}"
    result = tag=~/#{@proper_noun_or_scientific_or_closed_regexp}/
    return result
  end

  def proper_noun_or_scientific_or_closed_regexp
    regexp = nil
    @tags_info["proper_noun"].each do |category|
      if regexp == nil
        regexp = "^#{category}"
      else
        regexp << "|^" << category
      end
    end
    if @tags_info["scientific"]
      @tags_info["scientific"].each do |category|
        if regexp == nil
          regexp = "^#{category}"
        else
          regexp << "|^" << category
        end
      end
    end
    @tags_info["closed"].each do |category|
      if regexp == nil
        regexp = "^#{category}"
      else
        regexp << "|^" << category
      end
    end
    return regexp
  end
end
