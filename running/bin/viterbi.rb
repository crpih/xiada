# -*- coding: utf-8 -*-
require_relative "../#{ENV["XIADA_PROFILE"]}/pruning_system.rb"
require_relative "../../lib/string_utils.rb"

class Viterbi
  EMPTY_TAG = "###"
  EMPTY_WORD = "###"
  WINDOW_SIZE = 5

  def initialize(dw)
    @dw = dw
    @tags = nil
    @pruning_system = PruningSystem.new
    @without_suffixes_words = Hash.new
  end

  def run(sentence)
    @sentence = sentence
    @tags = nil
    while @tags == nil
      initialize_step(sentence)
      # sentence.print(STDERR)
      recurrence_step(sentence)
      last_delta = finalize_step(sentence)
      #sentence.print(STDERR)
      without_suffixes_words_size = @without_suffixes_words.keys.size
      @tags = back_way_build(last_delta, true)
      without_suffixes_words_new_size = @without_suffixes_words.keys.size
      break if without_suffixes_words_size == without_suffixes_words_new_size
    end
    if @tags == nil
      # If @tags == nil it could be:
      # 1) There is some erroneous rule
      # 2) There is an error in a word but this error match a valid lexicon word
      # So, we show a warning and analice the sentence with pruning_rules disabled
      @without_suffixes_words = Hash.new
      STDERR.puts "WARNING: Sentence -- #{sentence.text} -- had to be analized without prunning rules"
      reset_viterbi(sentence)
      initialize_step(sentence)
      recurrence_step(sentence)
      last_delta = finalize_step(sentence)
      @tags = back_way_build(last_delta, false)
    end
    @some_info = some_info?
  end

  def print_best_way
    #STDERR.puts "PRINTING WAY"
    if @tags == nil
      STDERR.puts "ERROR: No valid way for this sentence"
      exit
    else
      @tags.each do |tag|
        if tag.token.token_type == :standard
          print "#{tag.token.text}\t#{tag.value}"
          if tag.lemmas.keys.empty?
            print "\t*"
          else
            print "\t#{tag.lemmas.keys[0]}\t#{tag.hiperlemmas[tag.lemmas.keys]}"
          end
          puts ""
        end
      end
    end
    puts ""
  end

  def get_best_way
    result = ""
    #STDERR.puts "PRINTING WAY"
    if @tags == nil
      STDERR.puts "ERROR: No valid way for this sentence"
      exit
    else
      @tags.each do |tag|
        if tag.token.token_type == :standard
          result = result + "#{tag.token.text}\t#{tag.value}"
          if tag.lemmas.keys.empty?
            result = result + "\t*"
          else
            lemma = tag.lemmas.keys[0]
            hiperlemma = tag.hiperlemmas[lemma]
            result += "\t#{lemma}\t#{tag.token.get_unit}\t#{tag.token.from}\t#{tag.token.to}"
            result += "/#{hiperlemma}" if hiperlemma!=nil && hiperlemma!="" && hiperlemma != lemma
          end
          result = result + "\t\t"
        end
      end
    end
    return result
  end

  def print_best_way_xml_with_alternatives(sentence_tag, expression_tag, expression_attributes, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                                           tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value, expression,
                                           qualifying_tag)
    if @tags == nil
      STDERR.puts "ERROR: No valid way for this sentence"
    else
      #puts @sentence.print
      puts "<#{sentence_tag}#{expression_attributes}>\n"
      puts "<#{expression_tag}>#{expression}</#{expression_tag}>\n"
      if @some_info
        puts "<#{analysis_tag}>"
        print_best_way_xml_with_alternatives_recursive(@sentence.first_token, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag, tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value, qualifying_tag)
        puts "</#{analysis_tag}>"
      end
      puts "</#{sentence_tag}>"
    end
  end

  def print_best_way_xml_without_alternatives(sentence_tag, expression_tag, expression_attributes, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag,
                                              constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value, expression,
                                              qualifying_tag)
    if @tags == nil
      STDERR.puts "ERROR: No valid way for this sentence"
    else
      #puts @sentence.print
      puts "<#{sentence_tag}#{expression_attributes}>\n"
      puts "<#{expression_tag}>#{expression}</#{expression_tag}>\n"
      if @some_info
        puts "<#{analysis_tag}>"
        print_best_way_xml_without_alternatives_recursive(@sentence.first_token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value, qualifying_tag)
        puts "</#{analysis_tag}>"
      end
      puts "</#{sentence_tag}>"
    end
  end

  private

  def reset_viterbi(sentence)
    reset_viterbi_token(sentence.first_token, 1)
  end

  def initialize_step(sentence)
    initialize_step_token(sentence.first_token, 1)
  end

  def recurrence_step(sentence)
    token = sentence.first_token.next
    while token != nil
      if token.token_type == :standard
        recurrence_step_token(token)
        token = token.next
      elsif token.token_type == :begin_alternative
        token.nexts.keys.each do |next_token|
          token = next_token
          while token.token_type != :end_alternative
            recurrence_step_token(token)
            token = token.next
          end
        end
      elsif token.token_type == :end_alternative
        token = token.next
      elsif token.token_type == :end_sentence
        recurrence_step_token(token)
        token = token.next
      end
    end
  end

  def reset_viterbi_token(token, way)
    # STDERR.puts "\ninitialization of token:#{token.text} type:#{token.token_type} from_viterby:#{token.from_viterbi} tagged:#{token.tagged}"
    if token != nil
      token.reset_viterbi
      if token.token_type == :standard
        initialize_step_token(token.next, way)
      elsif (token.token_type == :begin_sentence) or (token.token_type == :end_sentence)
        initialize_step_token(token.next, 1)
      elsif token.token_type == :begin_alternative
        way = 1
        token.nexts.keys.each do |token_aux|
          initialize_step_token(token_aux, way)
          way = way + 1
        end
      elsif token.token_type == :end_alternative
        initialize_step_token(token.next, 1) if way == 1
      end
    end
  end

  def initialize_step_token(token, way)
    #STDERR.puts "\ninitialization of token:#{token.text} type:#{token.token_type} from_viterbi:#{token.from_viterbi} tagged:#{token.tagged}"
    if token != nil
      if token.token_type == :standard
        #STDERR.puts "without_suffixes_words: #{@without_suffixes_words}"
        unless @without_suffixes_words[String.new(token.text)]
          #STDERR.puts "entra"
          results = @dw.get_tags_lemmas_emissions(token.text, token.tags.keys)
        else
          #STDERR.puts "WARNING: token #{token.text} is getting open tags"
          results = @dw.get_open_tags_lemmas_emissions(token.text)
        end
        results.each do |result|
          tag_value = result[0]
          lemma = result[1]
          hiperlemma = result[2]
          #STDERR.puts "tag_value:#{tag_value}, lemma:#{lemma}, hiperlemma:#{hiperlemma}"
          log_b = Float(result[3])
          #STDERR.puts "log_b:#{log_b}"
          token.add_tag_lemma_emission(tag_value, lemma, hiperlemma, log_b, true)
        end
        #STDERR.puts "calling initialize_step_token 1 with next:#{token.next.text}"
        initialize_step_token(token.next, way)
      elsif (token.token_type == :begin_sentence) or (token.token_type == :end_sentence)
        results = @dw.get_tags_lemmas_emissions(EMPTY_WORD, nil)
        results.each do |result|
          tag_value = result[0]
          lemma = result[1]
          hiperlemma = result[2]
          log_b = Float(result[3])
          token.add_tag_lemma_emission(tag_value, lemma, hiperlemma, log_b, true)
        end
        if token.token_type == :begin_sentence
          token.tags.values.each do |tag|
            tag.add_or_replace_delta(tag.emission + @dw.get_bigram_probability(EMPTY_TAG, EMPTY_TAG) + tag.emission, nil, 1, EMPTY_TAG)
          end
          #STDERR.puts "calling initialize_step_token 2 with next:#{token.next.text}"
          initialize_step_token(token.next, 1)
        end
        # STDERR.puts "exiting begin/end sentence"
      elsif token.token_type == :begin_alternative
        way = 1
        token.nexts.keys.each do |token_aux|
          # STDERR.puts "calling initialize_step_token 3 with next:#{token_aux.text}"
          initialize_step_token(token_aux, way)
          way = way + 1
        end
      elsif token.token_type == :end_alternative
        # STDERR.puts "calling initialize_step_token 4 with next:#{token.next.text}, way:#{way}"
        initialize_step_token(token.next, 1) if way == 1
      end
    end
  end

  def recurrence_step_token(token)
    if token != nil
      #STDERR.puts "\nrecurrence_token: #{token.text} token_type:#{token.token_type}"
      if (token.token_type == :standard) or (token.token_type == :end_sentence)

        #STDERR.puts "\nEVALUATING TOKEN:#{token.text} token_object:#{token}"
        token.tags.values.each do |tag|
          #STDERR.puts "Evaluating tag:#{tag.value} tag_object:#{tag}"
          #deltas_aux = Hash.new
          deltas = Hash.new
          prev_tokens = prev_tokens_calculation(token)
          prev_tokens.each do |prev_token|
            #puts "prev_token: #{prev_token.text} id: #{prev_token.token_id}"
            prev_tags = nil
            prev_tags = prev_tags_calculation(prev_token)
            prev_tags.each do |prev_tag|
              #puts "prev_tag: #{prev_tag.value}"
              #prev_tag.deltas.each do |prev_delta_tag, prev_delta|
              prev_delta = prev_tag.maximum_delta
              length = prev_delta.length
              #puts "prev_tag delta:#{prev_delta.value} length:#{length}"
              prev_prev_tokens = nil
              prev_prev_tokens = prev_prev_tokens_calculation(prev_token)
              prev_prev_tokens.each do |prev_prev_token|
                #puts "prev_prev_token: #{prev_prev_token.text}"
                prev_prev_tags = nil
                prev_prev_tags = prev_prev_tags_calculation(prev_prev_token)
                prev_prev_tags.each do |prev_prev_tag|
                  #puts "prev_prev_tag: #{prev_prev_tag.value}"

                  #puts "--- trigram:#{prev_prev_tag.value},#{prev_tag.value},#{tag.value}--"
                  #if @pruning_system.process(prev_prev_tag.token.text, prev_prev_tag.value, prev_prev_tag.lemmas.keys,
                  #                           prev_tag.token.text, prev_tag.value, prev_tag.lemmas.keys,
                  #                           token.text, tag.value, tag.lemmas.keys)
                  current_delta = prev_delta.value +
                                  @dw.get_trigram_probability(prev_prev_tag.value,
                                                              prev_tag.value,
                                                              tag.value)
                  #puts "calculating trigram: #{prev_prev_tag.value} #{prev_tag.value} #{tag.value}"
                  normalized_current_delta = current_delta / Math.log(length + 1)
                  #puts "trigram:#{prev_prev_tag.value},#{prev_tag.value},#{tag.value}"
                  #puts "probability:#{@dw.get_trigram_probability(prev_prev_tag.value,prev_tag.value,tag.value)}"
                  #puts "deltas_aux[#{length}]=#{deltas_aux[length]} prev_delta:#{prev_delta.value}"
                  if (deltas[prev_tag.value + prev_token.token_id.to_s()] == nil) or (normalized_current_delta > deltas[prev_tag.value + prev_token.token_id.to_s()].normalized_value)
                    deltas[prev_tag.value + prev_token.token_id.to_s()] = Delta.new(current_delta, prev_delta, length + 1, tag)
                    #puts "delta max-[#{length+1}]:#{deltas[length+1].value}, tag:#{tag.value}, prev_delta:#{deltas[length+1].prev_delta.value}, prev_tag:#{deltas[length+1].prev_delta.tag.value}"
                  end
                  #else
                  #  puts "FILTERING #{prev_prev_tag.value} #{prev_tag.value} #{tag.value}"
                  #end
                end # prev_prev_tags.each
              end # prev_prev_tokens.each
              #end # prev_tag.deltas.each
            end # prev_tags.each
          end #prev_tokens.each
          update_deltas(tag, deltas)
        end # token.tags
      end # if token.token_type
    end # from token != nil
  end

  def update_deltas(tag, deltas)
    #puts "update_deltas"
    deltas.each do |delta_tag_value, delta|
      length = delta.length
      #puts "length:#{length}, delta:#{delta.value}"
      if (tag.deltas[delta_tag_value] == nil) or (delta.normalized_value > tag.deltas[delta_tag_value].normalized_value)
        tag.add_or_replace_delta(delta.value + tag.emission, delta.prev_delta, length, delta.prev_delta.tag.value + delta.prev_delta.tag.token.token_id.to_s())
        #puts "Updating with values delta:#{delta.value + tag.emission} normalized:#{(delta.value + tag.emission) / delta.length} emission:#{tag.emission}\n"
      end
    end
    #puts "ORDERED DELTAS:"
    #tag.ordered_deltas.each do |delta|
    #  puts "delta normalized_value: #{delta.normalized_value}"
    #end
  end

  def prev_tokens_calculation(token)
    prev_tokens = token.prevs.keys
    # if prev_token match alternative one, then we have to go one more ago.
    while (prev_tokens.size == 1) and (prev_tokens.first.token_type == :begin_alternative or prev_tokens.first.token_type == :end_alternative)
      prev_tokens = prev_tokens.first.prevs.keys
    end

    #print "prev_tokens:"
    #prev_tokens.each do |p_token|
    #  print " #{p_token.text} type:#{p_token.token_type}"
    #end
    #print "\n"

    return prev_tokens
  end

  def prev_tags_calculation(prev_token)
    prev_tags = Array.new
    prev_token.tags.values.each do |tag_object|
      prev_tags << tag_object
    end

    #print "prev_tags:"
    #prev_tags.each do |p_tag|
    #  print " #{p_tag.value}"
    #end
    #print "\n"

    return prev_tags
  end

  def prev_prev_tokens_calculation(prev_token)
    prev_prev_tokens = prev_token.prevs.keys
    while (prev_prev_tokens.size == 1) and (prev_prev_tokens.first.token_type == :begin_alternative or prev_prev_tokens.first.token_type == :end_alternative)
      prev_prev_tokens = prev_prev_tokens.first.prevs.keys
    end

    if prev_prev_tokens.empty?
      prev_prev_token = Token.new(@sentence.text, EMPTY_WORD, :artificial, -1, -1)
      results = @dw.get_tags_lemmas_emissions(EMPTY_WORD, nil)
      results.each do |result|
        tag_value = result[0]
        lemma = result[1]
        hiperlemma = result[2]
        log_b = Float(result[3])
        prev_prev_token.add_tag_lemma_emission(tag_value, lemma, hiperlemma, log_b, true)
      end
      prev_prev_tokens << prev_prev_token
    end

    #print "------------prev_prev_tokens:"
    #prev_prev_tokens.each do |p_p_token|
    #  print " #{p_p_token.text}"
    #end
    #print "------------\n"

    return prev_prev_tokens
  end

  def prev_prev_tags_calculation(prev_prev_token)
    prev_prev_tags = Array.new
    prev_prev_token.tags.values.each do |tag_object|
      #if prev_prev_token.text == EMPTY_WORD
      prev_prev_tags << tag_object
      #else
      #  tag_object.deltas.each do |t, d|
      #    l = d.length
      #    if length == (l+1)
      #      prev_prev_tags << tag_object
      #    end
      #  end
      #end
    end

    #print "------------prev_prev_tags:"
    #puts "token: #{prev_prev_token.text}"
    #prev_prev_tags.each do |p_p_tag|
    #  print " #{p_p_tag.value}"
    #end
    #print "------------\n"

    return prev_prev_tags
  end

  def finalize_step(sentence)
    # We do last calculation which use trigram "tag ### ###"
    deltas = Hash.new
    special_token = Token.new(@sentence.text, EMPTY_WORD, :artificial, -1, -1)
    results = @dw.get_tags_lemmas_emissions(EMPTY_WORD, nil)
    results.each do |result|
      tag_value = result[0]
      lemma = result[1]
      hiperlemma = result[2]
      log_b = Float(result[3])
      special_token.add_tag_lemma_emission(tag_value, lemma, hiperlemma, log_b, true)
    end
    special_token.tags.values.each do |tag|
      prev_token = sentence.last_token
      prev_tags = prev_tags_calculation(prev_token)
      prev_tags.each do |prev_tag|
        prev_delta = prev_tag.maximum_delta
        length = prev_delta.length
        prev_prev_tokens = prev_prev_tokens_calculation(prev_token)
        prev_prev_tokens.each do |prev_prev_token|
          prev_prev_tags = prev_prev_tags_calculation(prev_prev_token)
          prev_prev_tags.each do |prev_prev_tag|
            current_delta = prev_delta.value +
                            @dw.get_trigram_probability(prev_prev_tag.value,
                                                        prev_tag.value,
                                                        tag.value)
            normalized_current_delta = current_delta / (length + 1)
            if (deltas[prev_tag] == nil) or (normalized_current_delta > deltas[prev_tag].normalized_value)
              deltas[prev_tag] = Delta.new(current_delta, prev_delta, length + 1, tag)
            end
          end
        end
      end
      update_deltas(tag, deltas)
    end
    # There is only one last_delta in last iteration
    last_delta = deltas.values.first
    # STDERR.puts "last_delta value: #{last_delta.value} normalized_value: #{last_delta.normalized_value} tag_value: #{last_delta.tag.value}"
    return last_delta
  end

  def print_window(window)
    STDERR.print("WINDOW:")
    window.each do |element|
      if element != nil
        STDERR.print "(#{element[0]}/#{element[1]}/#{element[2]}/#{element[3]})\t"
      else
        STDERR.print "(empty/empty/empty)\t"
      end
    end
    STDERR.puts ""
  end

  def print_full_window(window)
    window.each do |element|
      STDERR.print "#{element[0].token.text}/#{element[0].value}\t"
    end
    STDERR.puts ""
  end

  def convert_window_to_prunning_format(tags_window)
    reversed_tag_window = tags_window.reverse
    window = Array.new(WINDOW_SIZE)

    (0..WINDOW_SIZE - 1).each do |index|
      if reversed_tag_window[index] == nil
        window[index] = Array.new
        window[index] << nil # form
        window[index] << nil # tag
        window[index] << Array.new # lemmas
        window[index] << nil # unit
      else
        window[index] = Array.new
        window[index] << reversed_tag_window[index].token.text
        window[index] << reversed_tag_window[index].value
        window[index] << reversed_tag_window[index].lemmas.keys
        window[index] << reversed_tag_window[index].token.get_unit
      end
    end
    return window
  end

  def update_window(full_window)
    window = Array.new(WINDOW_SIZE)
    (1..WINDOW_SIZE).each do |index|
      if full_window.size - index >= 0
        window[index - 1] = full_window[full_window.size - index][0]
      else
        window[index - 1] = nil
      end
    end
    return window.reverse
  end

  def back_way_build(last_delta, pruning_rules_enabled)
    full_window = Array.new
    element = Array.new
    current_delta = last_delta
    current_tag = last_delta.tag

    element << current_tag
    element << 0
    full_window << element # We store current tag and source delta index

    while current_delta != nil
      # STDERR.puts "current_delta_tag: #{current_delta.tag.value}"
      tags_window = update_window(full_window)
      window = convert_window_to_prunning_format(tags_window)
      #print_window(window)
      if pruning_rules_enabled
        returning_index = @pruning_system.process(window)
      else
        returning_index = 0
      end
      #STDERR.puts "returning_index: #{returning_index}"
      # returning_index = 0 means none pruning rule matching
      if returning_index == 0
        current_delta = current_tag.ordered_deltas[0].prev_delta
        unless current_delta == nil
          current_tag = current_delta.tag
          element = Array.new
          element << current_tag
          element << 0
          full_window << element
          #tags_window = update_window(full_window)
        end
      else
        # A rule rejected this way. We must choose another way from
        # the point of error.
        # STDERR.puts "FULL WINDOW BEFORE RECTIFICATION"
        #print_full_window(full_window)
        (2..returning_index).each do |index|
          # STDERR.puts "index"
          full_window.pop
        end
        #STDERR.puts "FULL WINDOW AFTER RECTIFICATION"
        #print_full_window(full_window)
        #tags_window = update_window(full_window)
        #window = convert_window_to_prunning_format(tags_window)
        #puts "ordered_deltas_size: #{full_window[full_window.size-2][0].ordered_deltas.size}"
        #puts "index:#{full_window[full_window.size-1][1]+1}"
        prev_ordered_deltas = full_window[full_window.size - 2][0].ordered_deltas
        prev_ordered_deltas_new_index = full_window[full_window.size - 1][1] + 1
        if (prev_ordered_deltas[prev_ordered_deltas_new_index] != nil)
          # STDERR.puts "There is another delta"
          new_delta_for_problematic_tag = full_window[full_window.size - 2][0].ordered_deltas[full_window[full_window.size - 1][1] + 1].prev_delta
          element = Array.new
          element << new_delta_for_problematic_tag.tag
          element << full_window[full_window.size - 1][1] + 1
          #STDERR.puts "New element from delta"
          full_window[full_window.size - 1] = element
          #tags_window = update_window(full_window)
          current_delta = new_delta_for_problematic_tag
          current_tag = current_delta.tag
        else
          # There is no valid way
          # So, we include problematic words (not in lexicon) in
          # @without_suffixes_words and start again

          full_window[full_window.size - WINDOW_SIZE..full_window.size].each do |element|
            # puts "analizing token: #{element[0].token.text}"
            if (element[0].token.token_type == :standard) and
               (@dw.get_emissions_info(element[0].token.text, nil).empty?)
              #puts "PROBLEMATIC TOKEN: #{element[0].token.text}"
              @without_suffixes_words[String.new(element[0].token.text)] = true
            end
          end
          return nil
        end
      end
    end

    tags_way = Array.new
    full_window.reverse.each do |element|
      element[0].selected = true
      tags_way << element[0]
    end

    return tags_way
  end

  def print_best_way_xml_with_alternatives_recursive(token, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag, tag_lemma_tag,
                                                     constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                                     qualifying_tag)
    #STDERR.puts "\n(print_best_way_xml_with_alternatives_recursive) token:#{token.text} type:#{token.token_type}"
    if token != nil
      if token.token_type == :standard
        #STDERR.puts"standard: #{token.text}"
        token = print_standard_unit(token, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                                    tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                    qualifying_tag)
        print_best_way_xml_with_alternatives_recursive(token.next, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                                                       tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                                       qualifying_tag)
      elsif (token.token_type == :begin_sentence)
        # print ignored tokens
        token.nexts_ignored.each do |token_aux|
          puts "<#{analysis_unit_tag}>"
          puts "<#{unit_tag}>#{token_aux.text}</#{unit_tag}>"
          token_aux.qualifying_info.keys.each do |info|
            puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
          end
          puts "</#{analysis_unit_tag}>"
        end
        print_best_way_xml_with_alternatives_recursive(token.next, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                                                       tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                                       qualifying_tag)
      elsif token.token_type == :begin_alternative
        token.nexts_ignored.each do |token_aux|
          puts "<#{analysis_unit_tag}>"
          puts "<#{unit_tag}>#{token_aux.text}</#{unit_tag}>"
          token_aux.qualifying_info.keys.each do |info|
            puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
          end
          puts "</#{analysis_unit_tag}>"
        end
        token = print_alternative_unit(token, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                                       tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                       qualifying_tag)
        print_best_way_xml_with_alternatives_recursive(token.next, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                                                       tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                                       qualifying_tag)
      elsif token.token_type == :end_alternative
        token.nexts_ignored.each do |token_aux|
          puts "<#{analysis_unit_tag}>"
          puts "<#{unit_tag}>#{token_aux.text}</#{unit_tag}>"
          token_aux.qualifying_info.keys.each do |info|
            puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
          end
          puts "</#{analysis_unit_tag}>"
        end
        print_best_way_xml_with_alternatives_recursive(token.next, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                                                       tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                                       qualifying_tag)
      end
    end
  end

  def print_best_way_xml_without_alternatives_recursive(token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag,
                                                        form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value, qualifying_tag)
    #STDERR.puts "\n(print_best_way_xml_without_alternatives_recursive) token:#{token.text} type:#{token.token_type}"
    if token != nil
      if token.token_type == :standard
        token = print_valid_only_standard_unit(token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag, form_tag,
                                               tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value, qualifying_tag)
        print_best_way_xml_without_alternatives_recursive(token.next, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag,
                                                          constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                                          qualifying_tag)
      elsif (token.token_type == :begin_sentence)
        # print ignored tokens
        token.nexts_ignored.each do |token_aux|
          puts "<#{analysis_unit_tag}>"
          puts "<#{unit_tag}>#{token_aux.text}</#{unit_tag}>"
          token_aux.qualifying_info.keys.each do |info|
            puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
          end
          puts "</#{analysis_unit_tag}>"
        end
        print_best_way_xml_without_alternatives_recursive(token.next, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag,
                                                          constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                                          qualifying_tag)
      elsif token.token_type == :begin_alternative
        #        token = print_alternative_unit(token, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
        #                                       tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
        #                                       qualifying_tag)
        token.nexts_ignored.each do |token_aux|
          puts "<#{analysis_unit_tag}>"
          puts "<#{unit_tag}>#{token_aux.text}</#{unit_tag}>"
          token_aux.qualifying_info.keys.each do |info|
            puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
          end
          puts "</#{analysis_unit_tag}>"
        end
        token.nexts.keys.each do |token_aux|
          if token_aux.some_tag_selected?
            print_best_way_xml_without_alternatives_recursive(token_aux, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag,
                                                              constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                                              qualifying_tag)
          end
        end
      elsif token.token_type == :end_alternative
        token.nexts_ignored.each do |token_aux|
          puts "<#{analysis_unit_tag}>"
          puts "<#{unit_tag}>#{token_aux.text}</#{unit_tag}>"
          token_aux.qualifying_info.keys.each do |info|
            puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
          end
          puts "</#{analysis_unit_tag}>"
        end
        print_best_way_xml_without_alternatives_recursive(token.next, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag,
                                                          constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                                          qualifying_tag)
      end
    end
  end

  def print_way(token, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                qualifying_tag)
    prev_token = token
    while (token.token_type != :end_alternative)
      prev_token = token
      print_token(token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag,
                  form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value)
      token = token.next
    end
    return prev_token
  end

  def print_alternative_unit(token, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag, tag_lemma_tag,
                             constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                             qualifying_tag)
    #puts "PRINTING ALTERNATIVE UNIT"

    last_token = nil
    puts "<#{analysis_unit_tag}>"
    puts "<#{unit_tag}>#{StringUtils.replace_xml_conflicting_characters(@sentence.get_text(token.from, token.to))}</#{unit_tag}>"
    token.qualifying_info.keys.each do |info|
      puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
    end
    puts "<#{alternatives_tag}>"

    token.nexts.keys.each do |token_aux|
      print "<#{alternative_tag}"
      print " #{valid_attr}=\"#{positive_valid_value}\"" if token_aux.some_tag_selected?
      puts ">"
      #puts "PRINTING WAY"
      last_token = print_way(token_aux, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                             tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                             qualifying_tag)
      puts "</#{alternative_tag}>"
    end

    puts "</#{alternatives_tag}>"
    puts "</#{analysis_unit_tag}>"

    #puts "END PRINTING ALTERMATIVE UNIT"

    return last_token
  end

  def print_standard_unit(token, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                          tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                          qualifying_tag)
    first_token = token
    prev_token_aux = token
    token_aux = token.next
    while token_aux.from == token.from and token_aux.to == token.to
      prev_token_aux = token_aux
      token_aux = token_aux.next
    end
    last_token = prev_token_aux
    print_unit_aux(first_token, last_token, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                   tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                   qualifying_tag)
    return last_token
  end

  def print_valid_only_standard_unit(token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag,
                                     form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value, qualifying_tag)
    first_token = token
    prev_token_aux = token
    token_aux = token.next
    while token_aux.from == token.from and token_aux.to == token.to and token_aux.token_type == :standard
      prev_token_aux = token_aux
      token_aux = token_aux.next
    end
    last_token = prev_token_aux
    #STDERR.puts "(print_valid_only_standard_unit): first_token: #{first_token.text}, last_token: #{last_token.text} first_token_type:#{first_token.token_type} last_token_type:#{last_token.token_type}"
    print_valid_only_unit_aux(first_token, last_token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag,
                              constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                              qualifying_tag)
    return last_token
  end

  def print_unit_aux(first_token, last_token, analysis_tag, analysis_unit_tag, unit_tag, alternatives_tag, alternative_tag,
                     tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                     qualifying_tag)
    puts "<#{analysis_unit_tag}>"
    #puts "first_token: #{first_token.text} token_type:#{first_token.token_type} from:#{first_token.from} to:#{first_token.to}"
    if first_token.chunk_entity_exclude_transform
      puts "<#{unit_tag}>#{@sentence.get_text(first_token.from, first_token.to)}</#{unit_tag}>"
    else
      puts "<#{unit_tag}>#{StringUtils.replace_xml_conflicting_characters(@sentence.get_text(first_token.from, first_token.to))}</#{unit_tag}>"
    end
    first_token.qualifying_info.keys.each do |info|
      puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
    end
    puts "<#{alternatives_tag}>"
    puts "<#{alternative_tag} #{valid_attr}=\"#{positive_valid_value}\">"
    token = first_token
    while token != last_token
      print_token(token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag,
                  form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value)
      token = token.next
    end
    print_token(token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag,
                form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value)
    puts "</#{alternative_tag}>"
    puts "</#{alternatives_tag}>"
    puts "</#{analysis_unit_tag}>"
    # print ignored tokens
    #puts "last_token: #{last_token.text} token_type:#{last_token.token_type} from:#{last_token.from} to:#{last_token.to}"
    last_token.nexts_ignored.each do |token_aux|
      puts "<#{analysis_unit_tag}>"
      puts "<#{unit_tag}>#{token_aux.text}</#{unit_tag}>"
      token_aux.qualifying_info.keys.each do |info|
        puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
      end
      puts "</#{analysis_unit_tag}>"
    end
  end

  def print_valid_only_unit_aux(first_token, last_token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag,
                                constituent_tag, form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value,
                                qualifying_tag)
    puts "<#{analysis_unit_tag}>"
    #STDERR.puts "(print_valid_only_unit_aux) first_token: #{first_token.text} token_type:#{first_token.token_type} from:#{first_token.from} to:#{first_token.to}"
    if first_token.chunk_entity_exclude_transform
      puts "<#{unit_tag}>#{@sentence.get_text(first_token.from, first_token.to)}</#{unit_tag}>"
    else
      puts "<#{unit_tag}>#{StringUtils.replace_xml_conflicting_characters(@sentence.get_text(first_token.from, first_token.to))}</#{unit_tag}>"
    end
    first_token.qualifying_info.keys.each do |info|
      puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
    end
    token = first_token
    while token != last_token
      print_valid_only_token(token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag,
                             form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value)
      token = token.next
    end
    print_valid_only_token(token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag,
                           form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value)
    puts "</#{analysis_unit_tag}>"
    # print ignored tokens
    last_token.nexts_ignored.each do |token_aux|
      puts "<#{analysis_unit_tag}>"
      puts "<#{unit_tag}>#{token_aux.text}</#{unit_tag}>"
      token_aux.qualifying_info.keys.each do |info|
        puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
      end
      puts "</#{analysis_unit_tag}>"
    end
  end

  def print_token(token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag,
                  form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value)
    # STDERR.puts "token.text: #{token.text}"
    puts "<#{constituent_tag}>"
    if token.chunk_entity_exclude_transform
      puts "<#{form_tag}>#{token.text}</#{form_tag}>"
    else
      puts "<#{form_tag}>#{StringUtils.replace_xml_conflicting_characters(token.text)}</#{form_tag}>"
    end
    token.tags.keys.sort.each do |tag|
      tag_object = token.tags[tag]
      if tag_object.lemmas.empty?
        print "<#{tag_lemma_tag}"
        print " #{valid_attr}=\"#{positive_valid_value}\"" if tag_object.selected?
        puts ">"
        puts "<#{tag_tag}>#{tag}</#{tag_tag}>"
        puts "<#{lemma_tag}>*</#{lemma_tag}>"
        puts "<#{hiperlemma_tag}>*</#{hiperlemma_tag}>" if hiperlemma_tag
        puts "</#{tag_lemma_tag}>"
      else
        one_valid = false
        tag_object.lemmas.keys.each do |lemma|
          print "<#{tag_lemma_tag}"
          if tag_object.selected? and !one_valid
            one_valid = true
            print " #{valid_attr}=\"#{positive_valid_value}\""
          end
          puts ">"
          puts "<#{tag_tag}>#{tag}</#{tag_tag}>"
          if token.chunk_entity_exclude_transform
            puts "<#{lemma_tag}>#{lemma}</#{lemma_tag}>"
            puts "<#{hiperlemma_tag}>#{tag_object.hiperlemmas[lemma]}</#{hiperlemma_tag}>" if hiperlemma_tag
          else
            puts "<#{lemma_tag}>#{StringUtils.replace_xml_conflicting_characters(lemma)}</#{lemma_tag}>"
            puts "<#{hiperlemma_tag}>#{StringUtils.replace_xml_conflicting_characters(tag_object.hiperlemmas[lemma])}</#{hiperlemma_tag}>" if hiperlemma_tag
          end
          puts "</#{tag_lemma_tag}>"
        end
      end
    end
    puts "</#{constituent_tag}>"
  end

  def print_valid_only_token(token, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag,
                             form_tag, tag_tag, lemma_tag, hiperlemma_tag, valid_attr, positive_valid_value)
    # STDERR.puts "(print_valid_only_token) token:#{token.text}"
    puts "<#{constituent_tag}>"
    if token.chunk_entity_exclude_transform
      puts "<#{form_tag}>#{token.text}</#{form_tag}>"
    else
      puts "<#{form_tag}>#{StringUtils.replace_xml_conflicting_characters(token.text)}</#{form_tag}>"
    end
    token.tags.keys.sort.each do |tag|
      tag_object = token.tags[tag]
      one_valid = false
      if tag_object.selected? and !one_valid
        one_valid = true
        puts "<#{tag_tag}>#{tag}</#{tag_tag}>"
        if tag_object.lemmas.empty?
          puts "<#{lemma_tag}>*</#{lemma_tag}>"
          puts "<#{hiperlemma_tag}>*</#{hiperlemma_tag}>" if hiperlemma_tag
        else
          tag_object.lemmas.keys.each do |lemma|
            if token.chunk_entity_exclude_transform
              puts "<#{lemma_tag}>#{lemma}</#{lemma_tag}>"
              puts "<#{hiperlemma_tag}>#{tag_object.hiperlemmas[lemma]}</#{hiperlemma_tag}>" if hiperlemma_tag
            else
              puts "<#{lemma_tag}>#{StringUtils.replace_xml_conflicting_characters(lemma)}</#{lemma_tag}>"
              puts "<#{hiperlemma_tag}>#{StringUtils.replace_xml_conflicting_characters(tag_object.hiperlemmas[lemma])}</#{hiperlemma_tag}>" if hiperlemma_tag
            end
          end
        end
      end
    end
    puts "</#{constituent_tag}>"
  end

  def some_info?
    if @tags
      @tags.each do |tag|
        if tag.token.token_type == :standard and tag.token.tagged
          return true
        elsif not tag.token.nexts_ignored.empty?
          return true
        end
      end
    end
    return false
  end
end
