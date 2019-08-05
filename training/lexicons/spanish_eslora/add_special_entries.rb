# -*- coding: utf-8 -*-
if ARGV.size == 1
  corpus_file_name = ARGV[0]
  File.open(corpus_file_name,"a") do |file|
    #file.puts "/\tQ\t/"
    #file.puts "//\tQ\t//"
    file.puts "<pausa/>\tETQ_PAUSA\t<pausa/>"
    file.puts "<pausa></pausa>\tETQ_PAUSA\t<pausa></pausa>"
    file.puts "<pausalarga/>\tETQ_PAUSA\t<pausalarga/>"
    file.puts "<pausalarga></pausalarga>\tETQ_PAUSA\t<pausalarga></pausalarga>"
    file.puts "<silencio/>\tETQ_PAUSA\t<silencio/>"
    file.puts "<silencio></silencio>\tETQ_PAUSA\t<silencio></silencio>"
    file.puts "estes\tDDMP\teste"
    file.puts "estes\tPDMP\teste"
    file.puts "eses\tDDMP\tese"
    file.puts "eses\tPDMP\tese"
  end
else
  puts "Usage:"
  puts "\truby #{$PROGRAM_NAME} <lexicon_file>"
end
