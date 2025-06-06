require "active_support/core_ext/object/blank"

class Words
  attr_reader :corpus_size, :real_corpus_size, :frequencies, :probabilities,
              :tag_frequencies, :from_lexicon, :word_tag_lemma_count

  def initialize(empty_word)
    @empty_word = empty_word
    @corpus_size = 0
    @real_corpus_size = 0
    @frequencies = Hash.new(0)
    @tag_frequencies = Hash.new(0)
    @word_frequencies = Hash.new(0)
    @word_tag_lemma_count = Hash.new(0)
    @lemmas = Hash.new { |h, k| h[k] = [] }
    @probabilities = Hash.new
    @from_lexicon = Hash.new
  end

  def add_word(word, tag, lemma, hiperlemma, from_lexicon, normative = false)
    hiperlemma ||= ""
    key = "#{word}&&&#{tag}"

    @corpus_size = @corpus_size + 1
    @real_corpus_size = @real_corpus_size + 1 unless word == @empty_word
    @frequencies[key] += 1
    @tag_frequencies[tag] += 1
    @word_frequencies[word] += 1
    @word_tag_lemma_count[[word, tag, lemma, normative].freeze] += 1
    @from_lexicon[key] = from_lexicon if @from_lexicon[key].blank?

    lemma_pairs = @lemmas[key]
    lemma_hiperlemma = [lemma, hiperlemma].freeze
    lemma_pairs << lemma_hiperlemma unless lemma_pairs.include?(lemma_hiperlemma)
  end

  def emission_data
    frequencies.flat_map do |key, frequency|
      word, tag = key.split("&&&")
      lemmas = @lemmas.fetch(key, [])
      log_b = @probabilities.fetch(key, 0)
      from_lexicon = @from_lexicon.fetch(key, false)
      lemmas.map do |lemma, hiperlemma|
        [word, tag, lemma, hiperlemma, frequency, log_b, from_lexicon ? 1 : 0]
      end
    end
  end

  def get_normative(word, tag, lemma) = @word_tag_lemma_count.key?([word, tag, lemma, true])

  def calculate_probabilities
    @frequencies.each do |key, frequency|
      _word, tag = key.split("&&&")
      @probabilities[key] = Math.log(Float(frequency) / @tag_frequencies[tag])
    end
  end

  def get_hiperlemma(lemma, tag)
    hiperlemmas = hiperlemmas_by_lemma_and_tag[[lemma, tag]]
    return nil unless hiperlemmas
    return nil if hiperlemmas.size > 1

    hiperlemmas.first
  end

  private

  def hiperlemmas_by_lemma_and_tag
    @hiperlemmas_by_lemma_and_tag ||= @lemmas.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(key, lemmas), acc|
      _word, tag = key.split("&&&")
      lemmas.each { |l, hl| acc[[l, tag]] << hl }
    end
  end
end
