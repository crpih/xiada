require_relative './test_helper'
require 'rack/mock'
require 'yaml'

YAML.stub(:load_file, []) { require_relative '../running/bin/server' }

class ServerGcRequestsTest < Minitest::Test
  Tagger = Struct.new(:profile, :database, :only_lexicon, :force_proper_nouns) do
    def tag_texts(_config, texts)
      texts
    end

    alias_method :tag_texts_alternatives, :tag_texts
  end

  def setup
    TAGGERS.replace([Tagger.new('test', 'test', false, false)])
  end

  def teardown
    TAGGERS.clear
  end

  def test_full_gc_runs_after_successful_requests_to_both_endpoints
    ['/tagger', '/tagger/alternatives'].each do |path|
      collections = []
      GC.stub(:start, ->(**options) { collections << options }) do
        response = post(path, '["sentence"]')

        assert_equal 200, response.status
        assert_equal '["sentence"]', response.body
      end
      assert_equal [{ full_mark: true, immediate_sweep: true }], collections
    end
  end

  def test_full_gc_runs_after_error_response_without_changing_it
    collections = []
    GC.stub(:start, ->(**options) { collections << options }) do
      response = post('/tagger', 'not json')

      assert_equal 400, response.status
      assert_equal '', response.body
    end
    assert_equal [{ full_mark: true, immediate_sweep: true }], collections
  end

  private

  def post(path, body)
    Rack::MockRequest.new(Sinatra::Application).post(
      "#{path}?profile=test&database=test", 'CONTENT_TYPE' => 'application/json', input: body
    )
  end
end
