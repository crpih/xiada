# frozen_string_literal: true

require_relative '../test_helper'

CORPUS = %w[galician_xiada spanish_eslora].freeze

Token = Struct.new(:form, :tag, :lemma)

describe 'Tagger precision' do
  CORPUS.each do |corpus|
    test_sentences = File.read("test/precision/corpus/#{corpus}_test.tagged")
                         .split("\n\n")
                         .map { |s| s.split("\n") }
                         .map { |s| s.map { |t| Token.new(*t.split("\t")) } }

    input = Tempfile.new
    input << '<?xml version="1.0" encoding="UTF-8"?>'
    input << '<document>'
    input << '<document_content>'
    test_sentences.each do |sentence|
      text = sentence.map(&:form).join(' ')
      input << "<oración>#{text.encode(xml: :text)}</oración>"
    end
    input << '</document_content>'
    input << '</document>'
    input.rewind

    # FIXME: Acronyms table is missing, it should be load with something in lexicons/bin

    result = `XIADA_PROFILE=#{corpus} ruby running/bin/xiada_tagger.rb -x running/#{corpus}/xml_values.txt -t -v -f #{input.path} test/precision/databases/#{corpus}.db 2> /dev/null`

    puts result
  end
end
