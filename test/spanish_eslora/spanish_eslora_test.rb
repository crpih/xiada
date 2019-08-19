require "test_helper"

class SpanishEsloraTaggingTests < Minitest::Test
  def tagger(file_name)
    command = " XIADA_PROFILE=spanish_eslora ruby #{__dir__}/../../running/bin/xiada_tagger.rb -x #{__dir__}/../../running/spanish_eslora/xml_values.txt -t -v -f #{__dir__}/#{file_name}.xml #{__dir__}/../../training/databases/spanish_eslora/training_spanish_eslora.db 2> #{__dir__}/#{file_name}.log | xmllint --format - > #{__dir__}/output/#{file_name}_new.xml "
    # puts "command:#{command}"
    `#{command}`
  end

  STDERR.puts "spanish #{__dir__}"

  Dir.glob("#{__dir__}/*.xml").each do |full_file_name|
    file_name = File.basename(full_file_name, ".*")
    define_method("test_#{file_name}") do
      tagger(file_name)
      result = File.read("#{__dir__}/output/#{file_name}_new.xml")
      expected = File.read("#{__dir__}/output/#{file_name}_output.xml")
      assert_equal expected, result
    end
  end
end
