# -*- coding: utf-8 -*-
require_relative "../../lib/string_utils"

class EncliticsProcessor
  def initialize(tagger_config, enclitics_hash)
    @tagger_config = tagger_config
    @enclitics_hash = enclitics_hash
    @rule_matching = @tagger_config.enclitics_rule_matching
    @validate_decomposition = @tagger_config.enclitics_validate_decomposition
    @filter_tags = @tagger_config.enclitics_filter_tags
  end

  def process(sentence)
    token = sentence.first_token.next
    process_recursive(sentence, token, 1, false)
  end

  private

  def process_recursive(sentence, token, way, inside_alternative) # modified ???
    #puts "processing token:#{token.text}, way:#{way}, type:#{token.token_type} tagged:#{token.tagged?}"
    if token.token_type != :end_sentence
      if token.token_type == :standard
        if !token.tagged?
          try_enclitics(sentence, token, inside_alternative)
        end
        process_recursive(sentence, token.next, way, inside_alternative)
      elsif token.token_type == :begin_alternative
        # Follow all ways recursively
        way = 1
        token.nexts.keys.each do |token_aux|
          process_recursive(sentence, token_aux, way, true)
          way = way + 1
        end
      elsif token.token_type == :end_alternative
        # Join alternatives an follow only one way
        process_recursive(sentence, token.next, 1, false) if way == 1
      elsif token.token_type == :begin_sentence
        process_recursive(sentence, token.next, 1, inside_alternative)
      end
    end
  end

  def try_enclitics(sentence, token, inside_alternative)
    # STDERR.puts "try_enclitics(#{token.text})"
    some_valid = false
    prev_token = token.prev
    next_token = token.next
    begin_alternative_token = Token.new(sentence.text, nil, :begin_alternative, token.from, token.to)
    end_alternative_token = Token.new(sentence.text, nil, :end_alternative, token.from, token.to)
    begin_alternative_token.qualifying_info = token.qualifying_info.clone
    end_alternative_token.qualifying_info = token.qualifying_info.clone
    end_alternative_token.nexts_ignored = token.nexts_ignored.clone
    word = token.text
    max_index = word.length - 2
    (0..max_index).each do |index|
      left = word[0, index + 1]
      right = word[index + 1, max_index - index + 1]
      left_tags = @tagger_config.dw.get_enclitic_verbs_roots_tags(sentence.document_config, left)
      left_tags_string = left_tags.join(" ")
      unless left_tags.empty? or !@tagger_config.dw.enclitic_combination_exists?(right)
        result = @validate_decomposition.(left, left_tags_string, right) { |e| syllable_count(e) }
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
            relevant_verb_part_tokens = restore_source_form(sentence, verb_part, verb_tags, enclitic_part, syllable_count(enclitic_part), begin_alternative_token, end_alternative_token, token.from, token.to, token)
          end

          # enclitic_part processing
          enclitics_processing(sentence, verb_part, relevant_verb_part_tokens, enclitic_part, begin_alternative_token, end_alternative_token, token.from, token.to, token)
          #if inside_alternative
          #  token_aux = next_token
          #  prev_tokens = end_alternative_token.prevs.keys
          #  while token_aux.token_type != :end_alternative
          #    new_prev_tokens = Array.new
          #    prev_tokens.each do |prev_token|
          #      prev_token.reset_nexts
          #      new_token = Token.new(sentence.text, token_aux.text, token_aux.token_type, token_aux.from, token_aux.to)
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
  def enclitics_processing(sentence, verb_part, relevant_verb_part_tokens, enclitic_part, begin_alternative_token, end_alternative_token, from, to, token)
    #STDERR.puts "enclitics_processing verb_part: #{verb_part}, enclitic_part: #{enclitic_part}"
    end_alternative_token.reset_prevs
    relevant_verb_part_tokens.each do |relevant_verb_part_token|
      begin_alternative_token.add_next(relevant_verb_part_token)
      relevant_verb_part_token.add_prev(begin_alternative_token)
      prev_token = relevant_verb_part_token

      enclitics_forms, enclitics_tags, enclitics_lemmas = split_enclitics(enclitic_part)

      new_token = nil
      enclitics_forms.each_index do |index|
        result = @filter_tags.(verb_part, enclitics_forms, enclitics_forms[index], enclitics_tags[index], enclitics_lemmas[index], index)
        enclitic = result[0]
        tags = result[1]
        lemmas = result[2]
        hiperlemmas = result[3]

        #STDERR.puts "enclitic: #{enclitic}"
        #STDERR.puts "tags: #{tags}"
        #STDERR.puts "lemmas: #{lemmas}"
        infos = @tagger_config.dw.get_emissions_info(enclitic, tags.split(" "))

        # FIXME: Ugly hack to remove hyphen in enclitics for galician_xiada
        # These cases must be searched with the hyphen, but the token text must not have the hyphen.
        # WARNING: Do not mutate the string, since it causes unpredictable output for unknown reasons.
        enclitic = enclitic.delete_prefix('-')  if %w[-lo -la -los -las].include?(enclitic) && @tagger_config.profile == "galician_xiada"
        new_token = Token.new(sentence.text, enclitic, :standard, from, to)
        new_token.qualifying_info = token.qualifying_info.clone
        #STDERR.puts "getting info, enclitic:#{enclitic}, tags:#{tags}"
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
  def enclitics_processing_orig(sentence, verb_part, relevant_verb_part_tokens, enclitic_part, begin_alternative_token, end_alternative_token, from, to, token)
    # puts "enclitics_processing verb_part: #{verb_part}, enclitic_part: #{enclitic_part}"
    #prev_tokens = end_alternative_token.prevs.keys
    prev_tokens = relevant_verb_part_tokens
    enclitic_elements = split_elements(enclitic_part)
    #puts "enclitic_elements"
    #enclitic_elements.each do |element|
    #  puts "  --#{element}--"
    #end
    enclitics_forms, enclitics_tags, enclitics_lemmas = split_enclitics(enclitic_part)


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
      result = @filter_tags.(verb_part, enclitics_forms, enclitics_forms[index], enclitics_tags[index], enclitics_lemmas[index], index)
      enclitic = result[0]
      tags = result[1]
      lemmas = result[2]
      hiperlemmas = result[3]
      new_prev_tokens = Array.new
      prev_tokens.each do |prev_token|
        #puts "enclitic: #{enclitic}"
        #puts "tags: #{tags}"
        #puts "lemmas: #{lemmas}"
        new_token = Token.new(sentence.text, enclitic, :standard, from, to)
        new_token.qualifying_info = token.qualifying_info.clone
        #puts "getting info, enclitic:#{enclitic}, tags:#{tags}"
        infos = @tagger_config.dw.get_emissions_info(enclitic, tags.split(" "))
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


  # Function which splits the enclitic into a sequence of valid parts
  def split_elements(enclitic_part)
    return [] if enclitic_part.empty?

    combinations = @enclitics_hash.keys.filter_map do |key|
      next unless enclitic_part.start_with?(key)

      [key, *split_elements(enclitic_part[key.length..])]
    end

    # Valid combinations are those which sum of lengths is equal to the length of the enclitic
    # We return the first valid combination
    combinations.find { |c| c.sum(&:length) == enclitic_part.length }
  end

  # Function which splits all enclitics components of a sequence
  def split_enclitics(enclitic_part)
    parts = split_elements(enclitic_part)
    return [[], [], []] if parts.nil?

    parts.flat_map { |p| @enclitics_hash[p] }
         .map { |f, tls| [f, tls.map(&:first).join(" "), tls.map(&:last).join(" ")] }
         .transpose
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

    end_alternative_token.prevs.keys.first.nexts_ignored = end_alternative_token.nexts_ignored.clone
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

    results = @tagger_config.dw.get_emissions_info(token.text, nil)
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

  private

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
    count = @tagger_config.dw.get_enclitics_number(enclitic_part)
    return count
  end

  # This method was previously in EncliticsProcessorCustom
  def restore_source_form(sentence, verb_part, verb_tags, enclitic_part, enclitic_syllables_length, begin_alternative_token, end_alternative_token, token_from, token_to, token)
    #STDERR.puts "verb_part: #{verb_part}"
    final_recovery_words = Hash.new
    relevant_tokens = Array.new
    infos = @tagger_config.dw.get_enclitic_verb_roots_info(sentence.document_config, verb_part, verb_tags.split(" "))
    infos.each do |_root, tag_value, lemma, hiperlemma, extra|
      results = @tagger_config.dw.get_recovery_info(sentence.document_config, verb_part, tag_value, lemma, true)
      if results.empty?
        results = @tagger_config.dw.get_recovery_info(sentence.document_config, verb_part, tag_value, lemma, false)
      end
      if results.empty?
        STDERR.puts "WARNING: Reverse info for tag:#{tag_value} and lemma:#{lemma} not found. Searching for verb_part: #{verb_part}"
      end
      max_p_score = 0
      final_recovery_word = String.new(verb_part)
      final_recovery_tag = String.new(tag_value)
      final_recovery_lemma = String.new(lemma)
      final_recovery_hiperlemma = String.new(hiperlemma)
      final_recovery_log_b = -100 # To be changed ??? TODO
      # STDERR.puts "results.size: #{results.size}"
      results.each do |result|
        recovery_word = result[0]
        recovery_tag = result[1]
        recovery_lemma = result[2]
        recovery_hiperlemma = result[3]
        recovery_log_b = Float(result[4])
        # If there are several entries for the same tag and lemma, we
        # choose the word with the greater proximity score.
        new_recovery_word = @rule_matching.(verb_part, tag_value, enclitic_part, enclitic_syllables_length, extra, recovery_word)
        unless recovery_word == new_recovery_word
          final_recovery_word = new_recovery_word
          final_recovery_tag = recovery_tag
          final_recovery_lemma = recovery_lemma
          final_recovery_hiperlemma = recovery_hiperlemma
          final_recovery_log_b = recovery_log_b
          break
        else
          p_score = proximity_score(recovery_word, verb_part)
          # STDERR.puts "recovery_word:#{recovery_word}"
          # STDERR.puts "p_score:#{p_score}"
          if p_score >= max_p_score
            max_p_score = p_score
            final_recovery_word = recovery_word
            final_recovery_tag = recovery_tag
            final_recovery_lemma = recovery_lemma
            final_recovery_hiperlemma = recovery_hiperlemma
            final_recovery_log_b = recovery_log_b
          end
        end
      end
      if final_recovery_words[final_recovery_word] == nil
        new_token = Token.new(sentence.text, final_recovery_word, :standard, token_from, token_to)
        new_token.qualifying_info = token.qualifying_info.clone
        final_recovery_words[final_recovery_word] = new_token
        #begin_alternative_token.add_next(new_token)
        #new_token.add_prev(begin_alternative_token)
        #new_token.add_next(end_alternative_token)
        #end_alternative_token.add_prev(new_token)
        relevant_tokens << new_token
      end
      final_recovery_words[final_recovery_word].add_tag_lemma_emission(final_recovery_tag, final_recovery_lemma, final_recovery_hiperlemma, final_recovery_log_b, false)
    end
    return relevant_tokens
  end

  def proximity_score(recovery_word, verb_part)
    recovery_word_wt = StringUtils.without_tilde(recovery_word)
    verb_part_wt = StringUtils.without_tilde(verb_part)
    score = 0
    (0..recovery_word.length - 1).each do |index|
      recovery_word_letter = recovery_word[index]
      recovery_word_letter_wt = recovery_word[index]
      if index < verb_part.length
        verb_part_letter = verb_part[index]
        verb_part_letter_wt = verb_part_wt[index]
        if recovery_word_letter == verb_part_letter
          score = score + 2
        elsif recovery_word_letter_wt == verb_part_letter_wt
          score = score + 1
        end
      else
        score = score - 1
      end
    end
    return score
  end
end
