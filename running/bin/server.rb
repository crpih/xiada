require 'sinatra'
require_relative 'database_wrapper'
require_relative 'tag_text'

set :default_content_type, :json

post '/tagger' do
  halt 400 if request.body.eof?

  texts = JSON.parse(request.body.read)
  halt 400 unless texts.is_a?(Array)

  proper_nouns_processor = PROPER_NOUNS_PROCESSOR&.with_trained(texts)
  stream do |out|
    out << '['
    texts.each_index do |i|
      out << tag_text(texts[i], proper_nouns_processor).to_json
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
