# -*- coding: utf-8 -*-
require_relative '../../../lib/sql_utils.rb'

class Acronyms

  def initialize(file_name)
    @file_name = file_name
  end

  def save(db)
    db.execute("create table acronyms (acronym text, tag text, lemma text, hiperlemma text)")
    process_file(db)
  end

  private

  def process_file(db)
    File.open(@file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          acronym, tag, lemma, hiperlemma = line.split(/\t/)
          hiperlemma = lemma unless hiperlemma
          query = "insert into acronyms (acronym, tag, lemma, hiperlemma) values ('#{SQLUtils.escape_SQL(acronym)}','#{SQLUtils.escape_SQL(tag)}','#{SQLUtils.escape_SQL(lemma)}','#{SQLUtils.escape_SQL(hiperlemma)}')"
          db.execute(query)
        end
      end
    end
  end
end
