# -*- coding: utf-8 -*-
require_relative 'tag.rb'

class Delta

  attr_reader :value, :normalized_value, :length, :prev_delta, :tag, :prev_tag_value

  def initialize(value, prev_delta, length, tag, prev_tag_value)
    @value = value
    @normalized_value = value / Math.log(length)
    @prev_delta = prev_delta
    @length = length
    @tag = tag
    @prev_tag_value = prev_tag_value
  end

end
