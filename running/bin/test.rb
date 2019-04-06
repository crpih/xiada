# -*- coding: utf-8 -*-
require 'sentence.rb'

while line = gets
  line = line.chomp
  Sentence.new(line)
end
