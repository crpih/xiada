require 'sqlite3'
require 'json'
require 'fileutils'
require_relative '../../test_helper'
require_relative '../../../running/bin/config'

def gender_number_variations(word)
  return word unless word.end_with?('o')

  base = word.delete_suffix('o')
  [word, "#{word}s", "#{base}a", "#{base}as"]
end

def read_words(tagger_config)
  File.readlines("test/regression/lemmatizer/#{tagger_config.database}_selected_words.txt", chomp: true)
      .map { |l| l.split('#').first&.strip } # Remove comments
      .reject(&:nil?).reject(&:empty?) # Skip blank lines
      .flat_map { |w| gender_number_variations(w) }
end

def test_snapshots(tagger_config, document_config)
  words = read_words(tagger_config)
  all_tags = tagger_config.dw.get_possible_tags(['*']).split(',').map { |t| t.delete_prefix("'").delete_suffix("'") }
  current = words.each_with_object({}) do |word, result|
    lemmas = tagger_config.lemmatizer.lemmatize(document_config, word, all_tags)
    result[word] = lemmas if lemmas&.any?
  end

  # Uncomment to save current results as expected
  FileUtils.mkdir_p("#{__dir__}/#{tagger_config.database}")
  File.write("#{__dir__}/#{tagger_config.database}/selected.json", JSON.pretty_generate(current))

  expected = JSON.parse(File.read("#{__dir__}/#{tagger_config.database}/selected.json"))
  words.each do |word|
    expected_word = expected[word]
    current_word = current[word]
    it "#{word}" do
      if expected_word.nil?
        assert_nil current_word, "Failed lemmatization for: #{word}"
      else
        refute_nil current_word, "Failed lemmatization for: #{word}"
        expected_word.zip(current_word).each do |expected_result, actual_result|
          expected_tag, expected_lemma, expected_hyperlemma, expected_log_b = expected_result
          actual_tag, actual_lemma, actual_hyperlemma, actual_log_b = actual_result
          assert_equal expected_tag, actual_tag, "Failed lemmatization for: #{word}"
          assert_equal expected_lemma, actual_lemma, "Failed lemmatization for: #{word}"
          assert_equal expected_hyperlemma, actual_hyperlemma, "Failed lemmatization for: #{word}"
          assert_in_delta expected_log_b, actual_log_b, 0.2 # Ignore minor differences
        end
      end
    end
  end
end

describe "Lemmatizer" do
  describe "galician_xiada" do
    tagger_config = Config::Tagger.new(profile: "galician_xiada", database: "galician_xiada_escrita")
    document_config = Config::Document.new(seseo: true, gheada: true)
    test_snapshots(tagger_config, document_config)
  end

  describe "galician_eslora" do
    tagger_config = Config::Tagger.new(profile: "galician_eslora", database: "galician_eslora")
    document_config = Config::Document.new(seseo: true, gheada: true)
    test_snapshots(tagger_config, document_config)
  end
end
