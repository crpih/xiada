# -*- coding: utf-8 -*-
require_relative "hmm_trainer.rb"

if ARGV.size == 3 or ARGV.size == 4
  corpus_file_name = ARGV[0]
  db_name = ARGV[1]
  tags_info_file = ARGV[2]
  external_lexicon = ARGV[3]
  trainer = HMMTrainer.new(corpus_file_name, tags_info_file)
  if external_lexicon != nil
    trainer.preload_external_lexicon(external_lexicon)
  end
  trainer.train
  puts "Writing to database #{db_name}..."
  trainer.db_insert(db_name)
else
  puts "Usage:"
  puts "\truby #{$PROGRAM_NAME} <corpus> <db_file> <tags_info_file> [<external_lexicon>]"
end
