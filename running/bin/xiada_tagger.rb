# -*- coding: utf-8 -*-
require "optparse"
require "rexml"
require "csv"
require_relative "sentence.rb"
require_relative "viterbi.rb"
require_relative "database_wrapper.rb"
require_relative "./proper_nouns"

class XiadaTagger
  def initialize
    raise "Missing XIADA_PROFILE environment variable" unless ENV['XIADA_PROFILE']
    raise "Missing XIADA_DATABASE environment variable" unless ENV['XIADA_DATABASE']

    @dw = DatabaseWrapper.new("training/databases/#{ENV['XIADA_PROFILE']}/training_#{ENV['XIADA_DATABASE']}.db")
    @acronyms = @dw.get_acronyms.each_with_object({}) { |a, r| r[a] = 1 }.freeze
    @abbreviations = @dw.get_abbreviations.each_with_object({}) { |a, r| r[a] = 1 }.freeze
    @enclitics = @dw.get_enclitics_info.freeze
    proper_nouns_file = "training/lexicons/#{ENV['XIADA_PROFILE']}/lexicon_propios.txt"
    @proper_noun_processor =
      if File.exists?(proper_nouns_file)
        ProperNouns.new(
          ProperNouns.parse_literals_file(proper_nouns_file),
          CSV.read("training/lexicons/#{ENV['XIADA_PROFILE']}/proper_nouns_links.txt", col_sep: "\t").map(&:first),
          CSV.read("training/lexicons/#{ENV['XIADA_PROFILE']}/proper_nouns_candidate_tags.txt", col_sep: "\t").map(&:first)
        )
      else
        nil
      end
  end

  def train_proper_nouns!(texts)
    @proper_noun_processor = @proper_noun_processor.with_trained(texts)
  end

  def call(text)
    sentence = Sentence.new(@dw, @acronyms, @abbreviations, @enclitics, @proper_noun_processor, text)
    sentence.contractions_processing
    sentence.idioms_processing # Must be processed before numerals
    sentence.numerals_processing
    sentence.enclitics_processing
    viterbi = Viterbi.new(@dw)
    viterbi.run(sentence)
    viterbi
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
