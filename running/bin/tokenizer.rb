# -*- coding: utf-8 -*-
class Tokenizer
  def initialize(source_sentence)
    @source_sentence = String.new(source_sentence)
    @current_position = 0
    @current_subtoken_position = 0
    @tokens = preprocess_text
  end

  def get_next_token
  end

  private

  def preprocess_text
    sentence = String.new(@source_sentence)
    sentence.gsub!(/([^ ])(\.\.\.)/,'\1 \2')
    sentence.gsub!(/(\.\.\.)([^ ])/,'\1 \2')

    tokens = sentence.split(/ |([¡!;¿\?"\(\)\[\]_])/)
    tokens_new = Array.new
    tokens.each_index do |index|
      token = tokens[index]
      
      
      # If a number ends with point, we separate this point in a new
      # token (it occurs in identifiers at the begining of the
      # sentence), else we separate ",", ":" e "'" from not numeric
      # words

      if token=~/^([0-9]+([.,\/:'][0-9]+)*)\.$/
        tokens_new << $1
        tokens_new << "."
      elsif token != ""
        tokens_aux = token.split(/([,:'])/)
        tokens_aux.each do |token_aux|
          tokens_new << token_aux if token_aux!=""
        end
      end
    end

    tokens = tokens_new

    # Detection of numbers separated by spaces
    tokens_new = Array.new
    index = 0
    while (index < tokens.size)
      token = tokens[index]
      if token=~/[0-9]+/ and (index < tokens.size)
        new_token = token
        new_full_token = "#{new_token}"
        new_index = index+1
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
  end
  @tokens = tokens
end
