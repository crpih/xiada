# -*- coding: utf-8 -*-
require_relative 'database_wrapper.rb'

class ContractionsProcessor

  def initialize(sentence, dw)
    @sentence = sentence
    @dw = dw
  end
  
  def process
    token = @sentence.first_token
    process_recursive(token, 1, false)
  end

  private
  
  def process_recursive(token, way, inside_alternative)
    #STDERR.puts "processing token:#{token.text}, way:#{way}, tagged:#{token.tagged?}"
    if token.token_type != :end_sentence
      if token.token_type == :standard
        unless token.tagged?
          contractions = get_contractions(token.text)
          if contractions.length != 0
            token = process_contraction(token,contractions, inside_alternative)
          end
        end
        process_recursive(token.next, 1, inside_alternative)
      elsif token.token_type == :begin_alternative
        # Follow all ways recursively
        way = 1
        token.nexts.keys.each do |token_aux|
          process_recursive(token_aux,way, true)
          way = way + 1
        end
      elsif token.token_type == :end_alternative
        # Join alternatives an follow only one way
        process_recursive(token.next, 1, false) if way == 1
      elsif token.token_type == :begin_sentence
        process_recursive(token.next, 1, inside_alternative)
      end
    end
  end
  
  def process_contraction(token, contractions, inside_alternative)
    # STDERR.puts "Processing contraction:#{token.text}"
    # STDERR.puts "Qualifying info: #{token.qualifying_info}"
    
    new_ways_words = Hash.new
    new_ways_begin = Array.new
    new_ways_end = Array.new
    contractions.each do |row|
      first_component_word = row[1]
      first_component_tag = row[2]
      first_component_lemma = row[3]
      first_component_hiperlemma = row[4]
      second_component_word = row[5]
      second_component_tag = row[6]
      second_component_lemma = row[7]
      second_component_hiperlemma = row[8]
      third_component_word = nil
      third_component_tag = nil
      third_component_lemma = nil
      third_component_hiperlemma = nil
      if row.length > 9
        third_component_word = row[9]
        third_component_tag = row[10]
        third_component_lemma = row[11]
        third_component_hiperlemma = row[12]
      end

      if new_ways_words.empty? or (!preexisting_way(first_component_word,
                                                    second_component_word,
                                                    third_component_word,
                                                    new_ways_words))
        new_token = Token.new(@sentence.text, first_component_word, :standard, token.from, token.to)
        new_token.qualifying_info = token.qualifying_info.clone
        new_token.add_tag_lemma_emission(first_component_tag, first_component_lemma, first_component_hiperlemma, nil, false)
        begin_token = new_token
        new_token_2 = Token.new(@sentence.text, second_component_word, :standard, token.from, token.to)
        new_token_2.qualifying_info = token.qualifying_info.clone
        new_token_2.add_tag_lemma_emission(second_component_tag, second_component_lemma, second_component_hiperlemma, nil, false)
        new_token.add_next(new_token_2)
        new_token_2.add_prev(new_token)
        end_token = new_token_2
        key = first_component_word + "&&&" + second_component_word
        new_token_3 = nil
        unless third_component_word == nil
          new_token_3 = Token.new(@sentence.text, third_component_word, :standard, token.from, token.to)
          new_token_3.qualifying_info = token.qualifying_info.clone
          new_token_3.add_tag_lemma_emission(third_component_tag, third_component_lemma, third_component_hiperlemma, nil, false)
          new_token_2.add_next(new_token_3)
          new_token_3.add_prev(new_token_2)
          end_token = new_token_3
          key = key + "&&&" + third_component_word
        end
        #add_ignored_tokens(end_token, token)
        new_ways_words[key] = new_token
        new_ways_begin << begin_token
        new_ways_end << end_token
      else
        # There exists a way with the same words. So we complete the tokens with
        # tag and lemma info.
        key = first_component_word + "&&&" + second_component_word
        key = key + "&&&" + third_component_word unless third_component_word == nil
        token_aux = new_ways_words[key]
        token_aux.add_tag_lemma_emission(first_component_tag, first_component_lemma, first_component_hiperlemma, nil, false)
        token_aux = token_aux.next
        token_aux.add_tag_lemma_emission(second_component_tag, second_component_lemma, second_component_hiperlemma, nil, false)
        unless token_aux.last
          token_aux = token_aux.next
          token_aux.add_tag_lemma_emission(third_component_tag, third_component_lemma, third_component_hiperlemma, nil, false)
        end
      end
    end # from contractions.each
    
    next_token = insert_ways(token, new_ways_begin, new_ways_end, inside_alternative)
    return next_token
  end
  
  def preexisting_way(first_component_word, second_component_word, third_component_word, new_ways_words)
    key = first_component_word + "&&&" + second_component_word
    key = key + "&&&" + third_component_word unless third_component_word == nil
    if new_ways_words[key] != nil
      return true
    else
      return false
    end    
  end
  
  def insert_ways(token, new_ways_begin, new_ways_end, inside_alternative)
    
    ways_number = 1
    token_info = @dw.get_emissions_info(token.text, nil)
    if token_info.empty?
      ways_number = 0
    end

    # By now it is not possible to regard lexicon entries which are
    # contractions if they are inside alternatives. => to be improved.

    ways_number = 0 if inside_alternative

    # We disconnect current token
    token.prevs.keys.each do |token_prev|
      token_prev.remove_next(token)
    end
    
    token.nexts.keys.each do |token_next|
      token_next.remove_prev(token)
    end
    
    ways_number = ways_number + new_ways_begin.length
    #puts "ways_number: #{ways_number}"
    
    if (ways_number > 1)
      begin_token = Token.new(@sentence.text, nil, :begin_alternative, token.from, token.to)
      end_token = Token.new(@sentence.text, nil, :end_alternative, token.from, token.to)
      begin_token.qualifying_info = token.qualifying_info.clone
      end_token.qualifying_info = token.qualifying_info.clone      
      last_token = end_token
      token.prevs.keys.each do |token_prev|
        #puts "Adding begin_alternative to token:#{token_prev.text} nexts"
        token_prev.reset_nexts
        token_prev.add_next(begin_token)
        begin_token.add_prev(token_prev)
      end
      new_ways_begin.each do |new_way_begin_token|
        begin_token.add_next(new_way_begin_token)
        #puts "Adding #{new_way_begin_token.text} to begin_alternative token nexts"
        new_way_begin_token.add_prev(begin_token)
      end
      
      token.nexts.keys.each do |token_next|
        #puts "Adding #{token_next.text} to end_alternative token nexts"
        token_next.reset_prevs
        token_next.add_prev(end_token)
        end_token.add_next(token_next)
      end
      new_ways_end.each do |new_way_end_token|
        #puts "Adding end_alternative to #{new_way_end_token.text} token nexts"
        end_token.add_prev(new_way_end_token)
        new_way_end_token.add_next(end_token)
      end
      # Reconnect current token as an alternative
      token.reset_prevs
      token.reset_nexts
      begin_token.add_next(token)
      token.add_prev(begin_token)
      end_token.add_prev(token)
      token.add_next(end_token)
      add_ignored_tokens(end_token, token) unless token.nexts_ignored.empty?
      token.nexts_ignored=Array.new
    else # There are not alternatives, only contraction is possible.
      last_token = new_ways_end[0]
      token.prevs.keys.each do |token_prev|
        new_ways_begin.each do |new_way_begin_token|
          token_prev.add_next(new_way_begin_token)
          new_way_begin_token.add_prev(token_prev)
        end
      end
      token.nexts.keys.each do |token_next|
        new_ways_end.each do |new_way_end_token|
          token_next.add_prev(new_way_end_token)
          new_way_end_token.add_next(token_next)
        end
      end
      add_ignored_tokens(last_token, token) unless token.nexts_ignored.empty?
    end
    #puts "Last token: #{last_token.text}"
    return last_token
  end

  def add_ignored_tokens(target_token, source_token)
    target_token.nexts_ignored = source_token.nexts_ignored.dup
  end

  def remove_ignored_tokens(target_token)
    target_token.nexts_ignored = Array.new
  end

  def get_contractions(token_text)
    @dw.get_contractions(token_text)
  end
end
  
