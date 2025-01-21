require 'csv'
require 'fileutils'
require_relative '../../test_helper'

def test_snapshots(database_name)
  tagger = XiadaTagger.new
  CSV.foreach("#{__dir__}/#{database_name}.csv").map(&:first).each_with_index do |example, i|
    it "#{i}.csv #{example}" do

      # We are removing unit positions to be able to compare the result with previous snapshots
      # TODO: Incorporate unit positions in the snapshots when the tagger is more stable
      result = CSV.generate(col_sep: "\t", encoding: 'utf-8') do |csv|
        tagger.call(example).best_way.each do |token|
          csv << token.values_at(:token, :tag, :lemma, :hiperlemma)
        end
      end

      # Save current results as expected if ENV variable defined
      if ENV['XIADA_SAVE_RESULT']
        FileUtils.mkdir_p("#{__dir__}/#{database_name}")
        File.write("#{__dir__}/#{database_name}/#{i}.csv", result)
      end

      expected = File.read("#{__dir__}/#{database_name}/#{i}.csv")
      assert_equal expected, result
    end
  end
end

describe 'XiadaTagger' do
  describe 'galician_xiada' do
    ENV['XIADA_PROFILE'] = 'galician_xiada'
    ENV['XIADA_DATABASE'] = 'galician_xiada_escrita'
    require_relative '../../../running/bin/xiada_tagger'

    test_snapshots('training_galician_xiada_escrita')
  end

  describe 'spanish_eslora' do
    ENV['XIADA_PROFILE'] = 'spanish_eslora'
    ENV['XIADA_DATABASE'] = 'spanish_eslora'
    require_relative '../../../running/bin/xiada_tagger'

    test_snapshots('training_spanish_eslora')
  end
end
