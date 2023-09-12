require 'csv'
require 'fileutils'
require_relative '../../test_helper'
def test_snapshots(profile, database_name, sentence_tag, command)
  ENV['XIADA_PROFILE'] = profile

  CSV.foreach("#{__dir__}/#{database_name}.csv").map(&:first).each_with_index do | example, i|
    it "#{i}.xml #{example}" do
      input = Tempfile.new
      input.write <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <document>
          <document_content>
            <#{sentence_tag}>#{example}</#{sentence_tag}>
          </document_content>
        </document>
      XML
      input.rewind

      result = `#{command.(input.path)}`

      # Save current results as expected if ENV variable defined
      if ENV['XIADA_SAVE_RESULT']
        FileUtils.mkdir_p("#{__dir__}/#{database_name}")
        File.write("#{__dir__}/#{database_name}/#{i}.xml", result) # if ENV['XIADA_SAVE_RESULT']
      end

      expected = File.read("#{__dir__}/#{database_name}/#{i}.xml")
      assert_equal expected, result
    ensure
      input.close
      input.unlink
    end
  end
end

describe 'XiadaTagger' do
  describe 'galician_xiada' do
    test_snapshots(
      'galician_xiada',
      'training_galician_xiada_escrita',
      'oración',
      ->(i) { "XIADA_PROFILE=galician_xiada ruby running/bin/xiada_tagger.rb -x running/galician_xiada/xml_values.txt -t -v -f #{i} training/databases/galician_xiada/training_galician_xiada_escrita.db 2> /dev/null" }
    )
  end

  describe 'spanish_eslora' do
    test_snapshots(
      'spanish_eslora',
      'training_spanish_eslora',
      'fragmento',
      ->(i) { "XIADA_PROFILE=spanish_eslora ruby running/bin/xiada_tagger.rb -x running/spanish_eslora/xml_values.txt -t -v --force_proper_nouns -f #{i} training/databases/spanish_eslora/training_spanish_eslora.db 2> /dev/null" }
    )
  end
end
