# -*- coding: utf-8 -*-
def load_tags_file(tags_file_name)
  tags = Hash.new
  File.open(tags_file_name,"r") do |file|
    while line = file.gets
      tag = line.chomp
      tags[tag] = true
    end
  end
  return tags
end

def validate_tags(lexicon_file_name, tags)
  error = false
  File.open(lexicon_file_name,"r") do |file|
    while line = file.gets
      line.chomp!
      unless line.empty?
        word, tag, lemma = line.split(/\t/)
        unless tags[tag]
          puts "tag: #{tag} from word: #{word} and lemma: #{lemma} not found."
          error = true
        end
      end
    end
  end
  return error
end

if ARGV.size == 2
  lexicon_file_name = ARGV[0]
  kernel_tags_file_name = ARGV[1]
  tags = load_tags_file(kernel_tags_file_name)
  error = validate_tags(lexicon_file_name, tags)
  exit(-1) if error
else
  puts "Usage:"
  puts "\truby #{$PROGRAM_NAME} <lexicon_file> <kernel_tags_file>"
end
