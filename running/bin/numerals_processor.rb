# -*- coding: utf-8 -*-
require_relative 'database_wrapper.rb'

class NumeralsProcessor

  def initialize(sentence, dw)
    @sentence = sentence
    @dw = dw
    @variables = Hash.new
    results = @dw.get_numerals_values
    results.each do |result|
      case result[0]
      when "tags_for_numbers"
        @variables[result[0]] = result[1].split(/ /)
      else
        @variables[result[0]] = result[1]
      end
    end
  end
  
  def process
    # TODO: ordinals can't be joined: primer segundo must be separated
    # IDEA: Treat the same way than cardinals (generated lexicon)
    # process_ordinals
    process_numbers
    process_cardinals
  end

  private

  def process_ordinals
    token = @sentence.first_token.next
    while token.token_type != :end_sentence
      if (token.token_type == :standard) and (!token.tagged?)
        if is_potential_ordinal(token)
          last_token = get_ordinal_end(token)
          unless last_token == token
            token = join_and_tag_ordinal(token, last_token)
          end
        end
      elsif token.token_type == :begin_alternative
        while token.token_type != :end_alternative
          token = token.next
        end
      end
      token = token.next
    end
  end
  
  def process_numbers
    token = @sentence.first_token.next
    while token.token_type != :end_sentence
      if (token.token_type == :standard) and (!token.tagged?)
        if is_number(token.text)
          if token.text[token.text.length-1,1] == "%"
            token.text.chop!
            token.add_tag_lemma_emission(@variables["percentage_number_tag"], token.text, token.text, 0.0, false)
            new_token = Token.new(@sentence.text, "%", :standard, token.from, token.to)
            #new_token.add_tag_lemma_emission(@variables["percentage_symbol_tag"],"%",0.0, false)
            token.nexts.keys.each do |token_aux|
              token_aux.reset_prevs
              token_aux.add_prev(new_token)
            end
            new_token.replace_nexts(token.nexts)
            new_token.add_prev(token)
            token.reset_nexts
            token.add_next(new_token)
          else
            @variables["tags_for_numbers"].each do |tag|
              token.add_tag_lemma_emission(tag, token.text, token.text, 0.0, false)
            end
            process_percent_continuation(token)
          end
        end
      elsif token.token_type == :begin_alternative
        while token.token_type != :end_alternative
          token = token.next
        end
      end
      token = token.next
    end
  end
  
  def process_cardinals
    process_lexicon_cardinals
    process_thousands_cardinals
  end
  
  def process_lexicon_cardinals
   token = @sentence.first_token.next
    while token.token_type != :end_sentence
      #puts "Processing token lexicon: #{token.text}"
      if (token.token_type == :standard) and (!token.tagged?)
        ids = @dw.get_cardinals_match(token.text, 1, nil)
        unless ids.empty?
          start_token = token
          end_token = nil
          cardinal = token.text
          def_ids = @dw.get_cardinal_ids(cardinal)
          end_token = token unless def_ids.empty? # Cardinal detected
          
          ids_index = 2
          token = token.next
          while token.token_type == :standard
            new_ids = @dw.get_cardinals_match(token.text, ids_index, ids)
            if new_ids.empty?
              break
            else # We can follow a cardinal
              cardinal = cardinal + " #{token.text}"
              new_def_ids = @dw.get_cardinal_ids(cardinal)
              unless new_def_ids.empty? # Longer cardinal detected
                end_token = token
                def_ids = new_def_ids
              end
            end
            token = token.next
            ids_index = ids_index + 1
          end
          if end_token != nil
            join_lexicon_cardinal(start_token, end_token)
            token = end_token
          else
            token = start_token
          end
        end # from unless ids.empty?
      elsif token.token_type == :begin_alternative
        while token.token_type != :end_alternative
          token = token.next
        end
        #token = token.next
      end
      token = token.next if token.token_type != :end_sentence
    end # from while token.token_type != :end_sentence
  end
  
  def process_thousands_cardinals
    token = @sentence.first_token.next
    while token.token_type != :end_sentence
      #puts "token:#{token.text}"
      if token.token_type == :standard
        if token.text == @variables["multiword_link"]
          from = token
          to = token
        
          prev_token_bool = false
          prev_token = token.prev
          prev_result = nil
          if prev_token.token_type == :standard
            prev_result = @dw.get_cardinal_tags_lemmas(prev_token.text)
            unless (prev_result.empty? or prev_token.text == "un")
              from = prev_token
              prev_token_bool = true
            end
          end
          
          next_token_bool = false
          next_token = token.next
          next_result = nil
          if next_token.token_type == :standard
            next_result = @dw.get_cardinal_tags_lemmas(next_token.text)
            unless next_result.empty?
              to = next_token
              next_token_bool = true
            end
          end
          #puts "prev_token_bool:#{prev_token_bool} next_token_bool:#{next_token_bool}"
          #puts "from:#{from.text} to:#{to.text}"
          if from != to
            tags_prev = Array.new
            lemmas_prev = Array.new
            if prev_token_bool
              prev_result.each do |result|
                tags_prev << result[0]
                lemmas_prev << result[1]
              end
            end
          
            tags_next = Array.new
            lemmas_next = Array.new
            if next_token_bool
              next_result.each do |result|
                tags_next << result[0]
                lemmas_next << result[1]
              end
            end
          
            #puts "tags_prev: #{tags_prev} tags_next:#{tags_next}"
            tags = nil
            lemma = nil
            if !tags_prev.empty? and !tags_next.empty?
              tags = combine_tags_thousands(tags_prev,tags_next)
            elsif !tags_prev.empty?
              tags = tags_prev
              lemma = combine_lemmas_thousands(lemmas_prev, lemmas_next)
            elsif !tags_next.empty?
              tags = tags_next
            end
            lemma = combine_lemmas_thousands(lemmas_prev, lemmas_next)
            join_thousands_cardinal(from, to, tags, lemma, lemma)
          end
        end # from if token.text == @variables["multiword_link"]
      end # from if token.token_type == :standard
      token = token.next if token.token_type != :end_sentence
    end # from while
  end
  
  def gender(etqs)
    gender_letter = nil
    gender_letter_old = nil
    etqs.each do |etq|
      if etq[0,1] == 'N'
        gender_letter = etq[3]
      elsif etq[0,1] == 'S'
        gender_letter = etq[2]
      end
      return nil if (gender_letter_old != nil) and (gender_letter != gender_letter_old)
      gender_letter_old = gender_letter
    end
    return gender_letter
  end
  
  def combine_tags_thousands(etqs1, etqs2)
    gender1 = gender(etqs1)
    gender2 = gender(etqs2)
    if gender1 != nil and gender2 != nil and gender1 != gender2
      # gender discordance is possible in real texts.
      etqsjoin = Array.new
      etqsjoin.concat(etqs1)
      etqsjoin.concat(etqs2)
      return etqsjoin
      #return nil
    end
    return etqs2 if gender1 == nil
    #return etqs1 if gender2 == nil
    return etqs1
  end
  
  def combine_lemmas_thousands(lemmas1, lemmas2)
    if lemmas1.empty?
      lemma = "mil " + lemmas2[0]
    elsif lemmas2.empty?
      lemma = lemmas1[0] + " mil"
    else
      lemma = lemmas1[0] + " mil " + lemmas2[0]
    end
    return lemma
  end
  
  def join_cardinal(from, to)
    token = from
    
    if from != to
      new_token_from = from.from
      new_token_to = to.to
      new_token_text = token.text
      token = token.next
      while token != to
        new_token_text << " "
        new_token_text << token.text
        token = token.next
      end
      new_token_text << " "
      new_token_text << token.text
      new_token = Token.new(@sentence.text, new_token_text, :standard, new_token_from, new_token_to)
      new_token.replace_prevs(from.prevs)
      new_token.replace_nexts(to.nexts)
      from.prev.reset_nexts
      from.prev.add_next(new_token)
      to.next.reset_prevs
      to.next.add_prev(new_token)
      token = new_token
    end
    return token
  end
  
  def join_lexicon_cardinal(from, to)
    #puts "joining lexicon cardinal from:#{from.text} to #{to.text}"
    token = from
    token = join_cardinal(from, to) if from != to
    
    # First, we add tags included in the lexicon
    inside_lexicon = false
    results = @dw.get_emissions_info(token.text, nil)
    results.each do |result|
      inside_lexicon = true
      tag = result[0]
      lemma = result[1]
      hiperlemma = result[2]
      log_b = Float(result[3])
      token.add_tag_lemma_emission(tag, lemma, hiperlemma, log_b, false)
    end

    # If word is inside lexicon, we don't include cardinals tags because
    # we cannot combine emission frequencies (0.0 is the greatest value)
    unless inside_lexicon
      # Next, tags not included in lexicon
      results = @dw.get_cardinal_tags_lemmas(token.text)
      results.each do |result|
        tag = result[0]
        lemma = result[1]
        hiperlemma = result[2]
        token.add_tag_lemma_emission(tag, lemma, hiperlemma, 0.0, false)
      end
      process_percent_continuation(token)
    end
  end
  
  def join_thousands_cardinal(from, to, tags, lemma, hiperlemma)
    #puts "joining lexicon cardinal from:#{from.text} to #{to.text}"
    token = join_cardinal(from, to)
    tags.each do |tag|
      token.add_tag_lemma_emission(tag, lemma, hiperlemma, 0.0, false)
    end
    process_percent_continuation(token)
  end
  
  def process_percent_continuation(token)
    next_token = token.next
    value = @variables["percentage_idiom"]
    if next_token.token_type == :standard
      if next_token.text == @variables["percentage_idiom"]
        token.to = next_token.to
        next_token.from = token.from
      end
    end
  end
  
  def is_potential_ordinal(token)
    results = @dw.get_emissions_info(token.text, nil)
    results.each do |result|
      if result[0] =~ /#{@variables["ordinal_tag"]}/
        return true
      end
    end
    return false
  end
  
  def get_ordinal_end(token)
    last_token = token
    while token.token_type == :standard and is_potential_ordinal(token) and !(token.tagged?)
      last_token = token
      token = token.next
    end
    return last_token
  end
  
  def join_and_tag_ordinal(from, to)
    #puts "Joining ordinal from:#{from.text} to:#{to.text}"
    token = from 
    if from != to
      lemma = nil
      results = @dw.get_emissions_info(token.text, nil)
      results.each do |result|
        if result[0] =~ /#{@variables["ordinal_tag"]}/
          lemma = result[1]
        end
      end
      new_token_from = from.from
      new_token_to = to.to
      new_token_text = token.text
      token = token.next
      while token != to
        new_token_text << " "
        new_token_text << token.text
        results = @dw.get_emissions_info(token.text, nil)
        results.each do |result|
          if result[0] =~ /#{@variables["ordinal_tag"]}/
            lemma << " "
            lemma << result[1]
            break
          end
        end
        token = token.next
      end
      new_token_text << " "
      new_token_text << token.text
      results = @dw.get_emissions_info(token.text, nil)
      results.each do |result|
        if result[0] =~ /#{@variables["ordinal_tag"]}/
          lemma << " "
          lemma << result[1]
          break
        end
      end
      new_token = Token.new(@sentence.text, new_token_text, :standard, new_token_from, new_token_to)
      # We add the numerals related tags of the last ordinal.
      results = @dw.get_emissions_info(to.text, nil)
      results.each do |result|
        if result[0] =~ /#{@variables["ordinal_tag"]}/
          new_token.add_tag_lemma_emission(result[0], lemma, lemma, Float(result[3]), false)
        end
      end
      new_token.replace_prevs(from.prevs)
      new_token.replace_nexts(to.nexts)
      from.prev.reset_nexts
      from.prev.add_next(new_token)
      to.next.reset_prevs
      to.next.add_prev(new_token)
      token = new_token
    end
    return token
  end
  
  def is_number(text)
    # if text =~ /^[+-]?[0-9]+[.,\/:]?[0-9]*[%]?$/ old
    if text =~ /^[+-]?[0-9]+([.,\/:' ][0-9]+)*[%]?$/
      return true
    end
    return false
  end
  
end
  
