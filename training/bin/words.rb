# -*- coding: utf-8 -*-
class Words
  attr_reader :corpus_size, :real_corpus_size, :frequencies, :probabilities,
              :tag_frequencies, :from_lexicon, :word_tag_lemma_count

  def initialize(empty_word)
    @empty_word = empty_word
    @lemmas = Hash.new # Now @lemmas include pairs [lemma,hiperlemma]
    @frequencies = Hash.new
    @tag_frequencies = Hash.new
    @word_frequencies = Hash.new
    @probabilities = Hash.new
    @from_lexicon = Hash.new
    @word_tag_lemma_count = Hash.new(0)
    @corpus_size = 0
    @real_corpus_size = 0
  end

  def add_word(word, tag, lemma, hiperlemma, from_lexicon, normative = false)
    hiperlemma = "" unless hiperlemma
    key = word + "&&&" + tag
    @corpus_size = @corpus_size + 1
    @real_corpus_size = @real_corpus_size + 1 unless word == @empty_word
    if @frequencies[key] == nil
      @frequencies[key] = 1
    else
      @frequencies[key] = @frequencies[key] + 1
    end

    if (@from_lexicon[key] == nil) || is_false(@from_lexicon[key])
      @from_lexicon[key] = from_lexicon
    end

    if @tag_frequencies[tag] == nil
      @tag_frequencies[tag] = 1
    else
      @tag_frequencies[tag] = @tag_frequencies[tag] + 1
    end
    if @word_frequencies[word] == nil
      @word_frequencies[word] = 1
    else
      @word_frequencies[word] = @word_frequencies[word] + 1
    end
    if @lemmas[key] == nil
      @lemmas[key] = Array.new
      @lemmas[key] << [lemma, hiperlemma]
    elsif not find(@lemmas[key], lemma)
      @lemmas[key] << [lemma, hiperlemma]
    end
    @word_tag_lemma_count[[word, tag, lemma, normative].freeze] += 1
  end

  def get_frequency(word, tag)
    key = word + "&&&" + tag
    if @frequencies[key] != nil
      return @frequencies[key]
    else
      return 0
    end
  end

  def get_from_lexicon(word, tag)
    key = word + "&&&" + tag
    if @from_lexicon[key] != nil
      return @from_lexicon[key]
    else
      return false
    end
  end

  def get_probability(word, tag)
    key = word + "&&&" + tag
    if @probabilities[key] != nil
      return @probabilities[key]
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
      return @word_frequencies[word]
    else
      return 0
    end
  end

  def get_normative(word, tag, lemma)
    @word_tag_lemma_count.key?([word, tag, lemma, true])
  end

  def calculate_probabilities
    @frequencies.each do |key, frequency|
      @probabilities[key] = Math.log(Float(frequency) /
                                     @tag_frequencies[get_tag_component(key)])
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

  def get_hiperlemma(lemma, tag)
    hiperlemmas = hiperlemmas_by_lemma_and_tag[[lemma, tag]]
    return nil unless hiperlemmas
    return nil if hiperlemmas.size > 1

    hiperlemmas.first
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

  def hiperlemmas_by_lemma_and_tag
    @hiperlemmas_by_lemma_and_tag ||= @lemmas.each_with_object({}) do |(key, lemmas), acc|
      _word, tag = key.split(/&&&/)
      lemmas.each do |lemma, hiperlemma|
        acc[[lemma, tag].freeze] ||= []
        acc[[lemma, tag]] << hiperlemma
      end
    end
  end
end
