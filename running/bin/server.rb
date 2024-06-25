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

helpers do
  def tag_text(text, proper_nouns_processor)
    sentence = Sentence.new(DW, ACRONYMS, ABBREVIATIONS, ENCLITICS, proper_nouns_processor, text)
    sentence.contractions_processing
    sentence.idioms_processing # Must be processed before numerals
    sentence.numerals_processing
    sentence.enclitics_processing
    viterbi = Viterbi.new(DW)
    viterbi.run(sentence)
    viterbi
  rescue StandardError
    raise TaggingSentenceError.new("Error tagging sentence: #{text}")
  rescue Exception
    raise TaggingSentenceError.new("Critical error tagging sentence: #{text}")
  end

  def handle_tagger_request
    halt 400 if request.body.eof?

    texts = JSON.parse(request.body.read)
    halt 400 unless texts.is_a?(Array)

    proper_nouns_processor = PROPER_NOUNS_PROCESSOR&.with_trained(texts)
    stream do |out|
      out << '['
      texts.each_index do |i|
        out << yield(texts[i], proper_nouns_processor).to_json
        out << ',' unless texts.size == i + 1
      end
      out << ']'
    end
  rescue JSON::ParserError
    halt 400
  rescue ProperNounTrainingError => e
    body = { message: e.message, backtrace: e.backtrace }.to_json
    halt 500, { 'Content-Type' => 'application/json' }, body
  rescue TaggingSentenceError => e
    body = { message: e.message, backtrace: e.backtrace, text: e.message }.to_json
    halt 500, { 'Content-Type' => 'application/json' }, body
  end
end

set :default_content_type, :json

post '/tagger/alternatives' do
  handle_tagger_request do |text, proper_nouns_processor|
    tag_text(text, proper_nouns_processor).all_ways
  end
end

post '/tagger' do
  handle_tagger_request do |text, proper_nouns_processor|
    tag_text(text, proper_nouns_processor).best_way
  end
end
