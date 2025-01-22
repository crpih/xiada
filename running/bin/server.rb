require 'sinatra'
require_relative 'database_wrapper'
require_relative 'xiada_tagger'

helpers do
  def handle_tagger_request
    halt 400 if request.body.eof?

    texts = JSON.parse(request.body.read)
    halt 400 unless texts.is_a?(Array)

    tagger = XiadaTagger.new
    tagger.train_proper_nouns!(texts)

    texts.map do |text|
      yield(tagger.call(text))
    rescue StandardError => e
      $stderr.write("#{e.message}\n#{e.backtrace.join("\n")}\n\n")
      body = { text: text, message: e.message, backtrace: e.backtrace }.to_json
      halt 500, { 'Content-Type' => 'application/json' }, body
    end.to_json

  rescue JSON::ParserError
    halt 400
  end
end

set :default_content_type, :json

post '/tagger/alternatives' do
  handle_tagger_request { |viterbi| viterbi.all_ways }
end

post '/tagger' do
  handle_tagger_request { |viterbi| viterbi.best_way }
end
