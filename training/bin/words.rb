# -*- coding: utf-8 -*-
require "gdbm"

class Words
  attr_reader :corpus_size, :real_corpus_size, :frequencies, :probabilities,
              :tag_frequencies, :from_lexicon, :word_tag_lemma_count

  def initialize(empty_word, memmory)
    @empty_word = empty_word
    @memmory = memmory
    @lemmas = Hash.new # Now @lemmas include pairs [lemma,hiperlemma]
    if @memmory
      @frequencies = Hash.new
      @tag_frequencies = Hash.new
      @word_frequencies = Hash.new
      @probabilities = Hash.new
      @from_lexicon = Hash.new
      @word_tag_lemma_count = Hash.new(0)
    else
      @frequencies = GDBM.new("frequencies.data", 0666, GDBM::NEWDB)
      @tag_frequencies = GDBM.new("tag_frequencies.data", 0666, GDBM::NEWDB)
      @word_frequencies = GDBM.new("word_frequencies.data", 0666, GDBM::NEWDB)
      @probabilities = GDBM.new("probabilities.data", 0666, GDBM::NEWDB)
      @from_lexicon = GDBM.new("from_lexicon.data", 0666, GDBM::NEWDB)
    end
    @corpus_size = 0
    @real_corpus_size = 0
  end

  def add_word(word, tag, lemma, hiperlemma, from_lexicon)
    hiperlemma = "" unless hiperlemma
    key = word + "&&&" + tag
    @corpus_size = @corpus_size + 1
    @real_corpus_size = @real_corpus_size + 1 unless word == @empty_word
    if @frequencies[key] == nil
      @frequencies[key] = 1 if @memmory
      @frequencies[key] = "1" unless @memmory
    else
      @frequencies[key] = @frequencies[key] + 1 if @memmory
      @frequencies[key] = "#{@frequencies[key].to_i + 1}" unless @memmory
    end

    if (@from_lexicon[key] == nil) || is_false(@from_lexicon[key])
      @from_lexicon[key] = from_lexicon if @memmory
      @from_lexicon[key] = "#{from_lexicon}" unless @memmory
    end

    if @tag_frequencies[tag] == nil
      @tag_frequencies[tag] = 1 if @memmory
      @tag_frequencies[tag] = "1" unless @memmory
    else
      @tag_frequencies[tag] = @tag_frequencies[tag] + 1 if @memmory
      @tag_frequencies[tag] = "#{@tag_frequencies[tag].to_i + 1}" unless @memmory
    end
    if @word_frequencies[word] == nil
      @word_frequencies[word] = 1 if @memmory
      @word_frequencies[word] = "1" unless @memmory
    else
      @word_frequencies[word] = @word_frequencies[word] + 1 if @memmory
      @word_frequencies[word] = "#{@word_frequencies[word].to_i + 1}" unless @memmory
    end
    if @lemmas[key] == nil
      @lemmas[key] = Array.new
      @lemmas[key] << [lemma, hiperlemma]
    elsif not find(@lemmas[key], lemma)
      @lemmas[key] << [lemma, hiperlemma]
    end
    @word_tag_lemma_count[[word, tag, lemma]] += 1
  end

  def get_frequency(word, tag)
    key = word + "&&&" + tag
    if @frequencies[key] != nil
      return @frequencies[key] if @memmory
      return @frequencies[key].to_i unless @memmory
    else
      return 0
    end
  end

  def get_from_lexicon(word, tag)
    key = word + "&&&" + tag
    if @from_lexicon[key] != nil
      return @from_lexicon[key] if @memmory
      return string_to_boolean(@from_lexicon[key]) unless @memmory
    else
      return false
    end
  end

  def get_probability(word, tag)
    key = word + "&&&" + tag
    if @probabilities[key] != nil
      return @probabilities[key] if @memmory
      return @probabilities[key].to_f unless @memmory
    else
      return 0
    end
  end

  def get_lemmas(word, tag)
    key = word + "&&&" + tag
    if @lemmas[key] != nil
      return @lemmas[key]
    else
      return nil
    end
  end

  def get_word_frequency(word)
    if @word_frequencies[word] != nil
      return @word_frequencies[word] if @memmory
      return @word_frequencies[word].to_i unless @memmory
    else
      return 0
    end
  end

  def calculate_probabilities
    if @memmory
      @frequencies.each do |key, frequency|
        @probabilities[key] = Math.log(Float(frequency) /
                                       @tag_frequencies[get_tag_component(key)])
      end
    else
      @frequencies.each do |key, frequency|
        @probabilities[key] = "#{Math.log(Float(frequency.to_i) /
                                          @tag_frequencies[get_tag_component(key)].to_i)}"
      end
    end
  end

  def get_word_component(key)
    word, tag = key.split(/&&&/)
    return(word)
  end

  def get_tag_component(key)
    word, tag = key.split(/&&&/)
    return(tag)
  end

  def show_contents
    @frequencies.keys.each do |key|
      puts "key: #{key}, frequency:#{@frequencies[key]}, probability:#{@probabilities[key]}"
    end
  end

  private

  def find(pair_array, key)
    pair_array.find { |a, _| a == key }
  end

  def is_true(element)
    return true if element or element == "true"
    return false
  end

  def is_false(element)
    return true if !element or element == "false"
    return false
  end

  def string_to_boolean(element)
    return true if element == "true"
    return false
  end
end
