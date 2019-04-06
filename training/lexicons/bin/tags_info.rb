# -*- coding: utf-8 -*-
require_relative '../../../lib/sql_utils.rb'

class TagsInfo

  def initialize(file_name)
    @file_name = file_name
  end

  def save(db)
    query = "create table tags_info (id integer, category text, name text, class text)"
    db.execute(query)
    process_file(db)
  end

  private

  def process_file(db)
    id = 1
    File.open(@file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          category, category_class, name = line.split(/\t/)
          query = "insert into tags_info (id, category, name, class) values (#{id},'#{SQLUtils.escape_SQL(category)}', '#{name}', '#{category_class}')"
          db.execute(query)
          id = id + 1
        end
      end
    end
  end
end
