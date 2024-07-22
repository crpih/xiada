# -*- coding: utf-8 -*-
require 'rubygems'
require 'dbi'
require 'sqlite3'
require_relative 'contractions.rb'
require_relative 'idioms.rb'
require_relative 'abbreviations.rb'
require_relative 'acronyms.rb'
require_relative 'numerals.rb'
require_relative 'enclitics.rb'
require_relative 'tags_info.rb'

if ARGV.size == 15
  training_database_file = ARGV[0]
  contractions_file = ARGV[1]
  sure_idioms_file = ARGV[2]
  unsure_idioms_file = ARGV[3]
  abbreviations_file = ARGV[4]
  acronyms_file = ARGV[5]
  proper_nouns_file = ARGV[6]
  proper_nouns_links_file = ARGV[7]
  proper_nouns_candidate_tags_file = ARGV[8]
  numerals_file = ARGV[9]
  numerals_values_file = ARGV[10]
  enclitic_verbs_file = ARGV[11]
  enclitics_file = ARGV[12]
  enclitic_combinations_file = ARGV[13]
  tags_info_file = ARGV[14]
  db = SQLite3::Database.open(training_database_file)
  db.transaction
  puts "Including contractions..."
  contractions = Contractions.new(contractions_file)
  contractions.save(db)
  puts "Including idioms..."
  idioms = Idioms.new(sure_idioms_file, unsure_idioms_file)
  idioms.save(db)
  puts "Including abbreviations..."
  abbreviations = Abbreviations.new(abbreviations_file)
  abbreviations.save(db)
  puts "Including acronyms..."
  acronyms = Acronyms.new(acronyms_file)
  acronyms.save(db)
  puts "Including numerals..."
  numerals = Numerals.new(numerals_file, numerals_values_file)
  numerals.save(db)
  puts "Including enclitics..."
  enclitics = Enclitics.new(enclitic_verbs_file, enclitics_file, enclitic_combinations_file)
  enclitics.save(db)
  puts "Including tags information..."
  tags_info = TagsInfo.new(tags_info_file)
  tags_info.save(db)
  db.commit
  db.close
else
  puts "Usage:"
  puts "\truby #{$PROGRAM_NAME} <training_database_file> <contractions_file> <sure_idioms_file> <unsure_idioms_file> <abreviations_file> <acronyms_file> <proper_nouns_file> <proper_nouns_links_file> <proper_nouns_candidate_tags> <numerals_file> <numerals_info_file> <enclitic_verb_files> <enclitics_file> <enclitic_combinations_file> <tags_info_file>"
end

