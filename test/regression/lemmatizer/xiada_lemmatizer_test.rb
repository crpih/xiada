require 'sqlite3'
require 'json'
require 'fileutils'
require_relative '../../test_helper'
require_relative '../../../running/bin/lemmatizer'
require_relative '../../../running/bin/database_wrapper'
require_relative '../../../running/galician_xiada/lemmatizer'
require_relative '../../../running/galician_xiada/lemmatizer_refactor'

def gender_number_variations(word)
  return word unless word.end_with?('o')

  base = word.delete_suffix('o')
  [word, "#{word}s", "#{base}a", "#{base}as"]
end

WORDS = File.readlines('test/regression/lemmatizer/xiada_selected_words.txt', chomp: true)
            .flat_map { |w| gender_number_variations(w) }

DATABASES = %w[training_galician_xiada_escrita].freeze

describe LemmatizerGalicianXiada do
  DATABASES.each do |database_name|
    it "should match #{database_name} previous results for selected examples" do
      # Setup
      ENV['XIADA_PROFILE'] = 'galician_xiada'
      db_file = "training/databases/galician_xiada/#{database_name}.db"
      dw = DatabaseWrapper.new(db_file)
      lemmatizer = Lemmatizer.new(dw).extend(LemmatizerGalicianXiadaRefactor)

      current = WORDS.each_with_object({}) do |word, result|
        lemmas = lemmatizer.lemmatize(word, nil)
        result[word] = lemmas if lemmas&.any?
      end

      # Save current results as expected if ENV variable defined
      if ENV['XIADA_SAVE_RESULT']
        FileUtils.mkdir_p("#{__dir__}/#{database_name}")
        File.write("#{__dir__}/#{database_name}/selected.json", JSON.pretty_generate(current))
      end

      expected = JSON.parse(File.read("#{__dir__}/#{database_name}/selected.json"))
      WORDS.each do |word|
        expected_word = expected[word]
        if expected_word.nil?
          assert_nil current[word], "Failed lemmatization for: #{word}"
        else
          assert_equal expected_word, current[word], "Failed lemmatization for: #{word}"
        end
      end
    end
  end
end
