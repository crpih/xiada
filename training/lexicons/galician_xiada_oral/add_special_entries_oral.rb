# -*- coding: utf-8 -*-
if ARGV.size == 1
  corpus_file_name = ARGV[0]
  File.open(corpus_file_name,"a") do |file|
    file.puts "<pausa/>\tQp\t<pausa/>"
    file.puts "<pausa></pausa>\tQp\t<pausa></pausa>"
  end
else
  puts "Usage:"
  puts "\truby #{$PROGRAM_NAME} <lexicon_file>"
end
