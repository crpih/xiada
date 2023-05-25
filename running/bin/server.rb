require 'json'
require 'sinatra'
require_relative 'database_wrapper'
require_relative 'viterbi'
require_relative 'sentence'

DW = DatabaseWrapper.new("training/databases/#{ENV['XIADA_PROFILE']}/training_#{ENV['XIADA_DATABASE']}.db")
ACRONYMS = DW.get_acronyms.each_with_object({}) { |a, r| r[a] = 1 }.freeze
ABBREVIATIONS = DW.get_abbreviations.each_with_object({}) { |a, r| r[a] = 1 }.freeze
ENCLITICS = DW.get_enclitics_info.freeze

TOKEN_FIELDS = %i[token tag lemma hyperlemma start finish].freeze

class ProperNounTrainingError < StandardError; end
class TaggingSentenceError < StandardError; end

helpers do
  def train_proper_nouns(texts)
    texts.each_with_object({}) do |text, trained_proper_nouns|
      sentence = Sentence.new(DW, ACRONYMS, ABBREVIATIONS, ENCLITICS, false)
      sentence.add_chunk(text, nil, nil, nil, nil)
      sentence.finish
      sentence.contractions_processing
      sentence.add_proper_nouns(trained_proper_nouns)
    end
  rescue StandardError
    raise ProperNounTrainingError
  end

  def tag_text(text, trained_proper_nouns)
    sentence = Sentence.new(DW, ACRONYMS, ABBREVIATIONS, ENCLITICS, true)
    sentence.add_chunk(text, nil, nil, nil, nil)
    sentence.finish
    sentence.contractions_processing
    sentence.idioms_processing # Must be processed before numerals
    sentence.proper_nouns_processing(trained_proper_nouns, false)
    sentence.numerals_processing
    sentence.enclitics_processing
    viterbi = Viterbi.new(DW)
    viterbi.run(sentence)
    viterbi.get_best_way
           .split("\n")
           .map { |t| t.split("\t") }
           .map do |token, tag, lemma, hyperlemma, start, finish|
      { token: token, tag: tag, lemma: lemma, hyperlemma: hyperlemma, start: start.to_i, finish: finish.to_i }
    end
  rescue StandardError
    raise TaggingSentenceError.new("Error tagging sentence: #{text}")
  end
end

set :default_content_type, :json

post '/tagger' do
  halt 400 if request.body.eof?

  texts = JSON.parse(request.body.read)
  halt 400 unless texts.is_a?(Array)

  trained_proper_nouns = train_proper_nouns(texts)
  stream do |out|
    out << '['
    texts.each_index do |i|
      out << tag_text(texts[i], trained_proper_nouns).to_json
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
