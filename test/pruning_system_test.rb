require_relative './test_helper'
require_relative '../running/galician_xiada/pruning_system'

describe GalicianXiada::PruningSystem do
  it 'logs indexed actual words for the matched window alongside the rule' do
    window = [
      ['con', 'P', ['con'], 'con'],
      ['a', 'Ddfs', ['o'], 'a'],
      ['xylophone', 'S.m.', ['xylophone'], 'xylophone'],
      nil
    ]

    _stdout, stderr = capture_subprocess_io do
      assert_equal 2, GalicianXiada::PruningSystem.new.process(window)
    end

    assert_includes stderr, 'rejected by RULE con,P,con,_'
    assert_includes stderr, 'matched words: [0, "con"], [1, "a"], [2, "xylophone"], [3, "<empty>"]'
  end
end
