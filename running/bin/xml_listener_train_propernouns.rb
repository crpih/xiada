# -*- coding: utf-8 -*-

class XMLListenerTrainProperNouns

  def initialize(xml_values, dw, acronyms_hash, abbreviations_hash, enclitics_hash)
    STDERR.puts "Training proper nouns..."
    @xml_values = xml_values
    @dw = dw
    @acronyms_hash = acronyms_hash
    @abbreviations_hash = abbreviations_hash
    @enclitics_hash = enclitics_hash
    @inside_sentence = false
    @chunk = ""
    @sentence = nil
    @trained_proper_nouns = {}
  end

  def tag_start(name, attributes)
    if sentence_tag?(name)
      @inside_sentence = true
      @sentence = Sentence.new(@dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, false)
      @chunk = ""
    end
  end

  def tag_end(name)
    if sentence_tag?(name)
      @sentence.add_chunk(@chunk, nil, nil, nil, nil)
      @sentence.finish
      train
      @inside_sentence = false
    end
  end

  def text(text)
    if @inside_sentence
        @chunk << text
    end
  end

  def xmldecl(version, encoding, standalone)
    #puts "<?xml version=\"#{version}\" encoding=\"#{encoding}\"?>"
  end

  def doctype(name, pub_sys, long_name, uri)
    #puts "<!DOCTYPE #{name} #{pub_sys} \"#{long_name}\">"
  end

  def method_missing(*args)
    #puts "missing: #{args.inspect}"
  end

  def get_trained_proper_nouns
    return @trained_proper_nouns
  end

  private

  def train
    # STDERR.puts "Sentence text: #{@sentence.text}"
    @sentence.add_proper_nouns(@trained_proper_nouns)
    # @trained_proper_nouns.keys.each do |proper_noun|
    #  STDERR.puts "proper_noun: #{proper_noun}"
    # end
  end

  def sentence_tag?(name)
    if name == @xml_values["sentence_tag"][0]
      return true
    else
      return false
    end
  end
end
