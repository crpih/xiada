# -*- coding: utf-8 -*-

require_relative "../spanish_eslora/lemmatizer.rb"
require_relative "../../lib/sql_utils.rb"

class Lemmatizer
  def initialize(dw)
    @dw = dw
  end

  def lemmatize(word, tags)
    return []
    #return word ? word : "*"
  end

  def lemmatize_verb_with_enclitics(left_part)
    return left_part
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

  # NOTE: This function breaks statistical model in some way
  def replace_lemmas(dw_result, search_exp, replace_exp)
    result = Array.new
    dw_result.each do |row|
      row[1].gsub!(/#{search_exp}/,"#{replace_exp}")
      result << row
    end
    return result
  end

  def replace_hiperlemmas(dw_result, search_exp, replace_exp)
    result = Array.new
    dw_result.each do |row|
      if search_exp && replace_exp
        row[2].gsub!(/#{search_exp}/,"#{replace_exp}") if row[2]
      else
        row[2]="#{replace_exp}" unless search_exp
      end
      result << row
    end
    return result
  end
end
