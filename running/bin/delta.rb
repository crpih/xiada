# -*- coding: utf-8 -*-
require_relative 'tag.rb'

class Delta

  attr_reader :value, :normalized_value, :length, :prev_delta, :tag
  
  def initialize(value, prev_delta, length, tag)
    @value = value
    @normalized_value = value / length
    @prev_delta = prev_delta
    @length = length
    @tag = tag
  end
 
end
