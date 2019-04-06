# -*- coding: utf-8 -*-
# Test if sum of emission probabilities is one.
# ??? Move to a test unit

require 'dbi'
require 'sqlite3'

def test_emission_frequencies(db)
  probabilities = Hash.new
  db.execute("select tag,log_b from emission_frequencies") do |row|
    tag = row[0]
    emission = Float(row[1])
    if probabilities[tag] == nil
      probabilities[tag] = Math.exp(emission)
    else
      probabilities[tag] = probabilities[tag] + Math.exp(emission)
    end
  end
  error = false
  probabilities.each do |tag, proba|
    value = (proba * 10**8).round.to_f / 10**8
    if value != 1.0
      error = true
      puts "tag:#{tag}, value:#{value}"
    end
  end
  puts "Emission probabilities test passed." unless error
end

def test_suffixes_frequencies(db)
  probabilities = Hash.new
  db.execute("select suffix,tag,log_b from guesser_frequencies") do |row|
    suffix = row[0]
    tag = row[1]
    emission = Float(row[2])
    key = suffix.length.to_s() + "&&&" + tag
    if probabilities[key] == nil
      probabilities[key] = Math.exp(emission)
    else
      probabilities[key] = probabilities[key] + Math.exp(emission)
    end
  end
  error = false
  probabilities.each do |key, proba|
    length, tag = key.split(/&&&/)
    value = (proba * 10**8).round.to_f / 10**8
    if value != 1.0
      error = true
      puts "length:#{length}, tag:#{tag}, value:#{value}"
    end
  end
  puts "Guesser probabilities test passed." unless error
end

if ARGV.size == 1
  db_name = ARGV[0]+".db"
  db = SQLite3::Database.open(db_name)
  test_emission_frequencies(db)
  test_suffixes_frequencies(db)
  db.close
else
  puts "Usage:"
  puts "\truby #{$PROGRAM_NAME} <training_db_name>"
end

