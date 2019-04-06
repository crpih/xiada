# -*- coding: utf-8 -*-

class SQLUtils

  def self.escape_SQL(str)
    str = str.gsub(/'/,"''")
    return str
  end
end
