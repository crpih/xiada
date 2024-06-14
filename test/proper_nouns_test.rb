require 'csv'
require_relative './test_helper'
require_relative '../running/bin/proper_nouns'

describe 'ProperNounsTest' do
  describe 'galician_xiada' do

    it 'should detect literal proper nouns' do
      nouns = CSV.read("training/lexicons/galician_xiada/lexicon_propios.txt", col_sep: "\t").map(&:first)
      proper_nouns = ProperNouns.new(nouns, [], [])
      nouns.each do |noun|
        assert_equal [0...noun.size], proper_nouns.call(noun), "Failed to detect literal proper noun: #{noun}"
      end
    end

    it 'should detect standard proper nouns' do
      proper_nouns = ProperNouns.new([], [], [])
      text = "Ola, que tal? Eu son o Xoán."
      assert_equal [23...27], proper_nouns.call(text), "Failed to detect standard proper noun: Xoán"
    end
  end
end
