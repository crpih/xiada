require 'sinatra'
require_relative 'database_wrapper'
require_relative 'xiada_tagger'

helpers do
  def handle_tagger_request
    halt 400 if request.body.eof?

    texts = JSON.parse(request.body.read)
    halt 400 unless texts.is_a?(Array)

    yield(texts).to_json

  rescue JSON::ParserError
    halt 400
  end
end

set :default_content_type, :json

# TODO: Read config from headers

TAGGER = XiadaTagger.new

post '/tagger/alternatives' do
  handle_tagger_request { |texts| TAGGER.tag_texts_alternatives(texts) }
end

post '/tagger' do
  handle_tagger_request { |texts| TAGGER.tag_texts(texts) }
end
