require_relative './test_helper'
require_relative '../running/bin/viterbi'
require 'ostruct'

class ViterbiPruningFallbackTest < Minitest::Test
  Token = Struct.new(:text, :token_type, :tagged, :nexts_ignored)
  Tag = Struct.new(:token, :ordered_deltas, :selected)
  Delta = Struct.new(:tag, :prev_delta)

  class Pruning
    def initialize(reject)
      @reject = reject
      @calls = 0
    end

    def process(_window)
      @calls += 1
      return 0 unless @reject && @calls.even?
      yield 'test rule'
      2
    end
  end

  class Harness < Viterbi
    def initialize(pruning)
      super(OpenStruct.new(pruning_system: pruning), nil)
      first = Tag.new(Token.new('word', :standard, false, {}), [], false)
      last = Tag.new(Token.new('end', :end_sentence, false, {}), [], false)
      previous = Delta.new(first, nil)
      first.ordered_deltas << Delta.new(first, nil)
      last.ordered_deltas << Delta.new(last, previous)
      @last_delta = Delta.new(last, previous)
    end

    private

    def initialize_step(*) = nil
    def recurrence_step(*) = nil
    def finalize_step(*) = @last_delta
    def reset_viterbi(*) = nil
    def update_window(*) = []
    def convert_window_to_prunning_format(*) = [['word', 'tag', ['lemma'], 'word']]
    def next_backtracking_delta(*) = nil
  end

  class RepeatedPruning
    def initialize
      @calls = 0
    end

    def process(_window)
      @calls += 1
      yield(@calls.odd? ? 'first rule' : 'second rule')
      1
    end
  end

  class RepeatedHarness < Harness
    private

    def initialize_step(*)
      @backtracks = 0
    end

    def next_backtracking_delta(*)
      @backtracks += 1
      @backtracks < 103 ? @last_delta : nil
    end
  end

  def test_fallback_preserves_every_rejection_in_order_without_a_limit
    sentence = OpenStruct.new(text: 'repeated sentence')
    processor = Object.new
    def processor.call(*) = nil
    _stdout, stderr = capture_subprocess_io do
      Postprocessor.stub(:new, ->(*) { processor }) { RepeatedHarness.new(RepeatedPruning.new).run(sentence) }
    end
    failures = JSON.parse(stderr).fetch('failures')
    assert_equal 103, failures.first.fetch('rejections').length
    assert_equal Array.new(51, ['first rule', 'second rule']).flatten + ['first rule'],
                 failures.first.fetch('rejections').map { |r| r.fetch('rule') }
  end

  def run_with(reject)
    sentence = OpenStruct.new(text: 'the sentence')
    processor = Object.new
    def processor.call(*) = nil
    _stdout, stderr = capture_subprocess_io do
      Postprocessor.stub(:new, ->(*) { processor }) { Harness.new(Pruning.new(reject)).run(sentence) }
    end
    stderr
  end

  def test_fallback_reports_sentence_problematic_word_and_rule
    event = JSON.parse(run_with(true))
    assert_equal 'pruning_fallback', event.fetch('event')
    assert_equal 'the sentence', event.fetch('sentence')
    assert_equal 'end', event.fetch('failures').first.fetch('token')
    assert_equal 'test rule', event.fetch('failures').first.fetch('rule')
    assert_equal 'word', event.fetch('failures').first.fetch('window').first.first
  end

  def test_successful_analysis_is_silent
    assert_empty run_with(false)
  end
end
