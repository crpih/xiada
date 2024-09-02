require 'json'
require 'sinatra'
require_relative 'database_wrapper'
require_relative 'viterbi'
require_relative 'sentence'
require_relative 'proper_nouns'

DW = DatabaseWrapper.new("training/databases/#{ENV['XIADA_PROFILE']}/training_#{ENV['XIADA_DATABASE']}.db")
ACRONYMS = DW.get_acronyms.each_with_object({}) { |a, r| r[a] = 1 }.freeze
ABBREVIATIONS = DW.get_abbreviations.each_with_object({}) { |a, r| r[a] = 1 }.freeze
ENCLITICS = DW.get_enclitics_info.freeze

TOKEN_FIELDS = %i[token tag lemma hyperlemma start finish].freeze

PROPER_NOUNS_FILE = "training/lexicons/#{ENV['XIADA_PROFILE']}/lexicon_propios.txt"
PROPER_NOUNS_PROCESSOR =
  if File.exists?(PROPER_NOUNS_FILE)
    ProperNouns.new(
      ProperNouns.parse_literals_file(PROPER_NOUNS_FILE),
      CSV.read("training/lexicons/#{ENV['XIADA_PROFILE']}/proper_nouns_links.txt", col_sep: "\t").map(&:first),
      CSV.read("training/lexicons/#{ENV['XIADA_PROFILE']}/proper_nouns_candidate_tags.txt", col_sep: "\t").map(&:first)
    )
  else
    nil
  end

class ProperNounTrainingError < StandardError; end

class TaggingSentenceError < StandardError; end

def tag_text(text, proper_nouns_processor)
  sentence = Sentence.new(DW, ACRONYMS, ABBREVIATIONS, ENCLITICS, proper_nouns_processor, text)
  sentence.contractions_processing
  sentence.idioms_processing # Must be processed before numerals
  sentence.numerals_processing
  sentence.enclitics_processing
  viterbi = Viterbi.new(DW)
  viterbi.run(sentence)
  viterbi.best_way
rescue StandardError
  raise TaggingSentenceError.new("Error tagging sentence: #{text}")
rescue Exception
  raise TaggingSentenceError.new("Critical error tagging sentence: #{text}")
end
