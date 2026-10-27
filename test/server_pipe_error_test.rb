require_relative './test_helper'
require 'rack/mock'
require 'yaml'

YAML.stub(:load_file, []) { require_relative '../running/bin/server' }

class ServerPipeErrorTest < Minitest::Test
  Tagger = Struct.new(:profile, :database, :only_lexicon, :force_proper_nouns) do
    def tag_texts(_config, texts)
      texts.map { |text| { 'text' => text, 'pid' => Process.pid } }
    end

    alias_method :tag_texts_alternatives, :tag_texts
  end

  def setup
    TAGGERS.replace([Tagger.new('test', 'test', false, false)])
  end

  def teardown
    TAGGERS.clear
  end

  class EmptyResultTagger < Tagger
    def tag_texts(_config, texts)
      texts.map { [] }
    end

    alias_method :tag_texts_alternatives, :tag_texts
  end

  def test_successful_response_shape_is_preserved
    TAGGERS.replace([EmptyResultTagger.new('test', 'test', false, false)])
    ['/tagger', '/tagger/alternatives'].each do |path|
      response = Rack::MockRequest.new(Sinatra::Application).post(
        "#{path}?profile=test&database=test", 'CONTENT_TYPE' => 'application/json', input: '["sentence"]'
      )
      assert_equal 200, response.status
      assert_equal [[]], JSON.parse(response.body)
    end
  end

  def test_both_endpoints_process_the_request_in_the_puma_worker
    ['/tagger', '/tagger/alternatives'].each do |path|
      response = Rack::MockRequest.new(Sinatra::Application).post(
        "#{path}?profile=test&database=test", 'CONTENT_TYPE' => 'application/json', input: '["sentence"]'
      )
      assert_equal 200, response.status
      assert_equal [{ 'text' => 'sentence', 'pid' => Process.pid }], JSON.parse(response.body)
    end
  end
end
