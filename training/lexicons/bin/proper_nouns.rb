# -*- coding: utf-8 -*-
require_relative '../../../lib/sql_utils.rb'

class ProperNouns

  MAX_NUM_COMPONENTS = 105

  def initialize(file_name, links_file_name, candidate_tags_file_name)
    @file_name = file_name
    @links_file_name = links_file_name
    @candidate_tags_file_name = candidate_tags_file_name
  end

  def save(db)
    query = "create table proper_nouns (id integer, proper_noun text, tag text, lemma text, hiperlemma text"
    (1..MAX_NUM_COMPONENTS).each do |cindex|
      column_name = "c"
      query = query + ", c#{cindex} text"
    end
    query = query + ")"
    db.execute(query)
    process_file(db)
    db.execute("create table proper_nouns_links (link text)")
    process_links_file(db)
    db.execute("create table proper_nouns_candidate_tags (tag text)")
    process_candidate_tags_file(db)
  end

  private

  def process_file(db)
    id = 1
    File.open(@file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          proper_noun, tag, lemma, hiperlemma = line.split(/\t/)
          hiperlemma = lemma unless hiperlemma
          components = proper_noun.split(/ /)
          length = components.length
          if length > MAX_NUM_COMPONENTS
            puts "Proper noun \"#{proper_noun}\" is greater than currect database capacity"
            puts "exiting..."
            exit
          end
          query = "insert into proper_nouns (id, proper_noun, tag, lemma, hiperlemma"
          query2 = " values (#{id},'#{SQLUtils.escape_SQL(proper_noun)}','#{SQLUtils.escape_SQL(tag)}','#{SQLUtils.escape_SQL(lemma)}','#{SQLUtils.escape_SQL(hiperlemma)}'"
          (1..length).each do |cindex|
            query = query + ", c#{cindex}"
            query2 = query2 + ", '#{SQLUtils.escape_SQL(components[cindex-1])}'"
          end
          query = query + ")"
          query2 = query2 + ")"
          query = query + query2
          #puts "query:#{query}"
          db.execute(query)
          id = id + 1
        end
      end
    end
  end
  
  def process_links_file(db)
    File.open(@links_file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          query = "insert into proper_nouns_links (link) values ('#{SQLUtils.escape_SQL(line)}')"
          db.execute(query)
        end
      end
    end
  end
  
  def process_candidate_tags_file(db)
    File.open(@candidate_tags_file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          query = "insert into proper_nouns_candidate_tags (tag) values ('#{SQLUtils.escape_SQL(line)}')"
          db.execute(query)
        end
      end
    end
  end
end
