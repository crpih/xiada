# -*- coding: utf-8 -*-
require_relative "../bin/database_wrapper.rb"
require_relative "../../lib/string_utils.rb"
require_relative "../bin/enclitics_processor_custom.rb"

class EncliticsProcessor
  def initialize(sentence, dw, enclitics_hash)
    @sentence = sentence
    @dw = dw
    @enclitics_hash = enclitics_hash
    xiada_profile = ENV["XIADA_PROFILE"]
    @enclitics_processor_custom = EncliticsProcessorCustom.new(@sentence, @dw, @enclitics_hash)
    case xiada_profile
    when "galician_xiada"
      @enclitics_processor_custom.extend(EncliticsProcessorCustomGalicianXiada)
    end
  end

  def process
    token = @sentence.first_token.next
    process_recursive(token, 1, false)
  end

  private

  def process_recursive(token, way, inside_alternative) # modified ???
    #puts "processing token:#{token.text}, way:#{way}, type:#{token.token_type} tagged:#{token.tagged?}"
    if token.token_type != :end_sentence
      if token.token_type == :standard
        if !token.tagged?
          try_enclitics(token, inside_alternative)
        end
        process_recursive(token.next, way, inside_alternative)
      elsif token.token_type == :begin_alternative
        # Follow all ways recursively
        way = 1
        token.nexts.keys.each do |token_aux|
          process_recursive(token_aux, way, true)
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

  def try_enclitics(token, inside_alternative)
    # STDERR.puts "try_enclitics(#{token.text})"
    some_valid = false
    prev_token = token.prev
    next_token = token.next
    begin_alternative_token = Token.new(@sentence.text, nil, :begin_alternative, token.from, token.to)
    end_alternative_token = Token.new(@sentence.text, nil, :end_alternative, token.from, token.to)
    begin_alternative_token.qualifying_info = token.qualifying_info.clone
    end_alternative_token.qualifying_info = token.qualifying_info.clone
    word = token.text
    max_index = word.length - 2
    (0..max_index).each do |index|
      left = word[0, index + 1]
      right = word[index + 1, max_index - index + 1]
      left_tags = @dw.get_enclitic_verbs_roots_tags(left)
      left_tags_string = left_tags.join(" ")
      unless left_tags.empty? or !@dw.enclitic_combination_exists?(right)
        result = validate_decomposition(left, left_tags_string, right)
        valid = result[0]
        verb_part = result[1]
        enclitic_part = result[2]
        verb_tags = result[3]
        if valid
          some_valid = true
          # Valid enclitics decomposition was found
          # STDERR.puts "VALID DECOMPOSITION: #{token.text}"
          # STDERR.puts "verb_part: #{verb_part}"
          # STDERR.puts "enclitic_part: #{enclitic_part}"
          # STDERR.puts "verb_tags: #{verb_tags}"
          # verb_part processing
          # pending: solution for non recovery mode (spanish)???
          recovery = true
          relevant_verb_part_tokens = nil
          if recovery
            relevant_verb_part_tokens = @enclitics_processor_custom.restore_source_form(verb_part, verb_tags, enclitic_part, syllable_count(enclitic_part), begin_alternative_token, end_alternative_token, token.from, token.to, token)
          end

          # enclitic_part processing
          enclitics_processing(verb_part, relevant_verb_part_tokens, enclitic_part, begin_alternative_token, end_alternative_token, token.from, token.to, token)
          #if inside_alternative
          #  token_aux = next_token
          #  prev_tokens = end_alternative_token.prevs.keys
          #  while token_aux.token_type != :end_alternative
          #    new_prev_tokens = Array.new
          #    prev_tokens.each do |prev_token|
          #      prev_token.reset_nexts
          #      new_token = Token.new(@sentence.text, token_aux.text, token_aux.token_type, token_aux.from, token_aux.to)
          #      new_token.qualifying_info = token.qualifying_info.clone
          #      prev_token.add_next(new_token)
          #      new_token.add_prev(prev_token)
          #      prev_token = new_token
          #      new_prev_tokens << new_token
          #    end
          #    prev_tokens = new_prev_tokens
          #    token_aux = token_aux.next
          #  end
          #  end_alternative_token.reset_prevs
          #  prev_tokens.each do |prev_token|
          #    prev_token.add_next(end_alternative_token)
          #    end_alternative_token.add_prev(prev_token)
          #  end
          #end
        end # from if valid
      end # from unless
    end # from 0..max_index
    if some_valid
      # insert created new ways inside Sentence structure
      insert_enclitic_alternatives(token, inside_alternative, begin_alternative_token, end_alternative_token)
    end
  end

  # Function which process the enclitic part and create necessary
  # tokens linked to de verb_part(s) one(s)
  def enclitics_processing(verb_part, relevant_verb_part_tokens, enclitic_part, begin_alternative_token, end_alternative_token, from, to, token)
    #STDERR.puts "enclitics_processing verb_part: #{verb_part}, enclitic_part: #{enclitic_part}"
    end_alternative_token.reset_prevs
    relevant_verb_part_tokens.each do |relevant_verb_part_token|
      begin_alternative_token.add_next(relevant_verb_part_token)
      relevant_verb_part_token.add_prev(begin_alternative_token)
      prev_token = relevant_verb_part_token

      enclitic_elements = split_elements(enclitic_part)
      enclitics = split_enclitics(enclitic_elements)
      enclitics_forms = enclitics[0]
      enclitics_tags = enclitics[1]
      enclitics_lemmas = enclitics[2]

      new_token = nil
      enclitics_forms.each_index do |index|
        result = filter_tags_enclitic(verb_part, enclitics_forms, enclitics_forms[index], enclitics_tags[index], enclitics_lemmas[index], index)
        enclitic = result[0]
        tags = result[1]
        lemmas = result[2]
        hiperlemmas = result[3]

        #STDERR.puts "enclitic: #{enclitic}"
        #STDERR.puts "tags: #{tags}"
        #STDERR.puts "lemmas: #{lemmas}"
        new_token = Token.new(@sentence.text, enclitic, :standard, from, to)
        new_token.qualifying_info = token.qualifying_info.clone
        #STDERR.puts "getting info, enclitic:#{enclitic}, tags:#{tags}"
        infos = @dw.get_emissions_info(enclitic, tags.split(" "))
        infos.each do |info|
          tag_value = info[0]
          lemma = info[1]
          hiperlemma = info[2]
          log_b = Float(info[3])
          #puts "adding tag:#{tag_value}"
          new_token.add_tag_lemma_emission(tag_value, lemma, hiperlemma, log_b, false)
        end
        prev_token.reset_nexts
        prev_token.add_next(new_token)
        new_token.add_prev(prev_token)
        prev_token = new_token
      end
      prev_token.add_next(end_alternative_token)
      end_alternative_token.add_prev(prev_token)
    end
  end

  # Function which process the enclitic part and create necessary
  # tokens linked to de verb_part(s) one(s)
  def enclitics_processing_orig(verb_part, relevant_verb_part_tokens, enclitic_part, begin_alternative_token, end_alternative_token, from, to, token)
    # puts "enclitics_processing verb_part: #{verb_part}, enclitic_part: #{enclitic_part}"
    #prev_tokens = end_alternative_token.prevs.keys
    prev_tokens = relevant_verb_part_tokens
    enclitic_elements = split_elements(enclitic_part)
    #puts "enclitic_elements"
    #enclitic_elements.each do |element|
    #  puts "  --#{element}--"
    #end
    enclitics = split_enclitics(enclitic_elements)

    enclitics_forms = enclitics[0]
    enclitics_tags = enclitics[1]
    enclitics_lemmas = enclitics[2]

    #puts "enclitics_forms"
    #enclitics_forms.each do |enclitic_form|
    #  puts "  --#{enclitic_form}--"
    #end

    #puts "enclitics_tags"
    #enclitics_tags.each do |enclitic_tags|
    #  puts "  --#{enclitic_tags}--"
    #end

    #puts "enclitics_lemmas"
    #enclitics_lemmas.each do |enclitic_lemma|
    #  puts "  --#{enclitic_lemma}--"
    #end

    new_token = nil
    enclitics_forms.each_index do |index|
      result = filter_tags_enclitic(verb_part, enclitics_forms, enclitics_forms[index], enclitics_tags[index], enclitics_lemmas[index], index)
      enclitic = result[0]
      tags = result[1]
      lemmas = result[2]
      hiperlemmas = result[3]
      new_prev_tokens = Array.new
      prev_tokens.each do |prev_token|
        #puts "enclitic: #{enclitic}"
        #puts "tags: #{tags}"
        #puts "lemmas: #{lemmas}"
        new_token = Token.new(@sentence.text, enclitic, :standard, from, to)
        new_token.qualifying_info = token.qualifying_info.clone
        #puts "getting info, enclitic:#{enclitic}, tags:#{tags}"
        infos = @dw.get_emissions_info(enclitic, tags.split(" "))
        infos.each do |info|
          tag_value = info[0]
          lemma = info[1]
          hiperlemma = info[2]
          log_b = Float(info[3])
          #puts "adding tag:#{tag_value}"
          new_token.add_tag_lemma_emission(tag_value, lemma, hiperlemma, log_b, false)
        end
        prev_token.reset_nexts
        prev_token.add_next(new_token)
        new_token.add_prev(prev_token)
        new_token.add_next(end_alternative_token)
        new_prev_tokens << new_token
      end
      prev_tokens = new_prev_tokens
    end

    #end_alternative_token.reset_prevs
    prev_tokens.each do |prev_token|
      prev_token.add_next(end_alternative_token)
      prev_token.nexts_ignored = token.nexts_ignored.dup
      end_alternative_token.add_prev(prev_token)
    end
  end

  # Function which determines if a verb_part/enclitic_part decomposition is valid
  # It returns an array of four elements:
  # 1) Boolean which indicates if it is a valid verb_part/enclitic_part decomposition
  # 2) verb_part
  # 3) enclitic_part
  # 4) A string with space separated valid verb tags
  def validate_decomposition(verb_part, verb_tags, enclitic_part)
  # validate_decomposition verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
    check_default = true
    if verb_tags == nil or verb_tags.empty?
      result = [false, nil, nil, nil]
      return result
    else
      result = [true, verb_part, enclitic_part, verb_tags]
      return result
    end
  end # from def validate_decomposition

  # Function which filters the tags of an enclitic within a decomposition sequence
  # It return an array of three elements:
  # 1) The form of the enclitic, which could be changed.
  # 2) A string with space separated valid enclitic tags
  # 3) A string with space separated corresponding lemmas
  def filter_tags_enclitic(verb_part, enclitics, enclitic, enclitic_tags, enclitic_lemmas, index)
    if enclitic_tags == nil or enclitic_tags.empty?
      result = [nil, nil]
    else
      result = [enclitic, enclitic_tags, enclitic_lemmas]
    end
    return result
  end # from def filter_tags_enclitic

  # This function returns an array of enclitics (or enclitics with contraction), that is,
  # it returns the entries in enclitics_hash to be used to process each "portion" of
  # enclitic_part
  def split_elements(enclitic_part)
    #puts "split_element enclitic_part:#{enclitic_part}"
    result = Array.new
    start_index = 0
    start_index_aux = 0
    while (start_index < enclitic_part.length)
      enclitic = nil
      substr = nil
      #puts "start_index:#{start_index}"
      (start_index..enclitic_part.length - 1).each do |index|
        #puts "index:#{index}"
        substr = enclitic_part[start_index, index - start_index + 1]
        #puts "substr:#{substr}"
        unless @enclitics_hash[substr] == nil
          enclitic = substr
          start_index_aux = index + 1
          #puts "selected_index: #{index} start_index_aux:#{start_index_aux}"
        end
      end
      #puts "adding enclitic: #{enclitic}"
      result << enclitic
      start_index = start_index_aux
    end
    return result
  end

  # Function which splits all enclitics components of a sequence
  def split_enclitics(enclitic_elements)
    enclitics = Array.new
    tags = Array.new
    lemmas = Array.new
    component_index = 0
    enclitic_elements.each do |element|
      values_array = @enclitics_hash[element]
      values_array.each do |component|
        component.each_index do |index|
          if index == 0
            form = component[index]
            enclitics << form
          else
            tags_lemmas = component[index]
            tags_lemmas.each do |tag_lemma|
              tag = tag_lemma[0]
              lemma = tag_lemma[1]
              if tags[component_index] == nil
                tags[component_index] = tag
                lemmas[component_index] = lemma
              else
                tags[component_index] << " " << tag
                lemmas[component_index] << " " << lemma
              end
            end # from tags_lemmas.each
          end # from if index == 0
        end # from component.each_index
        component_index = component_index + 1
      end # from values_array.each
    end # from enclitic_elements.each
    result = Array.new
    result << enclitics << tags << lemmas
    return result
  end

  def insert_enclitic_alternatives_basic(token, inside_alternative, begin_alternative_token, end_alternative_token)
    prev_token = token.prevs.keys.first
    next_token = token.nexts.keys.first
    #STDERR.puts "prev_token:#{prev_token.text}"
    #STDERR.puts "next_token:#{next_token.text}"

    prev_token.remove_next(token)
    #token.remove_prev(prev_token)

    next_token.remove_prev(token)
    #token.remove_next(next_token) # Old token can't be unlinked because of the main recursive processing function

    prev_token.add_next(begin_alternative_token.nexts.keys.first)
    #STDERR.puts "prev_token.next: #{begin_alternative_token.nexts.keys.first.text}"

    begin_alternative_token.nexts.keys.first.reset_prevs
    begin_alternative_token.nexts.keys.first.add_prev(prev_token)

    next_token.add_prev(end_alternative_token.prevs.keys.first)
    #STDERR.puts "next_token.prev: #{end_alternative_token.prevs.keys.first.text}"
    end_alternative_token.prevs.keys.first.reset_nexts
    end_alternative_token.prevs.keys.first.add_next(next_token)

    begin_alternative_token.reset_nexts
    end_alternative_token.reset_prevs
  end

  def insert_enclitic_alternatives(token, inside_alternative, begin_alternative_token, end_alternative_token)
    # STDERR.puts "insert_enclitic_alternatives: token:#{token.text}, inside_alternative: #{inside_alternative}"
    preserve_source_token = false

    results = @dw.get_emissions_info(token.text, nil)
    preserve_source_token = true unless results.empty?
    if begin_alternative_token.nexts.size == 1 and !preserve_source_token
      insert_enclitic_alternatives_basic(token, inside_alternative, begin_alternative_token, end_alternative_token)
    elsif inside_alternative
      #puts "inside_alternative"
      start_point_token = token
      before_start_point = token
      while start_point_token.token_type != :begin_alternative
        before_start_point = start_point_token
        start_point_token = start_point_token.prev
      end

      finish_point_token = token
      before_finish_point = token
      while finish_point_token.token_type != :end_alternative
        before_finish_point = finish_point_token
        finish_point_token = finish_point_token.next
      end

      unless preserve_source_token
        before_start_point.reset_prevs
        before_finish_point.reset_nexts
        start_point_token.remove_next(before_start_point)
        finish_point_token.remove_prev(before_finish_point)
      end
      #puts "adding all ways"
      add_all_ways(begin_alternative_token, start_point_token, finish_point_token)
      #puts "end adding all ways"
      begin_alternative_token.reset_nexts
      end_alternative_token.reset_prevs
    else
      prev_token = token.prev
      next_token = token.next
      prev_token.reset_nexts
      next_token.reset_prevs
      start_point_token = begin_alternative_token
      finish_point_token = end_alternative_token

      if preserve_source_token
        # Insert token in alternatives
        token.reset_prevs
        token.reset_nexts
        begin_alternative_token.add_next(token)
        token.add_prev(begin_alternative_token)
        token.add_next(end_alternative_token)
        end_alternative_token.add_prev(token)
      end

      if begin_alternative_token.size_nexts == 1
        # Finally there are not alternatives
        start_point_token = begin_alternative_token.next
        start_point_token.reset_prevs
        finish_point_token = end_alternative_token.prev
        finish_point_token.reset_nexts

        begin_alternative_token.reset_nexts
        end_alternative_token.reset_prevs
      end

      # Insert new way in the sentence
      prev_token.add_next(start_point_token)
      start_point_token.add_prev(prev_token)
      next_token.add_prev(finish_point_token)
      finish_point_token.add_next(next_token)
    end
  end

  def add_all_ways(begin_alternative_token, start_point_token, finish_point_token)
    begin_alternative_token.nexts.keys.each do |token|
      add_way(token, start_point_token, finish_point_token)
    end
  end

  def add_way(first_alternative_token, start_point_token, finish_point_token)
    start_point_token.add_next(first_alternative_token)
    first_alternative_token.reset_prevs
    first_alternative_token.add_prev(start_point_token)
    prev_token = first_alternative_token
    first_alternative_token = first_alternative_token.next
    while first_alternative_token.token_type != :end_alternative
      prev_token = first_alternative_token
      first_alternative_token = first_alternative_token.next
    end
    prev_token.reset_nexts
    prev_token.add_next(finish_point_token)
    finish_point_token.add_prev(prev_token)
  end

  ##############################################################################
  # Private functions for enclitic_verbs_rules_compiler generated function
  ##############################################################################

  def syllable_count(enclitic_part)
    count = @dw.get_enclitics_number(enclitic_part)
    return count
  end

  ##############################################################################
  # Private functions for enclitic_pronouns_rules_compiler generated function
  ##############################################################################

  def replace_form(new_form)
    return (new_form)
  end

  def remove_initial_character(string, character)
    if string.start_with?("#{character}")
      return string[1, string.length - 1]
    end
  end
end
