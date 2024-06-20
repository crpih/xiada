# -*- coding: utf-8 -*-
require 'active_support/core_ext/object/blank'
require_relative "token.rb"
require_relative "contractions_processor.rb"
require_relative "idioms_processor.rb"
require_relative "numerals_processor.rb"
require_relative "../#{ENV["XIADA_PROFILE"]}/enclitics_processor.rb"
require_relative "../../lib/string_utils.rb"

class Sentence
  include Enumerable

  attr_reader :first_token, :last_token, :text, :original_first_lower

  def initialize(dw, acronyms, abbreviations, enclitics, proper_nouns_processor, text)
    Token.reset_class
    @first_token = nil
    @last_token = nil
    @text = text
    @dw = dw
    @acronyms = acronyms
    @abbreviations = abbreviations
    @enclitics = enclitics
    @peripheric_regexp = @dw.get_peripheric_regexp
    @original_first_lower = false # Used by ProperNounsProcessor
    @first_token = Token.new(self.text, nil, :begin_sentence, -1, -1)
    @last_token = Token.new(self.text, nil, :end_sentence, -1, -1)
    @current_last_token = @first_token
    @current_text_offset = 0

    proper_nouns_processor.call(text).each do |segment|
      segment.is_a?(String) ? add_chunk(segment) : add_proper_noun(segment.text, segment.tag_lemmas)
    end
    finish
  end


  def add_chunk(text)
    return if text.blank?

    build_sentence_tokens(tokenize(text), text)
  end

  def finish
    @current_last_token.add_next(@last_token)
    @last_token.add_prev(@current_last_token)
    process_acronym_abbreviation_contraction_stuff
    first_to_lower
  end

  def empty?
    if @text =~ /^[ ]*$/
      return true
    else
      return false
    end
  end

  def tokenize(text)
    local_text = String.new(text)
    # STDERR.puts "local_text: #{local_text}, removed_info: #{removed_info}"
    # Remove several spaces due to tag removing inside text
    local_text.gsub!(/ +/, " ")
    local_text.gsub(/^ +/, "")

    # Dots are separated from previous and next words
    local_text.gsub!(/([^ ])(\.\.\.)/, '\1 \2')
    local_text.gsub!(/(\.\.\.)([^ ])/, '\1 \2')


    # workaround for acoutacións. By now we'll not allow abbreviations
    # followed by ) or "
    local_text.gsub!(/([a-zñA-ZÑáéíóúÁÉÍÓÚ])\.([)"])$/, '\1 . \2')

    tokens = local_text.split(/ |([;¡!¿\?"\[\]_])/)

    # ESLORA workaround
    tokens = merge_pausa_larga(tokens)

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
      elsif token =~ /(^https?:\/\/.+)(\.)?/
          tokens_new << $1 if $1 and $1 != ""
          tokens_new << $2 if $2 and $2 != ""
      # We separate ,:'- from not numeric words and simbols at the end of any word and -' at the beginning
      elsif token != "" and token =~ /^(['\-\()]?)(['\-\()]?)([\p{L}0-9<\/>\+\-=º@.]+)([']?)([.,:\-\)]?)([.,:\-\)]?)$/
        tokens_new << $1 if $1 and $1 != ""
        tokens_new << $2 if $2 and $2 != ""
        tokens_new << $3 if $3 and $3 != ""
        tokens_new << $4 if $4 and $4 != ""
        tokens_new << $5 if $5 and $5 != ""
        tokens_new << $6 if $6 and $6 != ""
      # We separate ,:'-) from numbers at the end of any word
      elsif token != "" and token =~ /^([\(]?)([\-]?[0-9]+[,\.]?[0-9+]?)([,:'\-\)]?)$/
        tokens_new << $1 if $1 and $1 != ""
        tokens_new << $2 if $2 and $2 != ""
        tokens_new << $3 if $3 and $3 != ""
      # Allow parens as prefixes inside words: (des)orde
      elsif token != "" and token =~ /\A\((?=\p{L}+\)\p{L}+)/
        tokens_new.push(*token.split(/([,:'])/).reject { |t| t == "" })
      # Allow parens as suffixes inside words: todos(as)
      elsif token != "" and token =~ /\A\p{L}+\(\p{L}+\)/
        tokens_new.push(*token.split(/([,:'])/).reject { |t| t == "" })
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

    # Numbers separated by spaces detection
    tokens_new = Array.new
    index = 0
    while (index < tokens.size)
      token = tokens[index]
      if token =~ /^[0-9]+$/ and (index < tokens.size)
        new_token = token
        new_full_token = "#{new_token}"
        new_index = index + 1
        new_token = tokens[new_index]
        while new_token =~ /^[0-9]+$/ and (new_index < tokens.size)
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
    if tokens.last =~ /([^\.]+)\.$/
      tokens[tokens.length - 1] = $1
      tokens << "."
    end
    # STDERR.puts "token.size: #{tokens.size}"
    # STDERR.puts "(tokenize) tokens (final):#{tokens}"

    return tokens
  end

  def merge_pausa_larga(tokens)
    i = 0
    result = []
    while i < tokens.length
      if tokens[i] == '<pausa' && tokens[i + 1] == '_' && tokens[i + 2] == 'larga/>'
        result << '<pausa_larga/>'
        i += 3
      else
        result << tokens[i]
        i += 1
      end
    end
    result
  end

  def build_sentence_tokens(tokens, text)
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
      #STDERR.puts "Building token: #{token.text}, from:#{token.from}, to:#{token.to}, chunk_entity_exclude_transform:#{token.chunk_entity_exclude_transform}"
      offset = to + 1
      token.add_prev(prev_token)
      prev_token.add_next(token)
      prev_token = token
    end
    @current_last_token = prev_token
    @current_text_offset += text.length
  end

  def add_proper_noun(text, tag_lemmas)
    token = Token.new(self.text, text, :standard, @current_text_offset, @current_text_offset + text.length - 1)
    tag_lemmas.each { |tag, lemma| token.add_tag_lemma_emission(tag, lemma, '', 0.0, false) }
    token.proper_noun = true
    token.add_prev(@current_last_token)
    @current_last_token.add_next(token)
    @current_last_token = token
    @current_text_offset += text.length
  end

  def process_acronym_abbreviation_contraction_stuff

    #### Last token check for acronym, abbreviation or contraction

    last_token = @last_token.prev
    if last_token.nexts_ignored.empty?
      #STDERR.puts "last_token: #{last_token.text} last_token_type: #{last_token.token_type}"

      # If last token is an acronym or abbreviation, we check if it is a contraction
      # or it is included in the lexicon to build the alternatives.

      if last_token.text =~ /\.$/ and (@acronyms[last_token.text] != nil or @abbreviations[last_token.text] != nil)
        # STDERR.puts "last token is acronym or abbreviation and last_tokens ends with dot"
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
  def full_ignored?
    token = @first_token
    while token
      return false if token.token_type == :standard
      token = token.next
    end
    return true
  end

  def contractions_processing
    processor = ContractionsProcessor.new(self, @dw)
    processor.process
  end

  def idioms_processing
    processor = IdiomsProcessor.new(self, @dw)
    processor.process
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

  private

  def peripheric?(tag)
    result = tag =~ /#{@peripheric_regexp}/
    return result
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
    if (token.token_type == :standard) &&
      (token.text.length == 1 || (
        token.text.length > 1 &&
          @acronyms[token.text] == nil &&
          @abbreviations[token.text] == nil &&
          !token.proper_noun)
      )
      token.replace_text(StringUtils.first_to_lower(token.text))
    end
    #STDERR.puts "first token after first_to_lower: #{token.text}"
  end
end
