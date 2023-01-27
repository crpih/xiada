require 'csv'
require 'fileutils'
require_relative '../../test_helper'

DATABASES = %w[training_galician_xiada_escrita].freeze

describe 'XiadaTagger' do
  ENV['XIADA_PROFILE'] = 'galician_xiada'

  DATABASES.each do |database_name|
    CSV.foreach("#{__dir__}/examples.csv").map(&:first).each_with_index do | example, i|
      it example do
        input = Tempfile.new
        input.write <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <document>
            <document_content>
              <oración>#{example}</oración>
            </document_content>
          </document>
        XML
        input.rewind

        result = `XIADA_PROFILE=galician_xiada ruby running/bin/xiada_tagger.rb -x running/galician_xiada/xml_values.txt -t -v -f #{input.path} training/databases/galician_xiada/training_galician_xiada_escrita.db 2> /dev/null`

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
end
