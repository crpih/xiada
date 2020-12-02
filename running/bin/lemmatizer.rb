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

  protected

  # NOTE: This function breaks statistical model in some way
  def replace_tags(dw_result, search_exp, replace_exp)
    result = Array.new
    dw_result.each do |row|
      row[0].gsub!(/#{search_exp}/,"#{replace_exp}")
      result << row
    end
    return result
  end
end
