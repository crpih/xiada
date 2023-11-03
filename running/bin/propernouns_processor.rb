# -*- coding: utf-8 -*-
require_relative "database_wrapper.rb"

class ProperNounsProcessor
  def initialize(sentence, dw, remove_join_opt)
    @sentence = sentence
    @dw = dw
    @force_proper_nouns = @sentence.force_proper_nouns
    @links = Hash.new
    results = @dw.get_proper_nouns_links
    results.each do |result|
      @links[result[0]] = true
    end
    @candidate_tags = @dw.get_proper_nouns_candidate_tags
    @remove_join_opt = remove_join_opt
  end

  def process(trained_proper_nouns)
    if @remove_join_opt
      STDERR.puts "Processing basic proper nouns"
      process_basic_proper_nouns
    else
      # STDERR.puts "Processing trained proper nouns"
      process_trained_proper_nouns(trained_proper_nouns) unless trained_proper_nouns == nil
      # STDERR.puts "Processing standard proper nouns"
      process_standard_proper_nouns
      # STDERR.puts "Processing lexicon proper nouns"
      process_lexicon_proper_nouns
      # STDERR.puts "Processing regexp proper nouns"
      process_regexp_proper_nouns
    end
  end

  def add_proper_nouns(trained_proper_nouns)
    prev_token = @sentence.first_token
    token = @sentence.first_token.next
    while (token.token_type == :standard) and (StringUtils.punctuation_beginner?(token.text) or StringUtils.numbers_beginner?(token.text))
      prev_token = token
      token = token.next
    end
    if (token.token_type == :begin_alternative)
      while (token.token_type != :end_alternative)
        prev_token = token
        token = token.next
      end
    end
    if token.token_type != :end_sentence
      prev_token = token
      token = token.next
    end
    while token.token_type != :end_sentence
      if token.token_type == :standard
        if (StringUtils.first_only_upper?(token.text) or StringUtils.alone_letter_upper?(token.text) or
            StringUtils.propers_joined?(token.text) and !token.tagged? and !StringUtils.punctuation_beginner?(prev_token.text))
          last_token = find_last_token(token)
          unless last_token == nil
            alternatives = get_proper_noun_alternatives(token, last_token)
            alternatives.each do |alternative|
              trained_proper_nouns[alternative] = true if @dw.get_emissions_info(StringUtils.to_lower(alternative), nil).empty?
            end
            prev_token = last_token
            token = last_token.next
          else
            prev_token = token
            token = token.next
          end
        else
          prev_token = token
          token = token.next
        end
      elsif token.token_type == :begin_alternative
        while token.token_type != :end_alternative
          prev_token = token
          token = token.next
        end
        prev_token = token
        token = token.next
      end
    end
    #trained_proper_nouns.keys.each do |proper_noun|
    #  puts proper_noun
    #end
  end

  private

  def process_basic_proper_nouns
    # STDERR.puts "(process_standard_proper_nouns)"
    token = @sentence.first_token.next
    while (token.token_type == :begin_alternative)
      while (token.token_type != :end_alternative)
        token = token.next
      end
      token = token.next
    end
    while (token.token_type == :standard) and (StringUtils.punctuation_beginner?(token.text) or StringUtils.numbers_beginner?(token.text))
      token = token.next
    end
    while (token.token_type == :begin_alternative)
      while (token.token_type != :end_alternative)
        token = token.next
      end
      token = token.next
    end
    # token = token.next if token.token_type != :end_sentence and not @force_proper_nouns
    while token.token_type != :end_sentence
      if token.token_type == :standard
        #STDERR.puts "standard token: #{token.text} type:#{token.token_type}"
        if (StringUtils.first_only_upper?(token.text) or StringUtils.alone_letter_upper?(token.text) or
            StringUtils.propers_joined?(token.text)) and !token.tagged?
          token.add_tags_lemma_emission(@candidate_tags, token.text, nil, 0.0, false)
          #STDERR.puts "inside"
          # Beginning of a standard proper noun
        end
        token = token.next
      elsif token.token_type == :begin_alternative
        while token.token_type != :end_alternative
          token = token.next
        end
        token = token.next
      end
    end
  end

  # This function process standard proper nouns, that is, sequences of starting
  # uppercase letter words and links, in the middle of the sentence.
  def process_standard_proper_nouns
    #STDERR.puts "(process_standard_proper_nouns)"
    token = @sentence.first_token.next
    if (token.token_type == :begin_alternative)
      while (token.token_type != :end_alternative)
        token = token.next
      end
      token = token.next
    end
    #STDERR.puts "ERRRTOKEN:#{token.text}"
    while (token.token_type == :standard) and (StringUtils.punctuation_beginner?(token.text) or StringUtils.numbers_beginner?(token.text))
      token = token.next
    end
    #STDERR.puts "ERRRTOKEN:#{token.text}"
    if (token.token_type == :begin_alternative)
      while (token.token_type != :end_alternative)
        token = token.next
      end
      token = token.next
    end
    #STDERR.puts "ERRRTOKEN:#{token.text}"
    # token = token.next if token.token_type != :end_sentence and not @force_proper_nouns
    #STDERR.puts "ERRRTOKEN:#{token.text}"

    while token.token_type != :end_sentence
      if token.token_type == :standard
        #STDERR.puts "standard token: #{token.text} type:#{token.token_type}"
        if (StringUtils.first_only_upper?(token.text) or StringUtils.alone_letter_upper?(token.text) or
            StringUtils.valid_upper_and_lower?(token.text) or StringUtils.proper_noun_with_single_quote_in_the_middle?(token.text) or StringUtils.propers_joined?(token.text)) and !token.tagged?
          #STDERR.puts "inside"
          # Beginning of a standard proper noun
          last_token = find_last_token(token)
          unless last_token == nil
            token = join_standard_proper_noun(token, last_token)
          end
          token = token.next
        else
          token = token.next
        end
      elsif token.token_type == :begin_alternative
        while token.token_type != :end_alternative
          token = token.next
        end
        token = token.next
      end
    end
  end

  def find_last_token(token)
    first_token = token
    last_token = token
    token = token.next
    while token.token_type == :standard
      if StringUtils.first_only_upper?(token.text) or StringUtils.propers_joined?(token.text) or StringUtils.alone_letter_upper?(token.text) or StringUtils.valid_upper_and_lower?(token.text) or StringUtils.proper_noun_with_single_quote_in_the_middle?(token.text) or StringUtils.roman_numeral?(token.text)
        last_token = token
        token = token.next
      elsif link?(token.text)
        token = token.next
      else
        break
      end
    end
    last_token = nil if (last_token == first_token) and StringUtils.alone_letter_upper?(first_token.text)
    return last_token
  end

  def link?(str)
    if @links[str]
      return true
    else
      return false
    end
  end

  def join_proper_noun(from, to)
    #STDERR.puts "join_proper_noun: from: #{from.text} to:#{to.text}"
    #STDERR.puts "from qualifying: #{from.qualifying_info}"
    #STDERR.puts "to qualifying: #{to.qualifying_info}"
    token = from
    if from != to
      new_token_from = from.from
      new_token_to = to.to
      new_token_text = String.new(token.text)
      token = token.next
      while token != to
        new_token_text << " "
        new_token_text << token.text
        token = token.next
      end
      new_token_text << " "
      new_token_text << token.text
      new_token = Token.new(@sentence.text, new_token_text, :standard, new_token_from, new_token_to)
      add_qualifying_info(new_token, from, to)
      add_ignored_tokens(new_token, to)
      #STDERR.puts "join qualifying: #{new_token.qualifying_info}"
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

  def add_qualifying_info(new_token, from, to)
    token = from
    while token != to
      token.qualifying_info.keys.each do |info|
        new_token.add_qualifying_info("#{info}")
      end
      token = token.next
    end
  end

  def add_ignored_tokens(new_token, to)
    new_token.nexts_ignored = to.nexts_ignored.dup
  end

  def join_standard_proper_noun(from, to)
    #STDERR.puts "joining standard proper noun from:#{from.text} to #{to.text}"
    token = join_proper_noun(from, to)
    #STDERR.puts "token.text: #{token.text}"
    token.add_tags_lemma_emission(@candidate_tags, token.text, nil, 0.0, false)
    # if the token is in uppercase in the lexicon, we add the other tags too.
    results = @dw.get_tags_lemmas_emissions_strict(token.text, nil)
    #STDERR.puts "results:#{results}"
    results.each do |result|
      tag_value = result[0]
      lemma = result[1]
      hiperlemma = result[2]
      #STDERR.puts "tag_value:#{tag_value}, lemma:#{lemma}, hiperlemma:#{hiperlemma}"
      log_b = Float(result[3])
      #STDERR.puts "log_b:#{log_b}"
      token.add_tag_lemma_emission(tag_value, lemma, hiperlemma, 0.0, false)
    end
    #STDERR.puts "candidate tags: #{@candidate_tags}"
    return token
  end

  # This function process lexicon proper nouns, that is, detection of proper
  # nouns included in proper nouns lexicon
  def process_lexicon_proper_nouns
    proper_noun_detected_at_first = false
    at_first_token = false
    first_token_tolower = false
    first_token = nil
    proper_noun_num_tokens = 0

    token = @sentence.first_token.next
    while (token.token_type == :standard) and (StringUtils.punctuation_beginner?(token.text) or StringUtils.numbers_beginner?(token.text))
      token = token.next
    end
    unless @sentence.original_first_lower
      if !token.tagged
        if StringUtils.all_lower?(token.text)
          token.replace_text(StringUtils.first_to_upper(token.text))
          first_token_tolower = true
        end
        first_token = token
        at_first_token = true
      end
    end
    #token = token.next if token.token_type != :end_sentence
    while token.token_type != :end_sentence
      if token.token_type == :standard
        ids = @dw.get_proper_nouns_match(token.text, 1, nil)
        unless ids.empty?
          start_token = token
          end_token = nil
          proper_noun = token.text
          def_ids = @dw.get_proper_noun_ids(proper_noun)
          unless def_ids.empty? # Proper noun detected
            end_token = token
            if at_first_token
              proper_noun_num_tokens = proper_noun_num_tokens + 1
              proper_noun_detected_at_first = true
            end
          end

          ids_index = 2
          token = token.next
          num_tokens = 0
          while token.token_type == :standard
            new_ids = @dw.get_proper_nouns_match(token.text, ids_index, ids)
            if new_ids.empty?
              break
            else # We can follow a proper noun
              num_tokens = num_tokens + 1
              proper_noun = proper_noun + " #{token.text}"
              new_def_ids = @dw.get_proper_noun_ids(proper_noun)
              unless new_def_ids.empty? # Longer proper noun detected
                end_token = token
                def_ids = new_def_ids
                if at_first_token
                  proper_noun_num_tokens = proper_noun_num_tokens + num_tokens
                  proper_noun_detected_at_first = true
                end
                num_tokens = 0
              end
            end
            token = token.next
            ids_index = ids_index + 1
          end
          unless end_token == nil
            end_token_aux = find_last_token(end_token) # try to follow proper noun with standard rules
            end_token = end_token_aux unless end_token_aux == nil
            #start_token = find_first_token(start_token)
            token = join_lexicon_proper_noun(start_token, end_token)
            first_token = token if at_first_token
          end
        end # from unless ids.empty?
      elsif token.token_type == :begin_alternative
        while token.token_type != :end_alternative
          token = token.next
        end
        #token = token.next
      end
      token = token.next if token.token_type != :end_sentence
      at_first_token = false
    end # from while token.token_type != :end_sentence
    if proper_noun_detected_at_first and proper_noun_num_tokens == 1
      process_first_token(first_token)
    else
      first_token.replace_text(StringUtils.first_to_lower(first_token.text)) if first_token_tolower
    end
  end

  # This function process trained proper nouns, that is, sequences
  # found in the middle of the sentence. It does not detect proper
  # nouns which starts with article "O Barco", "A Coruna", etc. These
  # proper nouns must be added to proper nouns lexicon to properly be
  # detected at the beginning of the sentence.

  def process_trained_proper_nouns(trained_proper_nouns)
    first_token_tolower = false
    token = @sentence.first_token.next
    while (token.token_type == :standard) and (StringUtils.punctuation_beginner?(token.text) or StringUtils.numbers_beginner?(token.text))
      token = token.next
    end
    unless @sentence.original_first_lower
      if StringUtils.all_lower?(token.text) and !token.tagged?
        token.replace_text(StringUtils.first_to_upper(token.text))
        first_token_tolower = true
      end
    end
    if trained_proper_nouns[token.text]
      last_token = find_last_token(token)
      unless last_token == nil
        new_token = join_standard_proper_noun(token, last_token)
        process_first_token(token) if token == last_token
      end
    elsif first_token_tolower
      token.replace_text(StringUtils.first_to_lower(token.text))
    end
  end

  def join_lexicon_proper_noun(from, to)
    #STDERR.puts "joining lexicon proper noun from:#{from.text} to #{to.text}"
    token = join_proper_noun(from, to)
    # results = @dw.get_tags_lemmas_emissions(token.text, @candidate_tags)
    results = @dw.get_tags_lemmas_emissions_strict(token.text, nil)
    #STDERR.puts "results: #{results}"
    if results.empty?
      results = @dw.get_proper_noun_tags(token.text)
      results.each do |tag|
        token.add_tag_lemma_emission(tag, token.text, token.text, 0.0, false)
      end
    else
      results.each do |result|
        token.add_tag_lemma_emission(result[0], result[1], result[2], Float(result[3]), false)
      end
    end
    return token
  end

  def process_first_token(first_token)

    #unless first_token.text =~ / / not necessary, checked is done in calling functions
    # Proper noun of only one word.
    lower_text = StringUtils.first_to_lower(first_token.text)
    unless @dw.get_emissions_info(lower_text, nil).empty?
      begin_alternative = Token.new(@sentence.text, nil, :begin_alternative, first_token.from, first_token.to)
      end_alternative = Token.new(@sentence.text, nil, :end_alternative, first_token.from, first_token.to)
      new_token = Token.new(@sentence.text, lower_text, :standard, first_token.from, first_token.to)

      begin_alternative.add_next(new_token)
      new_token.add_prev(begin_alternative)
      end_alternative.add_prev(new_token)
      new_token.add_next(end_alternative)

      first_token.prevs.keys.each do |token_prev|
        token_prev.remove_next(first_token)
        token_prev.add_next(begin_alternative)
        begin_alternative.add_prev(token_prev)
      end

      first_token.nexts.keys.each do |token_next|
        token_next.remove_prev(first_token)
        token_next.add_prev(end_alternative)
        end_alternative.add_next(token_next)
      end

      first_token.reset_nexts
      first_token.reset_prevs
      begin_alternative.add_next(first_token)
      first_token.add_prev(begin_alternative)
      end_alternative.add_prev(first_token)
      first_token.add_next(end_alternative)
    end
    #end
  end

  def get_proper_noun_alternatives(from, to)
    token = from
    result = Array.new
    while token != to
      if (StringUtils.first_only_upper?(token.text) or StringUtils.alone_letter_upper?(token.text) or
          StringUtils.propers_joined?(token.text)) and !token.tagged?
        result.concat(get_proper_noun_alternatives_aux(token, to))
      end
      token = token.next
    end
    if (StringUtils.first_only_upper?(token.text) or StringUtils.propers_joined?(token.text)) and
       !token.tagged?
      result.concat(get_proper_noun_alternatives_aux(token, to))
    end
    return result
  end

  def get_proper_noun_alternatives_aux(from, to)
    #STDERR.puts "\nget_proper_noun_alternatives_aux from:#{from.text} to:#{to.text}"
    result = Array.new
    token = from
    if from != to
      new_token_text = String.new(token.text)
      if (StringUtils.first_only_upper?(token.text) or StringUtils.propers_joined?(token.text)) and @dw.not_in_lexicon_or_only_substantive?(token.text)
        result << new_token_text
        new_token_text = String.new(new_token_text)
      end
      token = token.next
      while token != to
        new_token_text << " "
        new_token_text << String.new(token.text)
        if StringUtils.first_only_upper?(token.text) or StringUtils.propers_joined?(token.text)
          result << new_token_text
          new_token_text = String.new(new_token_text)
        end
        token = token.next
      end
      new_token_text << " "
      new_token_text << String.new(token.text)
      result << new_token_text if StringUtils.first_only_upper?(token.text) or StringUtils.propers_joined?(token.text)
    else
      if ((StringUtils.first_only_upper?(token.text) or StringUtils.propers_joined?(token.text)) and @dw.not_in_lexicon_or_only_substantive?(token.text))
        result << String.new(token.text)
      end
    end
    #puts "result:"
    #result.each do |item|
    #  STDERR.puts "item:#{item}"
    #end
    return result
  end

  def process_regexp_proper_nouns
    process_regexp_proper_nouns_recursive(@sentence.first_token, 1, 1)
  end

  def process_regexp_proper_nouns_recursive(token, way, ways)
    if token.token_type == :standard
      token.add_tags_lemma_emission(@candidate_tags, token.text, nil, 0.0, false) if regexp_proper_noun(token) and !token.tagged?
      process_regexp_proper_nouns_recursive(token.next, way, ways)
    elsif token.token_type == :begin_alternative
      # Follow all ways recursively
      way = 1
      ways = token.size_nexts
      token.nexts.keys.each do |token_aux|
        process_regexp_proper_nouns_recursive(token_aux, way, ways)
        way = way + 1
      end
    elsif token.token_type == :end_alternative
      # Join alternatives and follow only one way
      if way == ways
        process_regexp_proper_nouns_recursive(token.next, way, ways)
      end
    elsif token.token_type == :begin_sentence
      process_regexp_proper_nouns_recursive(token.next, way, ways)
    elsif token.token_type == :end_sentence
    end
  end

  def regexp_proper_noun(token)
    # To be externalized to database or file ???
    if token.text =~ /[A-Z]+-\d+/
      return true
    else
      return false
    end
  end
end
