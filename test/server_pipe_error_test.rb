require_relative './test_helper'
require 'rack/mock'
require 'yaml'
require 'timeout'

YAML.stub(:load_file, []) { require_relative '../running/bin/server' }

class ServerPipeErrorTest < Minitest::Test
  Tagger = Struct.new(:profile, :database, :only_lexicon, :force_proper_nouns, :kill_parent) do
    def tag_texts(_config, texts)
      if kill_parent
        parent = Process.ppid
        Process.kill('KILL', parent)
        $test_gate.read(1)
      end
      texts.map { [] }
    end

    alias_method :tag_texts_alternatives, :tag_texts
  end

  def request_in_process(kill_parent, path = '/tagger')
    reader, writer = IO.pipe
    gate_reader, gate_writer = IO.pipe
    pid = fork do
      reader.close
      gate_writer.close
      $test_gate = gate_reader
      STDOUT.reopen(writer)
      STDERR.reopen(writer)
      $stdout.sync = true
      TAGGERS.replace([Tagger.new('test', 'test', false, false, kill_parent)])
      response = Rack::MockRequest.new(Sinatra::Application).post(
        "#{path}?profile=test&database=test", 'CONTENT_TYPE' => 'application/json', input: '["private sentence"]'
      )
      puts "response_status=#{response.status} body=#{response.body}"
      exit! 0
    end
    writer.close
    gate_reader.close
    status = Timeout.timeout(10) do
      _, child_status = Process.wait2(pid)
      gate_writer.write('x') if kill_parent
      child_status
    end
    gate_writer.close
    output = Timeout.timeout(10) { reader.read }
    [output, status]
  ensure
    reader&.close
    writer&.close unless writer&.closed?
    gate_reader&.close unless gate_reader&.closed?
    gate_writer&.close unless gate_writer&.closed?
  end

  def test_epipe_identifies_request_and_parent_state_without_logging_text
    output, status = request_in_process(true)
    assert status.signaled?
    assert_includes output, 'Exception in child process: Errno::EPIPE'
    assert_match(/timestamp=\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z/, output)
    assert_match(/parent_pid=\d+/, output)
    assert_match(/current_ppid=\d+/, output)
    assert_match(/child_pid=\d+/, output)
    assert_includes output, 'path=/tagger'
    assert_includes output, 'profile=test'
    assert_includes output, 'database=test'
    assert_match(/elapsed_ms=\d+/, output)
    refute_includes output, 'private sentence'
  end

  def test_successful_requests_keep_response_and_do_not_log_pipe_errors
    ['/tagger', '/tagger/alternatives'].each do |path|
      output, status = request_in_process(false, path)
      assert status.success?
      assert_includes output, 'response_status=200 body=[[]]'
      refute_includes output, 'Errno::EPIPE'
    end
  end

  def test_alternatives_pipe_error_identifies_endpoint
    output, status = request_in_process(true, '/tagger/alternatives')
    assert status.signaled?
    assert_includes output, 'Exception in child process: Errno::EPIPE'
    assert_includes output, 'path=/tagger/alternatives'
  end
end
