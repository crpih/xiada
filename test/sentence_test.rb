require 'set'
require_relative 'test_helper'
require_relative '../running/bin/sentence'

class SentenceTest < Minitest::Test
  def setup
    @sentence = Sentence.allocate
    @sentence.instance_variable_set(:@abbreviations, Set.new)
    @sentence.instance_variable_set(:@acronyms, Set.new)
  end

  def test_separates_a_standalone_percent_symbol_from_following_comma
    assert_equal ['%', ','], @sentence.tokenize('%,', false)
  end

  def test_keeps_numeric_percentages_attached_before_following_comma
    assert_equal ['25%', ','], @sentence.tokenize('25%,', false)
  end
end
