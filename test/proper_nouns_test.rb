require 'csv'
require_relative './test_helper'
require_relative '../running/bin/proper_nouns'

describe 'ProperNounsTest' do
  describe 'galician_xiada' do

    joiners = CSV.read("training/lexicons/galician_xiada/proper_nouns_links.txt", col_sep: "\t").map(&:first)
    literals = ProperNouns.parse_literals_file("training/lexicons/galician_xiada/lexicon_propios.txt")
    tags = CSV.read("training/lexicons/galician_xiada/proper_nouns_candidate_tags.txt", col_sep: "\t").map(&:first)

    describe 'literal proper nouns' do
      it 'should detect literals anywhere in the sentence' do
        proper_nouns = ProperNouns.new(literals, joiners, tags)
        literals.each do |literal|
          result = proper_nouns.call(literal.text)
          expected = [ProperNouns::Literal.new(literal.text, literal.tag_lemmas)]
          assert_equal expected, result, "Failed to detect literal proper noun: #{literal.text}"
        end
      end

      it 'should expand the range of the literal if next range is a standard proper noun' do
        proper_nouns = ProperNouns.new(literals, joiners, tags)
        literals.each do |literal|
          # Skip literals ending with punctuation, proper nouns after that won't be detected
          next if literal.text.match?(/[!?).]\z/)

          text = "#{literal.text} Hermenegildo"
          result = proper_nouns.call(text)
          expected = [ProperNouns::Literal.new(text, tags.map { |tag| [tag, text] }.sort)]
          assert_equal expected, result, "Failed to expand literal proper noun: #{literal.text}"
        end
      end

      it 'should expand the range of the literal if next range is separated by a joiner' do
        proper_nouns = ProperNouns.new(literals, joiners, tags)
        joiners.each do |joiner|
          # Test with all literals is too slow, so we test with a sample
          literals.sample(10).each do |literal|
            text = "#{literal.text} #{joiner} Hermenegildo"
            result = proper_nouns.call(text)
            expected = [ProperNouns::Literal.new(text, tags.map { |tag| [tag, text] }.sort)]
            assert_equal expected, result, "Failed to expand literal proper noun separated by joiner: #{joiner}"
          end
        end
      end
    end

    describe 'standard proper nouns' do
      it 'should detect uppercases not after punctuation' do
        proper_nouns = ProperNouns.new([], joiners, tags)
        %w[? ! . )].each do |punctuation|
          text = "Ola, que tal#{punctuation} Eu son o Xoán."
          result = proper_nouns.call(text)
          expected = [
            "Ola, que tal#{punctuation} Eu son o ",
            ProperNouns::Literal.new("Xoán", tags.map { |tag| [tag, "Xoán"] }.sort),
            "."
          ]
          assert_equal expected, result, "Failed to detect proper noun not after punctuation: #{punctuation}"
        end
      end

      it 'should not detect uppercases at the beginning of a sentence' do
        proper_nouns = ProperNouns.new([], joiners, tags)
        text = "Xoán é un nome."
        assert_equal [text], proper_nouns.call(text)
      end

      it 'should detect proper nouns separated by joiners' do
        proper_nouns = ProperNouns.new([], joiners, tags)
        joiners.each do |joiner|
          text = "Son Xoán #{joiner} García."
          noun_start = 4
          noun_end = noun_start + 5 + joiner.size + 7
          result = proper_nouns.call(text)
          expected = [
            text[0...noun_start],
            ProperNouns::Literal.new("Xoán #{joiner} García", tags.map { |tag| [tag, "Xoán #{joiner} García"] }.sort),
            text[noun_end...text.size]
          ]
          assert_equal expected, result, "Failed to detect proper noun separated by joiner: #{joiner}"
        end
      end

      it 'should detect proper nouns between quotes' do
        proper_nouns = ProperNouns.new([], joiners, tags)
        %w[" '].each do |quote|
          text = "Dixo #{quote}Xoán#{quote}."
          result = proper_nouns.call(text)
          expected = [
            "Dixo ",
            ProperNouns::Literal.new("#{quote}Xoán#{quote}", tags.map { |tag| [tag, "#{quote}Xoán#{quote}"] }.sort),
            "."
          ]
          assert_equal expected, result, "Failed to detect proper noun between quotes: #{quote}"
        end
      end

      it 'should detect road names' do
        proper_nouns = ProperNouns.new([], joiners, tags)
        text = "Vou pola AP-9."
        result = proper_nouns.call(text)
        expected = [
          "Vou pola ",
          ProperNouns::Literal.new("AP-9", tags.map { |tag| [tag, "AP-9"] }.sort),
          "."
        ]
        assert_equal expected, result, "Failed to detect road name: #{text}"
      end
    end

    describe 'trained proper nouns' do
      it 'should detect trained proper nouns at the beginning of the sentence' do
        no_train_proper_nouns = ProperNouns.new([], joiners, tags)

        no_train_result = no_train_proper_nouns.call('Hermenegildo é un nome.')
        assert_equal ['Hermenegildo é un nome.'], no_train_result

        trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Hermenegildo.'])
        result = trained_proper_nouns.call('Hermenegildo é un nome.')
        expected = [
          ProperNouns::Literal.new('Hermenegildo', tags.map { |tag| [tag, 'Hermenegildo'] }.sort),
          ' é un nome.'
        ]
        assert_equal expected, result
      end
    end
  end
end
