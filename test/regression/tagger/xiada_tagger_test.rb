require 'csv'
require 'fileutils'
require_relative '../../test_helper'
require_relative '../../../running/bin/config'
require_relative '../../../running/bin/xiada_tagger'

def test_snapshots(tagger_config, document_config, cases_filename)
  tagger = XiadaTagger.new(tagger_config)
  CSV.foreach("#{__dir__}/#{cases_filename}.csv", col_sep: "\t", skip_lines: /^#/, skip_blanks: true).map(&:first).each_with_index do |example, i|
    it "#{cases_filename}/#{i}.csv #{example}" do
      # We are removing unit positions to be able to compare the result with previous snapshots
      # TODO: Incorporate unit positions in the snapshots when the tagger is more stable
      result = CSV.generate(col_sep: "\t", encoding: 'utf-8') do |csv|
        tagger.tag_texts(document_config, [example]).first.each do |token|
          csv << token.values_at(:token, :tag, :lemma, :hiperlemma)
        end
      end

      if ENV["UPDATE_SNAPSHOTS"] == "1" && cases_filename == "corga_4_2"
        FileUtils.mkdir_p("#{__dir__}/#{cases_filename}")
        File.write("#{__dir__}/#{cases_filename}/#{i}.csv", result)
      end

      expected = File.read("#{__dir__}/#{cases_filename}/#{i}.csv")
      assert_equal expected, result
    end
  end
end

describe 'XiadaTagger' do
  profiles = YAML.load_file("#{__dir__}/../../../profiles.example.yml", symbolize_names: true)
  galician_xiada_params = profiles.find { it[:profile] == "galician_xiada" }
  spanish_eslora_params = profiles.find { it[:profile] == "spanish_eslora" }

  describe 'galician_xiada reference' do
    tagger_config = Config::Tagger.new(**galician_xiada_params)
    document_config = Config::Document.new(seseo: true, gheada: true)
    test_snapshots(tagger_config, document_config, 'galician_xiada_escrita')
  end

  describe 'galician_xiada regressions manually selected' do
    tagger_config = Config::Tagger.new(**galician_xiada_params)
    document_config = Config::Document.new(seseo: true, gheada: true)
    test_snapshots(tagger_config, document_config, 'galician_xiada_escrita_manual_cases')
  end

  describe 'galician_xiada CORGA 4.2 baseline' do
    tagger_config = Config::Tagger.new(**galician_xiada_params)
    document_config = Config::Document.new(seseo: true, gheada: true)
    test_snapshots(tagger_config, document_config, 'corga_4_2')
  end

  describe 'spanish_eslora' do
    tagger_config = Config::Tagger.new(**spanish_eslora_params)
    document_config = Config::Document.new(seseo: false, gheada: false)
    test_snapshots(tagger_config, document_config, 'spanish_eslora')
  end
end
