# -*- coding: utf-8 -*-
require 'gdbm'

class Ngrams

  attr_reader :unigrams, :bigrams, :trigrams, :lambda1, :lambda2, :lambda3,
              :unigrams_s, :bigrams_s, :trigrams_s, :corpus_size, :real_corpus_size

  def initialize(empty_tag, memmory)
    @empty_tag = empty_tag
    @memmory = memmory
    if @memmory
      @unigrams = Hash.new
      @bigrams = Hash.new
      @trigrams = Hash.new
      @unigrams_a = Hash.new
      @bigrams_a = Hash.new
      @trigrams_a = Hash.new
    else
      @unigrams = GDBM.new('unigrams.data', 0666, GDBM::NEWDB)
      @bigrams = GDBM.new('bigrams.data', 0666, GDBM::NEWDB)
      @trigrams = GDBM.new('trigrams.data', 0666, GDBM::NEWDB)
      @unigrams_a = GDBM.new('unigrams_a.data', 0666, GDBM::NEWDB)
      @bigrams_a = GDBM.new('bigrams_a.data', 0666, GDBM::NEWDB)
      @trigrams_a = GDBM.new('trigrams_a.data', 0666, GDBM::NEWDB)
    end
    @lambda1 = 0
    @lambda2 = 0
    @lambda3 = 0
    @corpus_size = 0
    @real_corpus_size = 0
  end

  def add_unigram(tag)
    @corpus_size = @corpus_size + 1
    @real_corpus_size = @real_corpus_size + 1 unless tag == @empty_tag
    # puts "Inserting unigram: #{tag}"
    if @unigrams[tag] == nil
      @unigrams[tag] = 1 if @memmory
      @unigrams[tag] = "1" unless @memmory
    else
      @unigrams[tag] = @unigrams[tag] + 1 if @memmory
      @unigrams[tag] = "#{@unigrams[tag].to_i + 1}" unless @memmory
    end
  end

  def add_bigram(tag_prev, tag)
    # puts "Inserting bigram tag_prev: #{tag_prev} tag:#{tag}"
    key = tag_prev+"&"+tag
    if @bigrams[key] == nil
      @bigrams[key] = 1 if @memmory
      @bigrams[key] = "1" unless @memmory
    else
      @bigrams[key] = @bigrams[key] + 1 if @memmory
      @bigrams[key] = "#{@bigrams[key].to_i + 1}" unless @memmory
    end
  end
  
  def add_trigram(tag_prev_prev, tag_prev, tag)
    key = tag_prev_prev+"&"+tag_prev+"&"+tag
    #puts "Inserting trigram: #{key}"
    if @trigrams[key] == nil
      @trigrams[key] = 1 if @memmory
      @trigrams[key] = "1" unless @memmory
    else
      @trigrams[key] = @trigrams[key] + 1 if @memmory
      @trigrams[key] = "#{@trigrams[key].to_i + 1}" unless @memmory
    end
  end

  def get_unigram_frequency(tag)
    if @unigrams.key?(tag)
      return @unigrams[tag] if @memmory
      return @unigrams[tag].to_i unless @memmory
    else
      return 0
    end
  end
  
  def get_unigram_a(tag)
    if @unigrams.key?(tag)
      return @unigrams_a[tag] if @memmory
      return @unigrams_a[tag].to_f unless @memmory
    else
      return 0
    end
  end
  
  def get_bigram_frequency(tag_prev, tag)
    key = tag_prev+"&"+tag
    if @bigrams.key?(key)
      return @bigrams[key] if @memmory
      return @bigrams[key].to_i unless @memmory
    else
      return 0
    end
  end
  
  def get_bigram_a(tag_prev, tag)
    key = tag_prev+"&"+tag
    if @bigrams_a.key?(key)
      return @bigrams_a[key] if @memmory
      return @bigrams_a[key].to_f unless @memmory
    else
      return 0
    end
  end
  
  def get_trigram_frequency(tag_prev_prev, tag_prev, tag)
    key = tag_prev_prev+"&"+tag_prev+"&"+tag
    if @trigrams.key?(key)
      return @trigrams[key] if @memmory
      return @trigrams[key].to_i unless @memmory
    else
      return 0
    end
  end
  
  def get_trigram_a(tag_prev_prev, tag_prev, tag)
    key = tag_prev_prev+"&"+tag_prev+"&"+tag
    if @trigrams_a.key?(key)
      return @trigrams_a[key] if @memmory
      return @trigrams_a[key].to_f unless @memmory
    else
      return 0
    end
  end
  
  def calculate_lambdas

    n = unigrams.length
    
    trigrams.keys.each do |trigram|
      tag_prev_prev, tag_prev, tag = trigram.split(/&/)

      t1t2t3_frequency = get_trigram_frequency(tag_prev_prev,tag_prev,tag)
      t1t2_frequency = get_bigram_frequency(tag_prev_prev,tag_prev)
      t2t3_frequency = get_bigram_frequency(tag_prev,tag)
      t2_frequency = get_unigram_frequency(tag_prev)
      t3_frequency = get_unigram_frequency(tag)
      
      value1 = 0.0
      value2 = 0.0
      value3 = 0.0
      value3 = Float(t1t2t3_frequency-1)/(t1t2_frequency-1) if t1t2_frequency != 1
      value2 = Float(t2t3_frequency-1)/(t2_frequency-1) if (t2_frequency != 1) and (t2t3_frequency != 0)
      value1 = Float(t3_frequency-1)/(@corpus_size-1) if @corpus_size != 1
      
      index = max_index(value1,value2,value3)
      
      @lambda1 = @lambda1+t1t2t3_frequency if index == 1
      @lambda2 = @lambda2+t1t2t3_frequency if index == 2
      @lambda3 = @lambda3+t1t2t3_frequency if index == 3

    end

    normalize_lambdas

  end
  
  def calculate_as    
    unigrams.keys.each do |unigram|
      unigram_t1_frequency = get_unigram_frequency(unigram) # c3 in GraÃ±a code
      a3_log = Math.log(Float(unigram_t1_frequency) / @corpus_size * @lambda1)
      @unigrams_a[unigram] = a3_log if @memmory
      @unigrams_a[unigram] = "#{a3_log}" unless @memmory
    end
    
    bigrams.keys.each do |bigram|
      bigram_frequency = get_bigram_frequency(get_first_component(bigram), get_second_component(bigram)) # c23 in GraÃ±a code
      unigram_t1_frequency = get_unigram_frequency(get_first_component(bigram))
      unigram_t2_frequency = get_unigram_frequency(get_second_component(bigram))      
      a3 = Float(unigram_t2_frequency) / @corpus_size * @lambda1
      a2_log = Math.log((Float(bigram_frequency) / unigram_t1_frequency * @lambda2) + a3)
      @bigrams_a[bigram] = a2_log if @memmory
      @bigrams_a[bigram] = "#{a2_log}" unless @memmory
    end
    
    trigrams.keys.each do |trigram|
      trigram_frequency = get_trigram_frequency(get_first_component(trigram), get_second_component(trigram), get_third_component(trigram)) # c123 en GraÃ±a code
      bigram_t1t2_frequency = get_bigram_frequency(get_first_component(trigram), get_second_component(trigram))
      bigram_t2t3_frequency = get_bigram_frequency(get_second_component(trigram), get_third_component(trigram))
      unigram_t1_frequency = get_unigram_frequency(get_first_component(trigram))
      unigram_t2_frequency = get_unigram_frequency(get_second_component(trigram))
      unigram_t3_frequency = get_unigram_frequency(get_third_component(trigram))
      a3 = Float(unigram_t3_frequency) / @corpus_size * @lambda1
      a2 = Float(bigram_t2t3_frequency) / unigram_t2_frequency * @lambda2 + a3
      a1_log = Math.log(Float(trigram_frequency) / bigram_t1t2_frequency * @lambda3 + a2)
      @trigrams_a[trigram] = a1_log if @memmory
      @trigrams_a[trigram] = "#{a1_log}" unless @memmory
    end
  end

  def get_first_component (bigram_or_trigram_key)
    components = bigram_or_trigram_key.split(/&/)
    return components[0]
  end
  
  def get_second_component (bigram_or_trigram_key)
    components = bigram_or_trigram_key.split(/&/)
    return components[1]
  end
  
  def get_third_component (trigram_key)
    components = trigram_key.split(/&/)
    return components[2]
  end
  
  private
  
  def max_index(value1,value2,value3)
    if value3 > value2
      if value3 > value1
        index = 3
      else
        index = 1
      end
    else
      if value2 > value1
        index = 2
      else
        index = 1
      end
    end
    return index
  end 

  def normalize_lambdas
    sum = @lambda1 + @lambda2 + @lambda3
    @lambda1 = Float(@lambda1)/sum
    @lambda2 = Float(@lambda2)/sum
    @lambda3 = Float(@lambda3)/sum
  end
    
end
