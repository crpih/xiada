# -*- coding: utf-8 -*-
require "optparse"
require "rexml"
require "csv"
require_relative "sentence.rb"
require_relative "viterbi.rb"
require_relative "database_wrapper.rb"
require_relative "./proper_nouns"

class XiadaTagger

  class Exception < StandardError
    attr_reader :text

    def initialize(text, cause)
      super("Error processing text: #{text}\nCaused by: #{cause.message}")
      @text = text
    end
  end

  def initialize
    raise "Missing XIADA_PROFILE environment variable" unless ENV['XIADA_PROFILE']
    raise "Missing XIADA_DATABASE environment variable" unless ENV['XIADA_DATABASE']

    @dw = DatabaseWrapper.new("training/databases/#{ENV['XIADA_PROFILE']}/training_#{ENV['XIADA_DATABASE']}.db")
    @acronyms = @dw.get_acronyms.each_with_object({}) { |a, r| r[a] = 1 }.freeze
    @abbreviations = @dw.get_abbreviations.each_with_object({}) { |a, r| r[a] = 1 }.freeze
    @enclitics = @dw.get_enclitics_info.freeze
    proper_nouns_file = "training/lexicons/#{ENV['XIADA_PROFILE']}/lexicon_propios.txt"
    @proper_noun_processor =
      if File.exist?(proper_nouns_file)
        ProperNouns.new(
          ProperNouns.parse_all_lexicon_words("training/lexicons/#{ENV['XIADA_PROFILE']}/lexicon_principal.txt"),
          ProperNouns.parse_literals_file(proper_nouns_file),
          CSV.read("training/lexicons/#{ENV['XIADA_PROFILE']}/proper_nouns_links.txt", col_sep: "\t").map(&:first),
          CSV.read("training/lexicons/#{ENV['XIADA_PROFILE']}/proper_nouns_candidate_tags.txt", col_sep: "\t").map(&:first),
          force_proper_nouns: ENV['XIADA_FORCE_PROPER_NOUNS'] == 'true'
        )
      else
        nil
      end
  end

  def tag_texts(texts)
    trained_proper_nouns = @proper_noun_processor&.with_trained(texts)
    texts.map { |t| t.empty? ? [] : tag_text(t, trained_proper_nouns).best_way }
  end

  def tag_texts_alternatives(texts)
    trained_proper_nouns = @proper_noun_processor&.with_trained(texts)
    texts.map { |t| t.empty? ? [] : tag_text(t, trained_proper_nouns).all_ways }
  end

  def call(text) = tag_text(text, @proper_noun_processor)

  private

  def tag_text(text, proper_noun_processor)
    sentence = Sentence.new(@dw, @acronyms, @abbreviations, @enclitics, proper_noun_processor, text)
    sentence.contractions_processing
    sentence.idioms_processing # Must be processed before numerals
    sentence.numerals_processing
    sentence.enclitics_processing
    viterbi = Viterbi.new(@dw)
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
  tagger = XiadaTagger.new

  ARGF.each do |line|
    line = line.strip
    next puts if line.empty?

    tagger.call(line).best_way.each { |t| p t }
  end
end
