# -*- coding: utf-8 -*-

class Suffixes

  attr_reader :suffixes_tags_freqs, :suffixes_tags_probs, :theta

  def initialize(empty_word, max_suffix_length, max_occurrences, words)
    @words = words
    @empty_word = empty_word
    @max_suffix_length = max_suffix_length
    @max_occurrences = max_occurrences
    @length_tags_freqs = Hash.new
    @tags_freqs = Hash.new
    @tags_freqs_count = 0
    @frequencies = Hash.new
    @suffixes_tags_freqs = Hash.new
    @suffixes_tags_probs = Hash.new
    @theta = 0
    @word_for_suffixes_count = 0
  end
  
  def calculate_frequencies
    @words.frequencies.each do |key, freq|
      word,tag = key.split(/&&&/)
      if (word != @empty_word) and (@words.get_frequency(word,tag) <= @max_occurrences)
        @word_for_suffixes_count = @word_for_suffixes_count + 1
        #puts "word:#{word},tag:#{tag},freq:#{freq}"
        (1..freq).each do |value|
          #puts "value:#{value}"
          add_word(word, tag)
        end
      end
    end
  end
  
  def add_word(word, tag)
    #unless proper_noun_or_closed(tag)
      #puts "word:#{word}, tag:#{tag}"
      max_length = @max_suffix_length
      max_length = word.length-1 if (word.length-1) < @max_suffix_length
      (1..max_length).each do |suffix_length|
        suffix = word[word.length-suffix_length,suffix_length]
        #puts "length:#{suffix_length} suffix:#{suffix}"
        add_suffix(suffix)
        add_suffix_tag(suffix,tag)
        add_tag(suffix_length,tag)
      end
    #end
  end
  
  def calculate_probabilities
    calculate_first_probabilities
    
    s = @words.tag_frequencies.keys.length - 1
    puts "s:#{s}"
    
    mean_p = Float(1) / s
    puts "mean_p:#{mean_p}"
    puts "word_for_suffixes_count: #{@word_for_suffixes_count}"
    puts "tags_freqs_count: #{@tags_freqs_count}"
    exit
    sum = 0
    # ???
    #@tags_freqs.each do |tj, frequency|
    #  sum = sum + ((Float(frequency) / @tags_freqs_count) - mean_p) ** 2
    #end
    
    @words.tag_frequencies.each do |tj, frequency|
      sum = sum + ((Float(frequency) / @words.corpus_size) - mean_p) ** 2
    end
    
    puts "sum:#{sum}"

    @theta = sum / (s-1)
    puts "theta:#{@theta}"
    #puts "entries:#{get_suffixes_tags_freqs_number}"
    
    # Now we recalculate probabilities
    array_order = Array.new(@max_suffix_length) {Array.new}
    @suffixes_tags_freqs.keys.each do |key|
      suffix,tag = key.split(/&&&/)
      array_item = array_order[suffix.length-1]
      array_item << key
      #puts "suffix:#{suffix}, length:#{suffix.length}, array_item:#{array_item}, array_order:#{array_order}"
    end
    
    array_order.each_index do |index|
      array_length = array_order[index]
      array_length.each do |suffix_tag|
        suffix,tag = suffix_tag.split(/&&&/)
        #puts "index:#{index}, suffix_tag:#{suffix_tag}"
        if (index != 0)
          @suffixes_tags_probs[suffix_tag] = (@suffixes_tags_probs[suffix_tag] +
            theta * get_suffix_tag_prob_prev(suffix, tag))/(1+theta)
        else
          @suffixes_tags_probs[suffix_tag] = (@suffixes_tags_probs[suffix_tag] +
            theta * (@tags_freqs[tag]/@tags_freqs_count))/(1+theta)
        end
      end
    end
    
    # And finally, Bayes inversion
    
    @suffixes_tags_probs.keys.each do |key|
      suffix,tag = key.split(/&&&/)
      tags_key = suffix.length.to_s()+"&&&"+tag
      @suffixes_tags_probs[key] = Math.log(@suffixes_tags_probs[key] * @frequencies[suffix] / @length_tags_freqs[tags_key])
    end
    
  end

  def get_suffix_component(key)
    suffix,tag = key.split(/&&&/)
    return suffix
  end

  def get_tag_component(key)
    suffix,tag = key.split(/&&&/)
    return tag
  end
  
  def get_frequency(suffix, tag)
    key = suffix + "&&&" + tag
    return @suffixes_tags_freqs[key]
  end
  
  def get_probability(suffix, tag)
    key = suffix + "&&&" + tag
    return @suffixes_tags_probs[key]
  end
  
  def get_suffixes_tags_freqs_number
    return @suffixes_tags_freqs.keys.length
  end

  private
  
  def get_suffix_tag_prob_prev(suffix, tag)
    prev_suffix = suffix[1,suffix.length-1]
    return @suffixes_tags_probs[prev_suffix+"&&&"+tag]
  end
  
  def add_suffix(suffix)
    if @frequencies[suffix] == nil
      @frequencies[suffix] = 1
    else
      @frequencies[suffix] = @frequencies[suffix] + 1
    end
  end
  
  def add_suffix_tag(suffix, tag)
    key = suffix+"&&&"+tag
    if @suffixes_tags_freqs[key] == nil
      @suffixes_tags_freqs[key] = 1
    else
      @suffixes_tags_freqs[key] = @suffixes_tags_freqs[key] + 1
    end
  end
  
  def add_tag(suffix_length, tag)
    key = suffix_length.to_s()+"&&&"+tag
    if @length_tags_freqs[key] == nil
      @length_tags_freqs[key] = 1
    else
      @length_tags_freqs[key] = @length_tags_freqs[key] + 1
    end
    
    @tags_freqs_count = @tags_freqs_count + 1
    if @tags_freqs[tag] == nil
      @tags_freqs[tag] = 1
    else
      @tags_freqs[tag] = @tags_freqs[tag] + 1
    end
  end
  
  def calculate_first_probabilities
    @suffixes_tags_freqs.each do |key, freq|
      suffix,tag = key.split(/&&&/)
      @suffixes_tags_probs[key] = Float(freq) / @frequencies[suffix]
    end
  end
  
  def proper_noun_or_closed(tag)
    result = tag=~/Sp|P|C|D|E|T|M|I|R|G|L|Q/
    return result
  end
  
end
