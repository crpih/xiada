# -*- coding: utf-8 -*-
require_relative "sentence"
require_relative "config"
require_relative "viterbi"

class XiadaTagger
  delegate :profile, :database, :seseo, :only_lexicon, :force_proper_nouns, to: :@tagger_config

  class Exception < StandardError
    attr_reader :text

    def initialize(text, cause)
      super("Error processing text: #{text}\nCaused by: #{cause.message}")
      @text = text
    end
  end

  def initialize(tagger_config)
    @tagger_config = tagger_config
    @acronyms = @tagger_config.dw.get_acronyms.each_with_object({}) { |a, r| r[a] = 1 }.freeze
    @abbreviations = @tagger_config.dw.get_abbreviations.each_with_object({}) { |a, r| r[a] = 1 }.freeze
    @enclitics = @tagger_config.dw.get_enclitics_info.freeze
  end

  def tag_texts(document_config, texts)
    trained_proper_nouns = @tagger_config.proper_nouns_processor&.with_trained(texts)
    texts.map { |t| t.empty? ? [] : tag_text(document_config, trained_proper_nouns, t).best_way }
  end

  def tag_texts_alternatives(document_config, texts)
    trained_proper_nouns = @tagger_config.proper_nouns_processor&.with_trained(texts)
    texts.map { |t| t.empty? ? [] : tag_text(document_config, trained_proper_nouns, t).all_ways }
  end

  def call(document_config, text) = tag_text(document_config, nil, text)

  private

  def tag_text(document_config, proper_nouns_processor, text)
    sentence = Sentence.new(
      tagger_config: @tagger_config,
      document_config:,
      acronyms: @acronyms,
      abbreviations: @abbreviations,
      enclitics: @enclitics,
      proper_nouns_processor:,
      text:
    )
    sentence.contractions_processing
    sentence.idioms_processing # Must be processed before numerals
    sentence.numerals_processing
    sentence.enclitics_processing
    viterbi = Viterbi.new(@tagger_config, document_config)
    viterbi.run(sentence)
    viterbi
  rescue StandardError => e
    puts "Error processing text: #{text}"
    puts e.message
    puts e.backtrace.join("\n")
    raise Exception.new(text, e)
  end
end

# main #
if __FILE__ == $0
  tagger = XiadaTagger.new(Config::Tagger.from_env)
  document_config = Config::Document.from_env

  ARGF.each do |line|
    line = line.strip
    next puts if line.empty?

    tagger.call(document_config, line).best_way.each { |t| p t }
  end
end
