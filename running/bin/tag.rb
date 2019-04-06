# -*- coding: utf-8 -*-
require_relative 'delta.rb'
require_relative 'token.rb'

class Tag

  attr_reader :value, :lemmas, :hiperlemmas, :emission, :deltas, :ordered_deltas, :token
  attr_writer :selected
  
  def initialize(value, lemma, hiperlemma, token)
    @selected = false # it indicates if Viterbi algorithm has been selected it as the most probable tag.
    @value = value
    @lemmas = Hash.new
    @hiperlemmas = Hash.new
    @lemmas[lemma] = true unless lemma == nil
    @hiperlemmas[lemma] = hiperlemma unless hiperlemma == nil
    @token = token
    @deltas = Hash.new
    @ordered_deltas = Array.new
    @emission = nil
  end

  def reset_viterbi
    @deltas = Hash.new
    @ordered_deltas = Array.new
    @selected = false
  end

  def maximum_delta
    return @ordered_deltas.first
  end

  def add_emission(emission)
    @emission = emission
  end
  
  def add_lemma(lemma, hiperlemma)
    @lemmas[lemma] = true
    @hiperlemmas[lemma] = hiperlemma
  end
 
  def add_or_replace_delta(delta_value, prev_delta, length, prev_tag_value)
    # we store the maximum delta for each prev_tag_value
    # prev_tag_value is prev_tag plus token id and token id is
    # necessary because we can reach this delta throw differente
    # tokens with the same tag (and, so, we have to store two deltas
    # for one tag). This is related with alternativas and prunning
    # rules (see cara a pruning rules as examples).

    delta_object = Delta.new(delta_value, prev_delta, length, self)
    #puts "add_or_replace_delta delta_object prev_tag_value:#{prev_tag_value} value:#{delta_object.value}, normalized:#{delta_object.normalized_value} length:#{delta_object.length}"
    old_delta = @deltas[prev_tag_value]
    unless old_delta == nil
      @ordered_deltas.delete(old_delta)
    end
    @deltas[prev_tag_value] = delta_object
    insert_ordered_delta(delta_object)
    
    #if (@maximum_delta == nil) or (@maximum_delta.normalized_value < delta_object.normalized_value)
    #  @maximum_delta = delta_object
    #  # puts "setting maximum_delta normalized value: #{@maximum_delta.normalized_value}"
    #end
  end
  
  def lemmas?
    if @lemmas == nil or @lemmas.empty?
      return false
    else
      return true
    end
  end
  
  def emission?
    if @emission == nil
      return false
    else
      return true
    end
  end

  def selected?
    return @selected
  end

  private

  def insert_ordered_delta(delta_object)
    @ordered_deltas << delta_object
    @ordered_deltas = @ordered_deltas.sort_by{|delta| delta.normalized_value}.reverse
    # REIMPLEMENT THIS FUNCTION !!!
    #last_index = 0
    # @ordered_deltas.each_index do |index|
    #  last_index = index
    #  puts "delta_object.normalized_value:#{delta_object.normalized_value} ordered_deltas[index]:#{@ordered_deltas[index].normalized_value}"
    #  if delta_object.normalized_value > @ordered_deltas[index].normalized_value
    #    break;
    #  end
    #end
    #if (last_index != 0) and (last_index == @ordered_deltas.size-1)
    #  last_index = last_index + 1
    #end
    #puts "last_index:#{last_index}"
    # @ordered_deltas.insert(last_index, delta_object)
  end
end
