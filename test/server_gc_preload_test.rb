require_relative './test_helper'
require 'open3'
require 'rbconfig'

class ServerGcPreloadTest < Minitest::Test
  def test_full_collection_runs_after_every_configured_tagger_is_preloaded
    script = <<~'RUBY'
      require 'yaml'
      require_relative 'running/bin/xiada_tagger'

      profiles = [
        { profile: 'first', database: 'first', only_lexicon: false, force_proper_nouns: false, keep_uppercase_tokens_for: // },
        { profile: 'second', database: 'second', only_lexicon: false, force_proper_nouns: false, keep_uppercase_tokens_for: // }
      ]
      fake_config = Struct.new(:dw).new(Struct.new(:closed) { def close_database = self.closed = true }.new(false))
      Config::Tagger.define_singleton_method(:new) { |**_options| fake_config }
      XiadaTagger.define_singleton_method(:new) { |_config| Object.new }
      YAML.define_singleton_method(:load_file) { |*_args, **_options| profiles }
      collections = []
      GC.define_singleton_method(:start) do |**options|
        collections << [Object.const_get(:TAGGERS).length, options]
      end

      require_relative 'running/bin/server'
      expected = [[2, { full_mark: true, immediate_sweep: true }]]
      abort "unexpected GC calls: #{collections.inspect}" unless collections == expected
      puts 'GC_PRELOAD_TEST_OK'
    RUBY

    stdout, stderr, status = Open3.capture3(RbConfig.ruby, '-e', script)
    assert status.success?, "child failed (#{status.exitstatus}): #{stderr}\n#{stdout}"
    assert_includes stdout, 'GC_PRELOAD_TEST_OK'
    assert_empty stderr
  end
end
