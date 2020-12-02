# -*- coding: utf-8 -*-

class SQLUtils

  def self.escape_SQL(str)
    str = str.gsub(/'/,"''")
    str
  end

  def self.escape_SQL_wildcards(str)
    str = str.gsub(/'/,"''")
    str.gsub!("\*","%")
    str.gsub!("\?","_")
    str
  end
end
