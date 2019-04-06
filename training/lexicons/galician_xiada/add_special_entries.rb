# -*- coding: utf-8 -*-
if ARGV.size == 1
  corpus_file_name = ARGV[0]
  File.open(corpus_file_name,"a") do |file|
    file.puts("<fórmula/>\tZf00\t<fórmula/>")
    file.puts("<fórmula></fórmula>\tZf00\t<fórmula></fórmula>")
    file.puts("Rei\tScms\trei")
    file.puts("€\tZs00\t€\t€")
    # file.puts("¤\tZs00\t¤")
  end
else
  puts "Usage:"
  puts "\truby #{$PROGRAM_NAME} <lexicon_file>"
end
