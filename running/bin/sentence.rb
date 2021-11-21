# -*- coding: utf-8 -*-
require_relative "token.rb"
require_relative "contractions_processor.rb"
require_relative "idioms_processor.rb"
require_relative "propernouns_processor.rb"
require_relative "numerals_processor.rb"
require_relative "../#{ENV["XIADA_PROFILE"]}/enclitics_processor.rb"
require_relative "../../lib/string_utils.rb"

class Sentence
  attr_reader :first_token, :last_token, :text, :original_first_lower, :force_proper_nouns

  def initialize(dw, acronyms, abbreviations, enclitics, force_proper_nouns)
    Token.reset_class
    @first_token = nil
    @last_token = nil
    @text = ""
    @dw = dw
    @acronyms = acronyms
    @abbreviations = abbreviations
    @enclitics = enclitics
    @force_proper_nouns = force_proper_nouns
    @peripheric_regexp = @dw.get_peripheric_regexp
    @original_first_lower = false # Used by ProperNounsProcessor
    @first_token = Token.new(self.text, nil, :begin_sentence, -1, -1)
    @last_token = Token.new(self.text, nil, :end_sentence, -1, -1)
    @current_last_token = @first_token
    @current_text_offset = 0
  end

  def add_empty_tag_included_info(tag_str, qualifying_info)
    # STDERR.puts "(add_empty_tag_included_info) tag_str: #{tag_str}"
    @current_last_token.add_nexts_ignored("#{tag_str}", qualifying_info)
  end

  def add_chunk(text, ignore_content_info, qualifying_info, chunk_entity_exclude_transform, chunk_exclude_segmentation)
    # text.strip!
    text.gsub!(/\n/, "")
    #STDERR.puts "add_chunk:-#{text}-"
    #STDERR.puts "chunk_exclude_segmentation: #{chunk_exclude_segmentation}"
    #STDERR.puts "(add_chunk) chunk_exclude_transform: #{chunk_entity_exclude_transform}"
    ignore_content_info = nil if ignore_content_info and ignore_content_info.empty?
    #STDERR.puts "ignore_context_info: #{ignore_content_info}"
    qualifying_info = nil if qualifying_info and qualifying_info.empty?
    #STDERR.puts "qualifying_info: #{qualifying_info}\n\n"
    text = nil if text == ""
    if text
      unless text =~ /^ +$/ and @text =~ / $/
        @text << text
        build_chunk_sentence(text, ignore_content_info, qualifying_info, chunk_entity_exclude_transform, chunk_exclude_segmentation)
      end
    end
  end

  def finish
    @current_last_token.add_next(@last_token)
    @last_token.add_prev(@current_last_token)
    process_acronym_abbreviation_contraction_stuff
    process_proper_nouns_stuff
  end

  def empty?
    if @text =~ /^[ ]*$/
      return true
    else
      return false
    end
  end

  def build_chunk_sentence(text, ignore_content_info, qualifying_info, chunk_entity_exclude_transform, chunk_exclude_segmentation)
    if text
      #STDERR.puts "text: #{text}"
      #STDERR.puts "qualifying_info:#{qualifying_info} class:#{qualifying_info.class}"
      tokens = tokenize(text, chunk_exclude_segmentation, ignore_content_info, qualifying_info)
      #STDERR.puts "tokenize(text): #{tokens}"
    else
      tokens = nil
    end
    build_sentence_tokens(tokens, text, ignore_content_info, qualifying_info, chunk_entity_exclude_transform)
  end

  def tokenize(text, chunk_exclude_segmentation, ignore_content_info, qualifying_info)
    local_text = String.new(text)
    #STDERR.puts "(tokenize) local_text: #{local_text} chunk_exclude_segmentation:#{chunk_exclude_segmentation} ignore_content_info:#{ignore_content_info}"
    unless chunk_exclude_segmentation == nil or chunk_exclude_segmentation[0].empty?
      local_text, letter_replacement, removed_info = remove_chunk_exclude_segmentation(local_text, chunk_exclude_segmentation)
    end
    # STDERR.puts "local_text: #{local_text}, removed_info: #{removed_info}"
    # Remove several spaces due to tag removing inside text
    local_text.gsub!(/ +/, " ")
    local_text.gsub(/^ +/, "")

    # Dots are separated from previous and next words (if we don't have palabra_cortada qualifying info)
    unless qualifying_info and qualifying_info.include?("distinto[tipo=palabra_cortada]") # to be extrated to language configuration ???
      local_text.gsub!(/([^ ])(\.\.\.)/, '\1 \2')
      local_text.gsub!(/(\.\.\.)([^ ])/, '\1 \2')
    end

    # workaround for acoutacións. By now we'll not allow abbreviations
    # followed by ) or "
    local_text.gsub!(/([a-zñA-ZÑáéíóúÁÉÍÓÚ])\.([)"])$/, '\1 . \2')

    tokens = local_text.split(/ |([;¡!¿\?"\[\]_])/)

    #STDERR.puts "\n\n(tokenize) tokens0:#{tokens}"

    tokens_new = Array.new
    tokens.each_index do |index|
      token = tokens[index]
      # STDERR.puts "token_src: #{token} index:#{index}"
      # identifiers at the beginning of the sentence
      if index == 0 and token =~ /^[0-9A-Za-z]+\)/
        tokens_new << token
        # if a number ends with dot or comma, we separate this dot in a new token.
        # it occurs in identifiers at the begining of the sentence
      elsif token =~ /^(\(?)([0-9]+[\.,\/:'][0-9]+%?)(\)?)([\.,])$/ or token =~ /^(\(?)([0-9]+%?)(\)?)([\.,])$/
        tokens_new << $1 if $1 and $1 != ""
        tokens_new << $2 if $2 and $2 != ""
        tokens_new << $3 if $3 and $3 != ""
        tokens_new << $4 if $4 and $4 != ""
        # STDERR.puts "tokens_new: #{tokens_new}"
        #STDERR.puts "inside1"
        # URIS treatment
      elsif token =~ /(^https?:\/\/[a-z0-9\.?#\/=\-]+)(\.)?/
          tokens_new << $1 if $1 and $1 != ""
          tokens_new << $2 if $2 and $2 != ""
      # We separate ,:'- from not numeric words and simbols at the end of any word and - at the beginning
      elsif token != "" and token =~ /^([\-\()]?)([a-záéíóúñA-ZÑÁÉÍÓÚ]+)([,:'\-\)]?)$/
        tokens_new << $1 if $1 and $1 != ""
        tokens_new << $2 if $2 and $2 != ""
        tokens_new << $3 if $3 and $3 != ""
      # We separate ,:'-) from numbers at the end of any word
      elsif token != "" and token =~ /^([\(]?)([\-]?[0-9]+[,\.]?[0-9+]?)([,:'\-\)]?)$/
        tokens_new << $1 if $1 and $1 != ""
        tokens_new << $2 if $2 and $2 != ""
        tokens_new << $3 if $3 and $3 != ""
      # Split parents
      elsif token != "" and token =~/[\(\)]/ and token !~ /^[a-záéíóúñA-ZÑÁÉÍÓÚ0-9\-]+\([a-záéíóúñA-ZÑÁÉÍÓÚ0-9]+\)[a-záéíóúñA-ZÑÁÉÍÓÚ0-9]*\.?[,:']?$/ and token !~ /^[A-Za-z0-9]\)$/ and
        token !~ /^[a-záéíóúñA-ZÑÁÉÍÓÚ0-9\-]+'[a-záéíóúñA-ZÑÁÉÍÓÚ0-9\-]+/
        tokens_aux = token.split(/ |([\(\)])/)
        tokens_aux.each do |token_aux|
          tokens_new << token_aux if token_aux != ""
        end
      elsif token != ""
        # STDERR.puts "inside3"
        tokens_new << token
      end
    end
    tokens = tokens_new

    #STDERR.puts "(tokenize) tokens:#{tokens}"

    # URLs with query string detection
    tokens_new = Array.new
    index = 0
    while (index < tokens.size)
      token = tokens[index]
      #STDERR.puts "token:#{token}, index:#{index}, tokens.size:#{tokens.size}"
      if token =~ /^https?/ and (index + 2 < tokens.size) and (tokens[index+1]=~/[_?]/)
        new_token = token
        new_full_token = "#{new_token}"
        index = index + 1
        new_token = tokens[index]
        new_full_token << "#{new_token}"
        index = index + 1
        new_token = tokens[index]
        new_full_token << "#{new_token}"
        tokens_new << new_full_token
        index = index + 1
      else
        tokens_new << token
        index = index + 1
      end
    end
    tokens = tokens_new
    #STDERR.puts "(tokenize) tokens:#{tokens}"

    # Numbers separated by spaces detection
    tokens_new = Array.new
    index = 0
    while (index < tokens.size)
      token = tokens[index]
      if token =~ /[0-9]+/ and (index < tokens.size)
        new_token = token
        new_full_token = "#{new_token}"
        new_index = index + 1
        new_token = tokens[new_index]
        while new_token =~ /[0-9]+/ and (new_index < tokens.size)
          new_full_token << " #{new_token}"
          new_index = new_index + 1
          new_token = tokens[new_index] if (new_index < tokens.size)
        end
        tokens_new << new_full_token
        index = new_index
      else
        tokens_new << token
        index = index + 1
      end
    end
    tokens = tokens_new
    if ignore_content_info != nil and not ignore_content_info.empty?
      if tokens.last =~ /([^\.]+)\.$/
        tokens[tokens.length - 1] = $1
        tokens << "."
      end
    end
    unless chunk_exclude_segmentation == nil or chunk_exclude_segmentation[0].empty?
      tokens = restore_chunk_exclude_segmentation(tokens, letter_replacement, removed_info)
    end
    # STDERR.puts "token.size: #{tokens.size}"
    # STDERR.puts "(tokenize) tokens:#{tokens}"

    return tokens
  end

  def restore_chunk_exclude_segmentation(tokens, letter_replacement, removed_info)
    removed_info_index = 0
    regexp = letter_replacement * removed_info[removed_info_index].size
    last = false
    tokens.each do |token|
      while token =~ /#{regexp}/ and not last
        # STDERR.puts "token: #{token}"
        token.sub!(/#{regexp}/, removed_info[removed_info_index])
        # STDERR.puts "token: #{token}"
        removed_info_index = removed_info_index + 1
        if removed_info[removed_info_index]
          regexp = letter_replacement * removed_info[removed_info_index].size
        else
          last = true
        end
      end
    end
    return tokens
  end

  def remove_chunk_exclude_segmentation(text, chunk_exclude_segmentation)
    #STDERR.puts "(remove_chunk_exclude_segmentation) text: #{text}"
    letter = "@"
    selections = Array.new
    new_text = String.new(text)
    chunk_exclude_segmentation[0].each_index do |index|
      from = chunk_exclude_segmentation[0][index]
      to = chunk_exclude_segmentation[1][index]
      selection = new_text[from..to]
      selections << selection
      selection_replacement = get_selection_replacement(selection, letter)

      result = ""
      result << new_text[0..from - 1] if from > 0
      result << selection_replacement
      result << new_text[to + 1..new_text.size - 1] if to < new_text.size - 1
      # STDERR.puts "from: #{from}, to:#{to}, selection:#{selection}"
      # STDERR.puts "result: #{result}"
      new_text = result
    end
    #STDERR.puts "new_text: #{new_text}"
    return [new_text, letter, selections]
  end

  def get_selection_replacement(selection, letter)
    selection_replacement = letter * selection.size
    #STDERR.puts "selection            : #{selection}"
    #STDERR.puts "selection_replacement: #{selection_replacement}"
    return selection_replacement
  end

  def chunk_entity_exclude_transform_match?(from, to, chunk_entity_exclude_transform)
    # STDERR.puts "(chunk_entity_exclude_transform_match?) from:#{from}, to:#{to}"
    chunk_entity_exclude_transform.each do |element|
      element_from = element[0]
      element_to = element[1]
      return true if (from >= element_from and from <= element_to) or (to >= element_from and to <= element_to) or (element_from > from and element_to < to)
    end
    # STDERR.puts "false"
    return false
  end

  # Not used
  def build_ignore_content_info(text, ignore_content_info, qualifying_info, chunk_entity_exclude_transform)
    if text
      from = 0
      to = text.length - 1
      #token = Token.new(self.text, String.new(text), :standard, from+@current_text_offset, to+@current_text_offset)
      #unless chunk_entity_exclude_transform.empty?
      #  token.set_chunk_entity_exclude_transform if chunk_entity_exclude_transform_match?(from, to, chunk_entity_exclude_transform)
      #end
      #token.add_prev(@current_last_token)
      # @current_last_token.add_next(token)
      # @current_last_token = token
      # STDERR.puts "(build_ignored_content_info) text:#{text}, from:#{from}, to:#{to}, chunk_entity_exclude_transform:#{chunk_entity_exclude_transform}"
      if chunk_entity_exclude_transform_match?(from, to, chunk_entity_exclude_transform)
        @current_last_token.add_nexts_ignored(text, qualifying_info)
      else
        @current_last_token.add_nexts_ignored(StringUtils.replace_xml_conflicting_characters(text), qualifying_info)
      end
    end
  end

  def build_sentence_tokens(tokens, text, ignored_content_info, qualifying_info, chunk_entity_exclude_transform)
    if !ignored_content_info and text
      #STDERR.puts "1"
      prev_token = @current_last_token
      offset = 0
      from = 0
      tokens.each do |token_text|
        #STDERR.puts "text: #{text}"
        #STDERR.puts "token_text: #{token_text}"
        from = text.index(token_text, offset)
        to = from + token_text.length - 1
        token = Token.new(self.text, String.new(token_text), :standard, from + @current_text_offset, to + @current_text_offset)
        token.add_qualifying_info_array(qualifying_info) if qualifying_info
        unless chunk_entity_exclude_transform == nil or chunk_entity_exclude_transform.empty?
          token.set_chunk_entity_exclude_transform if chunk_entity_exclude_transform_match?(from, to, chunk_entity_exclude_transform)
        end
        #STDERR.puts "Building token: #{token.text}, from:#{token.from}, to:#{token.to}, chunk_entity_exclude_transform:#{token.chunk_entity_exclude_transform}"
        offset = to + 1
        token.add_prev(prev_token)
        prev_token.add_next(token)
        prev_token = token
      end
      @current_last_token = prev_token
    else
      #STDERR.puts "2"
      if ignored_content_info
        if tokens == nil or tokens.empty?
          # STDERR.puts "add_nexts_ignored(nil, #{ignored_content_info})"
          @current_last_token.add_nexts_ignored(nil, qualifying_info)
        else
          offset = 0
          from = 0
          tokens.each do |token_text|
            # STDERR.puts "token_text: #{token_text}"
            from = text.index(token_text, offset)
            to = from + token_text.length - 1
            if chunk_entity_exclude_transform == nil or chunk_entity_exclude_transform.empty?
              if chunk_entity_exclude_transform_match?(from, to, chunk_entity_exclude_transform)
                @current_last_token.add_nexts_ignored(token_text, qualifying_info)
              else
                @current_last_token.add_nexts_ignored(StringUtils.replace_xml_conflicting_characters(token_text), qualifying_info)
              end
            else
              if chunk_entity_exclude_transform_match?(from, to, chunk_entity_exclude_transform)
                @current_last_token.add_nexts_ignored(token_text, qualifying_info)
              else
                @current_last_token.add_nexts_ignored(StringUtils.replace_xml_conflicting_characters(token_text), qualifying_info)
              end
            end
            offset = to + 1
          end
        end
      end
    end
    @current_text_offset = @text.length
  end

  def process_proper_nouns_stuff

    #### For proper nouns module use

    if is_original_first_lower? and not @force_proper_nouns
      @original_first_lower = true
    else
      @original_first_lower = false
    end

    #### Convert to lower first word if it is not acronym or abbreviation

    first_to_lower unless @force_proper_nouns
  end

  def process_acronym_abbreviation_contraction_stuff

    #### Last token check for acronym, abbreviation or contraction

    last_token = @last_token.prev
    if last_token.nexts_ignored.empty?
      #STDERR.puts "last_token: #{last_token.text} last_token_type: #{last_token.token_type}"

      # If last token is an acronym or abbreviation, we check if it is a contraction
      # or it is included in the lexicon to build the alternatives.

      if last_token.text =~ /\.$/ and (@acronyms[last_token.text] != nil or @abbreviations[last_token.text] != nil)
        #STDERR.puts "last token is acronym or abbreviation and last_tokens ends with dot"
        last_token_without_end_point = last_token.text.gsub(/\.$/, "")
        result = @dw.get_emissions_info(last_token_without_end_point, nil)
        lexicon_not_abbreviation = false
        result.each do |result_entry|
          tag = result_entry[0]
          #puts "tag:#{tag}"
          if !peripheric?(tag)
            # last_token is in lexicon also
            lexicon_not_abbreviation = true
            break
          end
        end
        result2 = @dw.get_contractions(last_token_without_end_point)
        contraction = !result2.empty?
        # STDERR.puts "lexicon_not_abbreviation: #{lexicon_not_abbreviation}"
        # STDERR.puts "last_token_without_end_point:#{last_token_without_end_point}"
        # STDERR.puts "contraction: #{contraction}"
        if (lexicon_not_abbreviation or contraction) and not(lexicon_not_abbreviation and contraction)
          # STDERR.puts "entra0"
          # Build alternative
          begin_alternative = Token.new(self.text, nil, :begin_alternative, last_token.from, last_token.to)
          end_alternative = Token.new(self.text, nil, :end_alternative, last_token.from, last_token.to)
          acronym_way = Token.new(self.text, last_token.text, :standard, last_token.from, last_token.to)
          first_token_text = last_token.text[0, last_token.text.length - 1]
          second_token_text = last_token.text[last_token.text.length - 1, 1]

          begin_alternative.add_next(acronym_way)
          acronym_way.add_prev(begin_alternative)
          end_alternative.add_prev(acronym_way)
          acronym_way.add_next(end_alternative)

          # A revisar se esta condición é incompatible coa seguinte (xeran os mesmos tokens).
          if contraction or lexicon_not_abbreviation
            #STDERR.puts "1"
            contraction_or_lexicon_way_first_component = Token.new(self.text, first_token_text.clone, :standard, last_token.from, last_token.to - 1)
            contraction_or_lexicon_way_second_component = Token.new(self.text, second_token_text.clone, :standard, last_token.to, last_token.to)
            begin_alternative.add_next(contraction_or_lexicon_way_first_component)
            contraction_or_lexicon_way_first_component.add_prev(begin_alternative)
            end_alternative.add_prev(contraction_or_lexicon_way_second_component)
            contraction_or_lexicon_way_second_component.add_next(end_alternative)
            contraction_or_lexicon_way_first_component.add_next(contraction_or_lexicon_way_second_component)
            contraction_or_lexicon_way_second_component.add_prev(contraction_or_lexicon_way_first_component)
          end
          #          if lexicon_not_abbreviation
          #            STDERR.puts "2"
          #            lexicon_way_first_component = Token.new(self.text, first_token_text.clone, :standard, last_token.from, last_token.to-1)
          #            lexicon_way_second_component = Token.new(self.text, second_token_text.clone, :standard, last_token.to, last_token.to)
          #            begin_alternative.add_next(lexicon_way_first_component)
          #            lexicon_way_first_component.add_prev(begin_alternative)
          #            end_alternative.add_prev(lexicon_way_second_component)
          #            lexicon_way_second_component.add_next(end_alternative)
          #            lexicon_way_first_component.add_next(lexicon_way_second_component)
          #            lexicon_way_second_component.add_prev(lexicon_way_first_component)
          #          end

          # Insertion of alternatives inside the sentence.
          previous_token = last_token.prev
          next_token = @last_token
          previous_token.reset_nexts
          next_token.reset_prevs
          previous_token.add_next(begin_alternative)
          begin_alternative.add_prev(previous_token)
          next_token.add_prev(end_alternative)
          end_alternative.add_next(next_token)
        end
      else
        if last_token.text =~ /\.$/ and last_token.text != "..." and last_token.text != "."
          # We have to separate last word from end point
          last_token.text.gsub!(/\.$/, "")
          last_token.to = last_token.to - 1
          point_token = Token.new(self.text, ".", :standard, last_token.to + 1, last_token.to + 1)
          last_token.reset_nexts
          last_token.add_next(point_token)
          point_token.add_prev(last_token)
          @last_token.reset_prevs
          point_token.add_next(@last_token)
          @last_token.add_prev(point_token)
        end
      end
    else # Sentence end with ignored tokens
      # We always separate en point at the end of the sentence
      # three points reach tokenized from previous method
      # STDERR.puts "ENTER"
      # So, we have only to decide if we have to separate . or ...
      real_last_token = last_token.nexts_ignored.last
      # STDERR.puts "real_last_token: #{real_last_token}"
      if real_last_token =~ /\.$/ and real_last_token !~ /\.\.\.$/
        real_last_token_without_end_point = real_last_token.gsub(/\.$/, "")
        last_token.nexts_ignored.pop
        last_token.nexts_ignored << real_last_token_without_end_point
        last_token.nexts_ignored << "."
      end
    end
  end

  def print(fd)
    fd.puts "PRINTING SENTENCE"
    print_recursive(fd, @first_token, 1, 1)
  end

  def full_ignored?
    token = @first_token
    while token
      return false if token.token_type == :standard
      token = token.next
    end
    return true
  end

  def print_only_units(sentence_tag, expression_tag, expression_attributes, analysis_tag, analysis_unit_tag, unit_tag, tag_lemma_tag, constituent_tag, form_tag, tag_tag, lemma_tag, valid_attr, positive_valid_value, expression, qualifying_tag)
    puts "<#{sentence_tag}#{expression_attributes}>\n"
    puts "<#{expression_tag}>#{expression}</#{expression_tag}>\n"
    puts "<#{analysis_tag}>"
    token = @first_token
    while token
      if token.token_type == :standard
        puts "<#{analysis_unit_tag}>"
        if token.chunk_entity_exclude_transform
          puts "<#{unit_tag}>#{get_text(token.from, token.to)}</#{unit_tag}>"
          token.qualifying_info.keys.each do |info|
            puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
          end
          puts "<#{constituent_tag}>"
          puts "<#{form_tag}>#{token.text}</#{form_tag}>"
          puts "<#{tag_tag}></#{tag_tag}>"
          puts "<#{lemma_tag}></#{lemma_tag}>"
          puts "</#{constituent_tag}>"
        else
          puts "<#{unit_tag}>#{StringUtils.replace_xml_conflicting_characters(get_text(token.from, token.to))}</#{unit_tag}>"
          token.qualifying_info.keys.each do |info|
            puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
          end
          puts "<#{constituent_tag}>"
          puts "<#{form_tag}>#{StringUtils.replace_xml_conflicting_characters(token.text)}</#{form_tag}>"
          puts "<#{tag_tag}></#{tag_tag}>"
          puts "<#{lemma_tag}></#{lemma_tag}>"
          puts "</#{constituent_tag}>"
        end
        puts "</#{analysis_unit_tag}>"
      end

      token.nexts_ignored.each do |token_aux|
        puts "<#{analysis_unit_tag}>"
        puts "<#{unit_tag}>#{token_aux.text}</#{unit_tag}>"
        token_aux.qualifying_info.keys.each do |info|
          puts "<#{qualifying_tag}>#{info}</#{qualifying_tag}>"
        end
        puts "<#{constituent_tag}>"
        puts "<#{form_tag}>#{token_aux.text}</#{form_tag}>"
        puts "<#{tag_tag}></#{tag_tag}>"
        puts "<#{lemma_tag}></#{lemma_tag}>"
        puts "</#{constituent_tag}>"
        puts "</#{analysis_unit_tag}>"
      end
      token = token.next
    end
    puts "</#{analysis_tag}>"
    puts "</#{sentence_tag}>"
  end

  def print_from_token(token)
    puts "PRINTING SENTENCE TOKEN"
    print_recursive(STDOUT, token, 1, 1)
  end

  def print_reverse
    puts "PRINTING SENTENCE REVERSE"
    print_recursive_reverse(@last_token, 1, 1)
  end

  def print_reverse_from_token(token)
    puts "PRINTINT SENTENCE REVERSE TOKEN"
    print_recursive_reverse(token, 1, 1)
  end

  def contractions_processing
    processor = ContractionsProcessor.new(self, @dw)
    processor.process
  end

  def idioms_processing
    processor = IdiomsProcessor.new(self, @dw)
    processor.process
  end

  def proper_nouns_processing(trained_proper_nouns, remove_join_opt)
    processor = ProperNounsProcessor.new(self, @dw, remove_join_opt)
    processor.process(trained_proper_nouns)
  end

  def numerals_processing
    processor = NumeralsProcessor.new(self, @dw)
    processor.process
  end

  def enclitics_processing
    processor = EncliticsProcessor.new(self, @dw, @enclitics)
    processor.process
  end

  def get_text(from, to)
    return (@text[from..to])
  end

  def add_proper_nouns(trained_proper_nouns)
    processor = ProperNounsProcessor.new(self, @dw, false)
    if min_length > 1
      processor.add_proper_nouns(trained_proper_nouns)
    end
  end

  private

  def print_recursive(fd, token, way, ways)
    return nil unless token
    if token.token_type == :standard
      print_token(fd, token)
      print_recursive(fd, token.next, way, ways)
    elsif token.token_type == :begin_alternative
      print_token(fd, token)
      # Follow all ways recursively
      way = 1
      ways = token.size_nexts
      token.nexts.keys.each do |token_aux|
        fd.puts "<alternative>"
        print_recursive(fd, token_aux, way, ways)
        way = way + 1
      end
    elsif token.token_type == :end_alternative
      # Join alternatives and follow only one way
      fd.puts "</alternative>"
      if way == ways
        print_token(fd, token)
        print_recursive(fd, token.next, 1, 1)
      end
    elsif token.token_type == :begin_sentence
      print_token(fd, token)
      print_recursive(fd, token.next, 1, 1)
    elsif token.token_type == :end_sentence
      print_token(fd, token)
    end
  end

  def print_recursive_reverse(token, way, ways)
    if token.token_type == :standard
      print_token(STDOUT, token)
      print_recursive_reverse(token.prev, way, ways)
    elsif token.token_type == :end_alternative
      print_token(STDOUT, token)
      # Follow all ways recursively
      way = 1
      ways = token.size_prevs
      token.prevs.keys.each do |token_aux|
        puts "<alternative>"
        print_recursive_reverse(token_aux, way, ways)
        way = way + 1
      end
    elsif token.token_type == :begin_alternative
      # Join alternatives and follow only one way
      puts "</alternative>"
      if way == ways
        print_token(STDOUT, token)
        print_recursive_reverse(token.prev, 1, 1)
      end
    elsif token.token_type == :begin_sentence
      print_token(STDOUT, token)
    elsif token.token_type == :end_sentence
      print_token(STDOUT, token)
      print_recursive_reverse(token.prev, 1, 1)
    end
  end

  def print_token(fd, token)
    return nil unless token
    if token.token_type == :standard
      text = token.text
      text = "nil" if text == nil
      fd.puts "token:#{text}\ttype=#{token.token_type}\tfrom=#{token.from}\tto=#{token.to}\ttoken_object=#{token}\tchunk_entity_exclude_transform:#{token.chunk_entity_exclude_transform}"
      token.tags.values.each do |tag_object|
        fd.puts "\ttag=#{tag_object.value}\temission=#{tag_object.emission}\tselected=#{tag_object.selected?}\ttag_object=#{tag_object}\ttoken_object_from_tag=#{tag_object.token}"
        tag_object.lemmas.keys.each do |lemma|
          fd.print "\tlemma=#{lemma}"
          fd.print "/hiperlemma=#{tag_object.hiperlemmas[lemma]}" if tag_object.hiperlemmas[lemma]
          fd.puts ""
        end
        tag_object.deltas.each do |prev_tag, delta|
          fd.puts "\t\tdelta=#{delta.value}, prev_tag=#{prev_tag}"
          fd.puts "\t\tdelta.normalized=#{delta.normalized_value}, prev_tag=#{prev_tag}"
        end
      end
      unless token.nexts_ignored.empty?
        fd.print "ignored tokens (standard):\n"
        token.nexts_ignored.each do |ignored_token|
          fd.print " #{ignored_token.text}"
          ignored_token.qualifying_info.keys.each do |info|
            fd.print " <qual>#{info}</qual>"
          end
          fd.puts ""
        end
      end
      fd.print "infos:"
      token.qualifying_info.each do |info|
        fd.print " <qual>#{info}</qual>"
      end
      fd.puts ""
    elsif token.token_type == :begin_alternative
      fd.puts "<alternatives> nexts:#{token.nexts.size}"
    elsif token.token_type == :end_alternative
      unless token.nexts_ignored.empty?
        fd.print "ignored tokens (end_alternative):\n"
        token.nexts_ignored.each do |ignored_token|
          fd.print " #{ignored_token.text}"
          ignored_token.qualifying_info.keys.each do |info|
            fd.print " <qual>#{info}</qual>"
          end
          fd.puts ""
        end
      end
      fd.puts "</alternatives> prevs:#{token.prevs.size}"
    elsif token.token_type == :begin_sentence
      fd.puts "<sentence>"
      unless token.nexts_ignored.empty?
        fd.print "ignored tokens:"
        token.nexts_ignored.each do |ignored_token|
          fd.print " #{ignored_token.text}"
          ignored_token.qualifying_info.keys.each do |info|
            fd.print " <qual>#{info}</qual>"
          end
        end
      end
      fd.print "infos:"
      token.qualifying_info.keys.each do |info|
        fd.print " <qual>#{info}</qual>"
      end
      fd.puts ""
    elsif token.token_type == :end_sentence
      fd.puts "</sentence>"
    end
  end

  def is_original_first_lower?
    all_lower = false
    token = @first_token.next
    while (token.token_type == :standard) and (StringUtils.punctuation_beginner?(token.text) or StringUtils.numbers_beginner?(token.text))
      token = token.next
    end
    all_lower = StringUtils.all_lower?(token.text) if (token.token_type == :standard)
    return all_lower
  end

  def first_to_lower
    token = @first_token.next
    while (token.token_type == :standard) and (StringUtils.punctuation_beginner?(token.text) or StringUtils.numbers_beginner?(token.text))
      token = token.next
    end
    #STDERR.puts "first token: #{token.text}"
    #if (token.token_type == :standard) and (token.text.length == 1 or ((token.text.length > 1) and
    #  (@acronyms[token.text] == nil) and (@abbreviations[token.text] == nil) and
    #  !first_words_in_lexicon))
    if (token.token_type == :standard) and (token.text.length == 1 or ((token.text.length > 1) and
      (@acronyms[token.text] == nil) and (@abbreviations[token.text] == nil)))
      token.replace_text(StringUtils.first_to_lower(token.text)) 
    end
    #STDERR.puts "first token after first_to_lower: #{token.text}"
  end

  def first_words_in_lexicon
    token = @first_token.next
    while (token.token_type == :standard) and (StringUtils.punctuation_beginner?(token.text) or StringUtils.numbers_beginner?(token.text))
      token = token.next
    end
    text_to_search = ""
    word_counter = 1
    while (token.token_type == :standard) and word_counter < 5
      text_to_search << "#{token.text}"
      result = @dw.get_emissions_info(text_to_search, nil)
      #STDERR.puts "result:#{result}"
      return true unless result.empty?
      text_to_search << " "
      token = token.next
      word_counter = word_counter + 1
    end
    return false
  end

  def min_length
    min_length = 0
    token = @first_token.next
    while token.token_type != :end_sentence
      if token.token_type == :standard
        token = token.next
        min_length = min_length + 1
      elsif token.token_type == :begin_alternative
        min_length_aux_min = Float::MAX.floor
        token.nexts.keys.each do |token_aux|
          min_length_aux = 0
          token_aux2 = token_aux
          while token_aux2.token_type != :end_alternative
            token_aux2 = token_aux2.next
            min_length_aux = min_length_aux + 1
          end
          token = token_aux2
          min_length_aux_min = min_length_aux if min_length_aux < min_length_aux_min
        end
        min_length = min_length + min_length_aux_min
      elsif token.token_type == :end_alternative
        token = token.next
      end
    end
    return min_length
  end

  def peripheric?(tag)
    result = tag =~ /#{@peripheric_regexp}/
    return result
  end
end
