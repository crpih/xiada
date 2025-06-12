require "json"
require "yaml"
require "benchmark"
require "sinatra"
require_relative "database_wrapper"
require_relative "xiada_tagger"

# Preload all taggers
TAGGERS = YAML.load_file("#{__dir__}/../../profiles.yml", symbolize_names: true).map do |params|
  params => { profile:, database:, only_lexicon:, force_proper_nouns: }
  tagger = nil
  elapsed = Benchmark.measure do
    tagger_config = Config::Tagger.new(profile:, database:, only_lexicon:, force_proper_nouns:)
    tagger = XiadaTagger.new(tagger_config)
    tagger_config.dw.close_database # Close the database before forking
  end
  puts "Loaded tagger with config #{params.inspect} in #{elapsed.real.round(2)} seconds"
  tagger
end

helpers do
  def handle_tagger_request
    halt 400 if request.body.eof?

    texts = JSON.parse(request.body.read)
    halt 400 unless texts.is_a?(Array)

    document_config = Config::Document.new(seseo: params['seseo'] == 'true', gheada: params['gheada'] == 'true')
    tagger = get_tagger

    # Fork to prevent memory leaks in long-running processes
    rd, wr = IO.pipe
    fork do
      rd.close
      wr.write yield(tagger, document_config, texts).to_json
      wr.close
    rescue => e
      puts "Exception in child process: #{e.class} - #{e.message}"
      puts e.backtrace
    end
    wr.close
    result = rd.read
    rd.close
    Process.wait

    result

  rescue JSON::ParserError
    halt 400
  rescue StandardError => e
    halt 500, { error: e.message }.to_json
  end

  def get_tagger
    # Read from ENV as fallback for compatibility
    profile = params['profile'] || ENV['XIADA_PROFILE']
    database = params['database'] || ENV['XIADA_DATABASE']
    only_lexicon = params['only_lexicon'] == 'true' || ENV['XIADA_ONLY_LEXICON'] == 'true'
    force_proper_nouns = params['force_proper_nouns'] == 'true' || ENV['XIADA_FORCE_PROPER_NOUNS'] == 'true'

    tagger = TAGGERS.find { |t| t.profile == profile && t.database == database && t.only_lexicon == only_lexicon && t.force_proper_nouns == force_proper_nouns }
    halt 400, { error: "Invalid tagger configuration" }.to_json unless tagger

    tagger
  rescue StandardError => e
    halt 500, { error: e.message }.to_json
  end
end

set :default_content_type, :json

post '/tagger/alternatives' do
  handle_tagger_request { |tagger, document_config, texts| tagger.tag_texts_alternatives(document_config, texts) }
end

post '/tagger' do
  handle_tagger_request { |tagger, document_config, texts| tagger.tag_texts(document_config, texts) }
end
