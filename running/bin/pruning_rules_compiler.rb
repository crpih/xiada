# -*- coding: utf-8 -*-
# main

# This script reads from STDIN the pruning rules and print to STDOUT a
# ruby class which can process them (PruningSystem).

def print_head
  puts "class PruningSystem"
  puts "def initialize"
  puts "end"
end

def print_tail
  puts "end"
end

def adapt_word_or_lemma(word_or_lemma)
  word_or_lemma.gsub!("*", ".*")
  word_or_lemma.gsub!("?", ".?")
  return word_or_lemma
end

def get_word_condition_string(value, index)
  word_or_lemma_string = nil
  if value != "_"
    if value =~ /^!(.*)/
      word_or_lemma_string = "(window[#{index}][0] !~ /^(#{adapt_word_or_lemma($1)})$/)"
    else
      word_or_lemma_string = "(window[#{index}][0] =~ /^(#{adapt_word_or_lemma(value)})$/)"
    end
  end
  return word_or_lemma_string
end

def get_lemma_condition_string(value, index)
  lemma_string = nil
  if value != "_"
    if value =~ /^!(.*)/
      lemma_string = "(!match_some_lemma(window[#{index}][2],\"#{$1}\"))"
    else
      lemma_string = "(match_some_lemma(window[#{index}][2],\"#{value}\"))"
    end
  end
  return lemma_string
end

def get_unit_condition_string(value, index)
  word_or_lemma_string = nil
  if value != "_"
    if value =~ /^!(.*)/
      word_or_lemma_string = "(window[#{index}][3] !~ /^(#{adapt_word_or_lemma($1)})$/)"
    else
      word_or_lemma_string = "(window[#{index}][3] =~ /^(#{adapt_word_or_lemma(value)})$/)"
    end
  end
  return word_or_lemma_string
end

def adapt_tag(tag)
  tag.gsub!("*", ".*")
  tag.gsub!("?", ".?")
  return tag
end

def get_tag_condition_string(tag, index)
  tag_string = nil
  if tag != "_"
    if tag =~ /^!(.*)/
      tag_string = "(window[#{index}][1] !~ /^(#{adapt_tag($1)})$/)"
    else
      tag_string = "(window[#{index}][1] =~ /^(#{adapt_tag(tag)})$/)"
    end
    #puts "tag_string: #{tag_string}"
    #elements = tag.split(/\|/)
    #tag_string = "("
    #index_aux = 1
    #elements.each do |element|
    #  tag_string = tag_string + " or " unless index_aux == 1
    #  tag_string = tag_string + "tag#{index} =~ /#{adapt_tag(element)}/"
    #  index_aux = index_aux + 1
    #end
    #tag_string = tag_string + ")"
  end
  return tag_string
end

def print_component_condition(component, index)
  elements = component.split(/,/)
  word = elements[0]
  tag = elements[1]
  lemma = elements[2]
  unit = elements[3]
  breaking_point = elements[4]

  #puts "\n\nword:#{word}, tag:#{tag}, lemma:#{lemma}, unit:#{unit}"

  word_string = get_word_condition_string(word, index)
  tag_string = get_tag_condition_string(tag, index)
  lemma_string = get_lemma_condition_string(lemma, index)
  unit_string = get_unit_condition_string(unit, index)

  # puts "\n\nword_string: #{word_string}, tag_string: #{tag_string}, lemma_string: #{lemma_string}, unit_string: #{unit_string}"

  first_element = false
  if word_string
    print word_string
    first_element = true
  end
  if tag_string
    print " and " if first_element
    print tag_string
    first_element = true
  end
  if lemma_string
    print " and " if first_element
    print lemma_string
    first_element = true
  end
  if unit_string
    print " and " if first_element
    print unit_string
  end

  if breaking_point == nil
    return false
  else
    return true
  end
end

def print_pruning_rule(line)
  index = 0
  puts "\# RULE: #{line}"
  print "if "
  components = line.split(/\t/)
  index_breaking_point = 0
  components.each do |component|
    print " and " unless index == 0
    breaking_point = print_component_condition(component, index)
    index = index + 1
    index_breaking_point = index if breaking_point
  end
  if index_breaking_point == 0
    STDERR.puts "index_breaking_point = 0!!! for rule #{line}"
    exit 1
  end
  print "\n"
  # puts "STDERR.puts \"rejected by RULE #{line}\"" # Important line for debugging
  puts "return #{index_breaking_point}"
  puts "end"
end

# main

print_head

puts "def process(window)"
# puts "STDERR.puts print_window(window)" # Important line for debugging
while line = STDIN.gets
  line.chomp!
  unless line =~ /^\#/ or line.empty?
    #STDERR.puts "line:#{line}"
    print_pruning_rule(line)
  end
end
puts "return 0"
puts "end"

puts "private"

puts "def match_some_lemma (lemmas, string)"
puts "  lemmas.each do |lemma|"
puts "    if lemma =~ /^(\#\{string\})$/"
puts "      return true"
puts "    end"
puts "  end"
puts "  return false"
puts "end"
puts "end"

puts "def print_window(window)"
puts "  window.each do |element|"
puts "    if element != nil"
puts "      STDERR.print \"(\#{element[0]}/\#{element[1]}/\#{element[2]}/\#{element[3]})\""
puts "    else"
puts "      STDERR.print \"(empty/empty/empty/empty)\""
puts "    end"
puts "  end"
puts "  STDERR.puts \"\""
puts "end"
