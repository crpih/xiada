require 'csv'
require_relative 'test_helper'
require_relative '../running/bin/config'
require_relative '../running/bin/xiada_tagger'

class CapitalizationTest < Minitest::Test
  CASES = {
    7 => 'Estudantes',
    8 => 'The',
    9 => 'Hannah',
    10 => 'Asociación',
    11 => 'Atacan'
  }.freeze

  def setup
    params = YAML.load_file('profiles.example.yml', symbolize_names: true).find { |profile| profile[:profile] == 'galician_xiada' }
    @tagger = XiadaTagger.new(Config::Tagger.new(**params))
    @document_config = Config::Document.new(seseo: true, gheada: true)
    @examples = CSV.foreach('test/regression/tagger/corga_4_2.csv', col_sep: "\t", skip_lines: /^#/, skip_blanks: true).map(&:first)
  end

  def test_full_best_way_snapshots_preserve_capitalization
    CASES.each_key do |index|
      result = @tagger.tag_texts(@document_config, [@examples.fetch(index)]).first
      actual = CSV.generate(col_sep: "\t", encoding: 'utf-8') do |csv|
        result.each { |token| csv << token.values_at(:token, :tag, :lemma, :hiperlemma) }
      end

      expected_path = "test/regression/tagger/corga_4_2/#{index}.csv"
      assert_equal File.read(expected_path), actual, "best_way snapshot #{expected_path}"
    end
  end

  def test_all_ways_matches_the_full_selected_output_and_preserves_capitalization
    CASES.each do |index, capitalized_token|
      text = @examples.fetch(index)
      best = @tagger.tag_texts(@document_config, [text]).first
      all = @tagger.tag_texts_alternatives(@document_config, [text]).first
      all_tokens = all_way_tokens(all)

      assert_equal best.map { |token| token[:token] }, selected_all_way_tokens(all), "selected all_ways output C-#{index + 1}"
      assert_includes all_tokens, capitalized_token, "all_ways output C-#{index + 1}"
      assert_equal 1, all_tokens.count(capitalized_token), "all_ways output C-#{index + 1}"
      refute_includes all_tokens, capitalized_token.downcase, "all_ways output C-#{index + 1}" unless capitalized_token == 'The'
    end
  end

  def test_only_the_first_element_is_normalized
    result = @tagger.tag_texts(@document_config, ['Desde Erguer. Estudantes']).first

    assert_equal ['desde', 'Erguer', '.', 'Estudantes'], result.map { |token| token[:token] }
  end

  def test_initial_capitalization_uses_the_selected_analysis
    common_words = ['Di a casa', 'Universidade da Coruña', 'Plataforma SOS']

    common_words.each do |text|
      result = @tagger.tag_texts(@document_config, [text]).first

      refute_match(/^[A-ZÁÉÍÓÚÑ]/, result.first[:token], text)
    end

    proper_noun = @tagger.tag_texts(@document_config, ['Vázquez falou.']).first
    assert_equal 'Vázquez', proper_noun.first[:token]
    assert_equal 'Sp00', proper_noun.first[:tag]
  end

  def test_initial_capitalization_skips_leading_punctuation
    result = @tagger.tag_texts(@document_config, ['(...) Conseguir unha reprodución']).first

    assert_equal ['(', '...', ')', 'conseguir'], result.first(4).map { |token| token[:token] }
  end

  private

  def selected_all_way_tokens(entries)
    entries.flat_map do |entry|
      if entry[:alternatives]
        selected = entry[:alternatives].find { |alternative| alternative[:selected] }
        selected_all_way_tokens(selected[:tokens])
      else
        [entry[:token]]
      end
    end
  end

  def all_way_tokens(entries)
    entries.flat_map do |entry|
      if entry[:alternatives]
        entry[:alternatives].flat_map { |alternative| all_way_tokens(alternative[:tokens]) }
      else
        [entry[:token]]
      end
    end
  end
end
