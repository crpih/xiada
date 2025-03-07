require 'sqlite3'
require 'json'
require 'fileutils'
require_relative '../../test_helper'
require_relative '../../../running/bin/database_wrapper'
require_relative '../../../running/galician_xiada/lemmas/lemmatizer_corga'
require_relative '../../../running/galician_eslora/lemmatizer'

def gender_number_variations(word)
  return word unless word.end_with?('o')

  base = word.delete_suffix('o')
  [word, "#{word}s", "#{base}a", "#{base}as"]
end

def read_words(database_name)
  File.readlines("test/regression/lemmatizer/#{database_name}_selected_words.txt", chomp: true)
      .map { |l| l.split('#').first&.strip } # Remove comments
      .reject(&:nil?).reject(&:empty?) # Skip blank lines
      .flat_map { |w| gender_number_variations(w) }
end

def test_snapshots(database_name, lemmatizer, all_tags)
  words = read_words(database_name)
  current = words.each_with_object({}) do |word, result|
    lemmas = lemmatizer.lemmatize(word, all_tags)
    result[word] = lemmas if lemmas&.any?
  end

  # Save current results as expected if ENV variable defined
  if ENV['XIADA_SAVE_RESULT']
    FileUtils.mkdir_p("#{__dir__}/#{database_name}")
    File.write("#{__dir__}/#{database_name}/selected.json", JSON.pretty_generate(current))
  end

  expected = JSON.parse(File.read("#{__dir__}/#{database_name}/selected.json"))
  words.each do |word|
    expected_word = expected[word]
    it "#{word}" do
      if expected_word.nil?
        assert_nil current[word], "Failed lemmatization for: #{word}"
      else
        assert_equal expected_word, current[word], "Failed lemmatization for: #{word}"
      end
    end
  end
end

describe "Lemmatizer" do
  describe "galician_xiada" do
    ENV['XIADA_PROFILE'] = 'galician_xiada'
    ENV['XIADA_DATABASE'] = 'galician_xiada_escrita'
    dw = DatabaseWrapper.new("training/databases/galician_xiada/training_galician_xiada_escrita.db")
    all_tags = dw.get_possible_tags(['*']).split(',').map { |t| t.delete_prefix("'").delete_suffix("'") }
    lemmatizer = Lemmas::LemmatizerCorga.new(dw)

    test_snapshots('galician_xiada_escrita', lemmatizer, all_tags)
  end

  describe "galician_eslora" do
    ENV['XIADA_PROFILE'] = 'galician_eslora'
    ENV['XIADA_DATABASE'] = 'galician_eslora'
    dw = DatabaseWrapper.new("training/databases/galician_eslora/training_galician_eslora.db")
    all_tags = dw.get_possible_tags(['*']).split(',').map { |t| t.delete_prefix("'").delete_suffix("'") }
    lemmatizer = LemmatizerMultilingualEslora.new(dw)

    test_snapshots('galician_eslora', lemmatizer, all_tags)
  end
end
