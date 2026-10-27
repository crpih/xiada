require_relative './test_helper'
require_relative '../running/galician_xiada/pruning_system'

describe GalicianXiada::PruningSystem do
  it 'reports matching rules to the caller without printing routine rejections' do
    window = [
      ['con', 'P', ['con'], 'con'],
      ['a', 'Ddfs', ['o'], 'a'],
      ['xylophone', 'S.m.', ['xylophone'], 'xylophone'],
      nil
    ]
    rules = []
    stdout, stderr = capture_subprocess_io do
      assert_equal 2, GalicianXiada::PruningSystem.new.process(window) { |rule| rules << rule }
    end

    assert_empty stdout
    assert_empty stderr
    assert_includes rules.first, 'con,P,con,_'
    assert_equal 1, rules.length
  end

  it 'preserves the return value when no diagnostics are requested' do
    window = [['con', 'P', ['con'], 'con'], ['a', 'Ddfs', ['o'], 'a'],
              ['xylophone', 'S.m.', ['xylophone'], 'xylophone'], nil]
    _stdout, stderr = capture_subprocess_io do
      assert_equal 2, GalicianXiada::PruningSystem.new.process(window)
    end
    assert_empty stderr
  end
end
