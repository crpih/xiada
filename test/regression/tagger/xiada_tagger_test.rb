require 'csv'
require 'fileutils'
require_relative '../../test_helper'
require_relative '../../../running/bin/config'
require_relative '../../../running/bin/xiada_tagger'

def test_snapshots(tagger_config, document_config, cases_filename)
  tagger = XiadaTagger.new(tagger_config)
  CSV.foreach("#{__dir__}/#{cases_filename}.csv", col_sep: "\t", skip_lines: /^#/).map(&:first).each_with_index do |example, i|
    it "#{i}.csv #{example}" do
      # We are removing unit positions to be able to compare the result with previous snapshots
      # TODO: Incorporate unit positions in the snapshots when the tagger is more stable
      result = CSV.generate(col_sep: "\t", encoding: 'utf-8') do |csv|
        tagger.tag_texts(document_config, [example]).first.each do |token|
          csv << token.values_at(:token, :tag, :lemma, :hiperlemma)
        end
      end

      # # Uncomment to save current results as expected
      # FileUtils.mkdir_p("#{__dir__}/#{cases_filename}")
      # File.write("#{__dir__}/#{cases_filename}/#{i}.csv", result)

      expected = File.read("#{__dir__}/#{cases_filename}/#{i}.csv")
      assert_equal expected, result
    end
  end
end

describe 'XiadaTagger' do
  describe 'galician_xiada reference' do
    tagger_config = Config::Tagger.new(profile: "galician_xiada", database: "galician_xiada_escrita")
    document_config = Config::Document.new(seseo: true, gheada: true)
    test_snapshots(tagger_config, document_config, 'galician_xiada_escrita')
  end

  describe 'galician_xiada regressions manually selected' do
    tagger_config = Config::Tagger.new(profile: "galician_xiada", database: "galician_xiada_escrita")
    document_config = Config::Document.new(seseo: true, gheada: true)
    test_snapshots(tagger_config, document_config, 'galician_xiada_escrita_manual_cases')
  end

  describe 'spanish_eslora' do
    tagger_config = Config::Tagger.new(profile: "spanish_eslora", database: "spanish_eslora")
    document_config = Config::Document.new(seseo: false, gheada: false)
    test_snapshots(tagger_config, document_config, 'spanish_eslora')
  end
end
