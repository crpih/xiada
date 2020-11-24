# -*- coding: utf-8 -*-

require_relative "../spanish_eslora/lemmatizer.rb"
require_relative "../galician_xiada/lemmatizer.rb"
require_relative "../../lib/sql_utils.rb"

class Lemmatizer
  def initialize(dw)
    @dw = dw
  end

  def lemmatize(word, tags)
    return word ? word : "*"
  end
end
