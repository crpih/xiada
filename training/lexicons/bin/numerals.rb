# -*- coding: utf-8 -*-
require_relative '../../../lib/sql_utils.rb'

class Numerals

  MAX_NUM_COMPONENTS = 4

  def initialize(file_name, values_file_name)
    @file_name = file_name
    @values_file_name = values_file_name
  end

  def save(db)
  
    query = "create table cardinals (id integer, cardinal text, tag text, lemma text, hiperlemma text"
    (1..MAX_NUM_COMPONENTS).each do |cindex|
      column_name = "c"
      query = query + ", c#{cindex} text"
    end
    query = query + ", primary key(cardinal, tag)"
    query = query + ")"
    db.execute(query)
    process_file(db)
    db.execute("create index cardinals_cardinal on cardinals(cardinal)")
    (1..MAX_NUM_COMPONENTS).each do |cindex|
      column_name = "c"
      db.execute("create index cardinals_c#{cindex} on cardinals(c#{cindex})")
    end
    db.execute("create table numerals_values (variable_name text, value text)")
    process_values_file(db)
  end

  private

  def process_file(db)
    id = 1
    File.open(@file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          cardinal, tag, lemma, hiperlemma = line.split(/\t/)
          hiperlemma = lemma unless hiperlemma
          components = cardinal.split(/ /)
          length = components.length
          if length > MAX_NUM_COMPONENTS
            puts "Cardinal \"#{cardinal}\" is greater than currect database capacity"
            puts "exiting..."
            exit
          end
          query = "insert into cardinals (id, cardinal, tag, lemma, hiperlemma"
          query2 = " values (#{id},'#{SQLUtils.escape_SQL(cardinal)}','#{SQLUtils.escape_SQL(tag)}','#{SQLUtils.escape_SQL(lemma)}','#{SQLUtils.escape_SQL(hiperlemma)}'"
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

  def process_values_file(db)
    id = 1
    File.open(@values_file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        elements = line.split(/\t/)
        variable_name = elements[0]
        values = elements[1..elements.length-1]
        if (values.length == 1)
          value = values[0]
        else
          value = nil
          values.each do |value_aux|
            if value == nil
              value = value_aux
            else
              value = value + " #{value_aux}"
            end
          end
        end
        db.execute("insert into numerals_values values ('#{variable_name}','#{value}')")
      end
    end
  end
  
end
