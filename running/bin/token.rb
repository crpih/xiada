# -*- coding: utf-8 -*-
require 'yaml'
require_relative 'sentence.rb'
require_relative 'tag.rb'
class Token

  attr_accessor :prevs, :nexts, :text, :token_type, :tags, :token_id, :from_viterbi, :tagged, :nexts_ignored, :chunk_entity_exclude_transform, :from, :to, :nexts_ignored, :qualifying_info, :length # ??? from and to must be updated throw change_from and change_to

  def initialize(sentence_text, text, type, from, to)
    @sentence_text = sentence_text # Necessary because Marshall does not work with sentence itself.
    @text = text
    @token_type = type # :begin_sentence :end_sentence :begin_alternative :end_alternative :standard
    @from = from
    @to = to
    @nexts = Hash.new
    @nexts_ignored = Array.new
    @prevs = Hash.new
    @tags = Hash.new
    @tagged = false
    @from_viterbi = false # It indicates if it was tagged by Viterbi algorithm
    assign_id
    @qualifying_info = Hash.new
    @chunk_entity_exclude_transform = false
  end

  def add_qualifying_info(qualifying_info)
    unless @qualifying_info[qualifying_info]
      @qualifying_info[qualifying_info] = true
    end
  end

  def add_qualifying_info_array(qualifying_info_array)
    qualifying_info_array.each do |qualifying_info|
      unless @qualifying_info[qualifying_info]
        @qualifying_info[qualifying_info] = true
      end
    end
  end

  def add_nexts_ignored(token_text, qualifying_info)
    #STDERR.puts "(adding_nexts_ignored): token_text:#{token_text}, qualifying_info:#{qualifying_info}"
    new_token = Token.new(@sentence_text,"#{token_text}",@type,@from,@to)
    new_token.add_qualifying_info_array(qualifying_info) if qualifying_info
    @nexts_ignored << new_token
  end

  def reset_viterbi
    if from_viterbi
      @tagged = false
      @tags = Hash.new
    end
    @from_viterbi = false
    @tags.each do |tag, tag_object|
      tag_object.reset_viterbi
    end
  end

  def deep_copy
    token = Marshal.load(Marshal.dump(self))
    token.assign_id
    return token
  end

  def deep_copy_reset_links
    token = Token.new(@sentence_text.dup, @text.dup, @token_type, @from, @to)
    token.nexts_ignored = Marshal.load(Marshal.dump(@nexts_ignored))

    # FIXME: Horrors ahead!
    # Here be dragons! Deep copy of tags and tag objects to prevent ruby from crashing on marshall dump.
    # The problem is that the tag objects have a reference to the token object, and the token object has a reference to the tag object.
    # This is a circular reference that makes ruby crash when trying to marshall dump the token object.
    # Probably a ruby bug, but we cannot reproduce it and our current version (2.7.2) is unsupported.
    token.tags = @tags.each_with_object({}) do |(tag, tag_object), result|
      tag_copy = tag_object.dup
      tag_copy.instance_variable_set(:@token, nil)
      tag_deep_copy = Marshal.load(Marshal.dump(tag_copy))
      tag_deep_copy.instance_variable_set(:@token, token)
      result[tag] = tag_deep_copy
    end
    token.tagged = @tagged
    token.from_viterbi = @from_viterbi
    token.qualifying_info = Marshal.load(Marshal.dump(@qualifying_info))
    token.chunk_entity_exclude_transform = @chunk_entity_exclude_transform
    return token
  end

  def tagged?
    return @tagged
  end

  def add_tag_lemma_emission(tag, lemma, hiperlemma, emission, from_viterbi)
    @tagged = true
    @from_viterbi = from_viterbi
    tag_object = @tags[tag]
    if tag_object == nil
      tag_object = Tag.new(tag, lemma, hiperlemma, self)
      tag_object.add_emission(emission)
      @tags[tag] = tag_object
    else
      tag_object.add_emission(emission) unless tag_object.emission?
      tag_object.add_lemma(lemma, hiperlemma) if lemma
    end
  end

  def add_tags_lemma_emission(tags_array, lemma, hiperlemma, emission, from_vierbi)
    tags_array.each do |tag|
      add_tag_lemma_emission(tag, lemma, hiperlemma, emission, from_viterbi)
    end
  end

  def add_next(token)
    @nexts[token] = 1
  end

  def remove_next(token)
    @nexts.delete(token)
  end

  def reset_nexts
    @nexts = Hash.new
  end

  def replace_nexts(nexts)
    @nexts = nexts
  end

  def add_prev(token)
    @prevs[token] = 1
  end

  def remove_prev(token)
    @prevs.delete(token)
  end


  def reset_prevs
    @prevs = Hash.new
  end

  def replace_prevs(prevs)
    @prevs = prevs
  end

  def replace_text(text)
    @text = text
  end

  # Valid when there are only one next. Returns the first next.
  def next
    if @nexts.empty?
      return nil
    else
      @nexts.keys.each do |key|
        return key
      end
    end
  end

  # Valid when there are only one prev. Returns the first prev.
  def prev
    if @prevs.empty?
      return nil
    else
      @prevs.keys.each do |key|
        return key
      end
    end
  end

  def last
    return @nexts.empty?
  end

  def first
    return @prevs.empty?
  end

  def size_nexts
    return @nexts.length
  end

  def size_prevs
    return @prevs.length
  end

  def replace_text(text)
    @text = text
  end

  def some_tag_selected?
    @tags.each do |tag, tag_object|
      return true if tag_object.selected?
    end
    return false
  end

  def change_from(from)
    @from = from
  end

  def change_to(to)
    @to = to
  end

  def self.reset_class
    @@id_counter = 1
  end

  def get_unit
    #puts "token: #{text} from: #{@from} to:#{@to}"
    if @from!=-1 and @to!=-1
      return get_text(@from, @to)
    else
      return nil
    end
  end

  protected

  # This id is necessary for prunning rules to work properly. Several
  # diferent alternatives could end with the same word+tag so token_id
  # make them different.

  def assign_id
    @token_id = @@id_counter
    @@id_counter = @@id_counter + 1
  end

  private

  def get_text(from, to)
    return (@sentence_text[from..to])
  end


end
