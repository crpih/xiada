require "test_helper"

class GalicianXiadaTaggingTests < Minitest::Test
  def tagger(file_name)
    command = " XIADA_PROFILE=galician_xiada ruby #{__dir__}/../../running/bin/xiada_tagger.rb -x #{__dir__}/../../running/galician_xiada/xml_values.txt -t -v -f #{__dir__}/#{file_name}.xml #{__dir__}/../../training/databases/galician_xiada/training_galician_xiada_escrita.db 2> #{__dir__}/#{file_name}.log | xmllint --format - > #{__dir__}/output/#{file_name}_new.xml "
    # puts "command:#{command}"
    `#{command}`
  end

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
