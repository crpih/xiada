# -*- coding: utf-8 -*-
require_relative "../../lib/string_utils.rb"

class XMLListener
  def initialize(xml_values, dw, acronyms_hash, abbreviations_hash, enclitics_hash, trained_proper_nouns, valid_opt, remove_join_opt, force_proper_nouns)
    # STDERR.puts "Analizing sentence..."
    @xml_values = xml_values
    @dw = dw
    @acronyms_hash = acronyms_hash
    @abbreviations_hash = abbreviations_hash
    @enclitics_hash = enclitics_hash
    @trained_proper_nouns = trained_proper_nouns
    @valid_opt = valid_opt
    @remove_join_opt = remove_join_opt
    @force_proper_nouns = force_proper_nouns

    @inside_sentence = false

    @ignoring_tags = Hash.new
    @ignoring_inline_start_tags = Hash.new
    @ignoring_inline_end_tags = Hash.new
    @ignoring_inline_conversions = Hash.new

    @qualifying_tags = Hash.new
    @qualifying_inline_start_tags = Hash.new
    @qualifying_inline_end_tags = Hash.new
    @qualifying_inline_conversions = Hash.new
    @not_segment_content_tags = Hash.new

    @active_ignoring_tags = Hash.new
    @active_qualifying_tags = Hash.new
    @active_not_segment_content_tags = Hash.new

    @expression = "" # text to show in expression
    @chunk = "" # text to tag
    @sentence = nil
    @exclude_from_chunk_tags = Hash.new
    @sentence_tag_attributes = ""

    @empty_tags_included_info = Hash.new
    @qualifying_internal_tags = Hash.new
    @ignoring_internal_tags = Hash.new

    load_ignore_info
    load_qualifying_info
    load_empty_tags_included_info
    load_not_segment_content_tags_info
  end

  def comment(comment)
    # STDERR.puts "COMMENT:comment"
  end

  def tag_start(name, attributes)
    tag_attrs_str = compound_tag_attrs_str(name, attributes)
    attribute_names = attributes.keys
    ignoring_internal_name = @ignoring_internal_tags[name]
    qualifying_internal_name = @qualifying_internal_tags[name]
    #STDERR.puts "\n\ntag_start: <#{name}>, ignoring_internal_name: #{ignoring_internal_name}, qualifying_internal_name: #{qualifying_internal_name}"
    #STDERR.puts "@active_qualifying_tags: #{@active_qualifying_tags}\n\n"
    if sentence_tag?(name)
      @sentence = Sentence.new(@dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, @force_proper_nouns)
      @inside_sentence = true
      @chunk = ""
      @expression = ""
      @sentence_tag_attributes = compound_only_attrs_str(attributes)
      if tag_attributes_included?(ignoring_internal_name, attribute_names, @ignoring_tags)
        @active_ignoring_tags[ignoring_internal_name] = extra_info_format(ignoring_internal_name, attributes)
      end
      #STDERR.puts "BEFORE"
      #STDERR.puts "(tag_attributes_included?)qualifying_internal_name: #{qualifying_internal_name} / attribute_names: #{attribute_names} / @qualifying_tags: #{@qualifying_tags}"
      if tag_attributes_included?(qualifying_internal_name, attribute_names, @qualifying_tags)
        #STDERR.puts "QUALIFIED!"
        @active_qualifying_tags[qualifying_internal_name] = extra_info_format(qualifying_internal_name, attributes)
      end
      @to = -1
      @chunk_entity_exclude_transform = Array.new
      @active_not_segment_content_tags = Hash.new
      @chunk_exclude_segmentation = Array.new
      @chunk_exclude_segmentation[0] = Array.new
      @chunk_exclude_segmentation[1] = Array.new
    else
      if @inside_sentence
        is_ignoring_tag = tag_attributes_included?(ignoring_internal_name, attribute_names, @ignoring_tags)
        is_qualifying_tag = tag_attributes_included?(qualifying_internal_name, attribute_names, @qualifying_tags)
        is_empty_tag_included_info = tag_attributes_included?(name, attribute_names, @empty_tags_included_info)
        is_not_segment_content_tag = tag_included?(name, @not_segment_content_tags)
        @active_not_segment_content_tags[name] = true if is_not_segment_content_tag
        #STDERR.puts "@active_not_segment_content_tags:#{@active_not_segment_content_tags}"
        if is_ignoring_tag or is_qualifying_tag or is_empty_tag_included_info and @active_not_segment_content_tags.empty?
          #STDERR.puts "IGNORING:#{is_ignoring_tag} OR/AND QUALIFYING:#{is_qualifying_tag} TAG OR/AND EMPTY_TAG_INCLUDED_INFO:#{is_empty_tag_included_info}"
          #STDERR.puts "process_chunk1"
          process_chunk(@active_ignoring_tags, @active_qualifying_tags) unless @chunk == "" or @chunk =~ /^ +$/
          @active_ignoring_tags[ignoring_internal_name] = extra_info_format(ignoring_internal_name, attributes) if is_ignoring_tag
          @active_qualifying_tags[qualifying_internal_name] = extra_info_format(qualifying_internal_name, attributes) if is_qualifying_tag
          @sentence.add_empty_tag_included_info("<#{name}#{compound_only_attrs_str(attributes)}/>", @active_qualifying_tags.values) if is_empty_tag_included_info
        end

        @expression << tag_attrs_str
        if not @ignoring_tags[ignoring_internal_name] and not @qualifying_tags[qualifying_internal_name] and not @empty_tags_included_info[name]
          @chunk << tag_attrs_str
          from = @to + 1
          to = from + tag_attrs_str.length - 1
          new_from_to = [from, to]
          # STDERR.puts "tag: #{tag_attrs_str} adding from: #{from} to: #{to}"
          @chunk_entity_exclude_transform << new_from_to
          @to = to
          @chunk_exclude_segmentation[0] << from unless @active_not_segment_content_tags.empty?
        end
      else
        if tag_attributes_included?(ignoring_internal_name, attribute_names, @ignoring_tags)
          @active_ignoring_tags[ignoring_internal_name] = extra_info_format(ignoring_internal_name, attributes)
        end
        #STDERR.puts "(tag_attributes_included?)qualifying_internal_name: #{qualifying_internal_name} / attribute_names: #{attribute_names} / @qualifying_tags: #{@qualifying_tags}"
        if tag_attributes_included?(qualifying_internal_name, attribute_names, @qualifying_tags)
          #STDERR.puts "QUALIFIED2!!!"
          @active_qualifying_tags[qualifying_internal_name] = extra_info_format(qualifying_internal_name, attributes)
          #STDERR.puts "@active_qualifying_tags:#{@active_qualifying_tags}"
        end
        print tag_attrs_str
      end
    end
  end

  def tag_end(name)
    #STDERR.puts "tag_end: </#{name}>"
    ignoring_internal_name = @ignoring_internal_tags[name]
    qualifying_internal_name = @qualifying_internal_tags[name]
    #STDERR.puts "ignoring_internal_name: #{ignoring_internal_name}, qualifying_internal_name: #{qualifying_internal_name}"
    if sentence_tag?(name)
      # STDERR.puts "processs_chunk3"
      process_chunk(@active_ignoring_tags, @active_qualifying_tags) unless @chunk == "" or @chunk =~ /^ +$/
      #STDERR.puts "finish"
      @sentence.finish
      analize
      @inside_sentence = false
      @active_ignoring_tags.delete(name)
      @active_qualifying_tags.delete(name)
    else
      if @inside_sentence
        is_not_segment_content_tag = tag_included?(name, @not_segment_content_tags)
        @active_not_segment_content_tags.delete(name) if is_not_segment_content_tag
        closed_tag = "</" + name + ">"
        @expression << closed_tag
        if not @ignoring_tags[ignoring_internal_name] and not @qualifying_tags[qualifying_internal_name] and not @empty_tags_included_info[name]
          @chunk << closed_tag
          from = @to + 1
          to = from + closed_tag.length - 1
          new_from_to = [from, to]
          # STDERR.puts "tag: #{name} adding from: #{from} to: #{to}"
          # STDERR.puts "adding from:#{from} to:#{to}"
          @chunk_entity_exclude_transform << new_from_to
          @to = to
          @chunk_exclude_segmentation[1] << to if @active_not_segment_content_tags.empty?
        end

        is_qualifying_tag = tag_included?(qualifying_internal_name, @qualifying_tags)
        is_ignoring_tag = tag_included?(ignoring_internal_name, @ignoring_tags)
        if is_ignoring_tag or is_qualifying_tag and @active_not_segment_content_tags.empty?
          # STDERR.puts "process_chunk2"
          process_chunk(@active_ignoring_tags, @active_qualifying_tags) unless @chunk == "" or @chunk =~ /^ +$/
          @active_qualifying_tags.delete(qualifying_internal_name) if is_qualifying_tag and not @qualifying_inline_start_tags[name]
          @active_ignoring_tags.delete(ignoring_internal_name) if is_ignoring_tag and not @ignoring_inline_start_tags[name]
        end
      else
        print "</" + name + ">"
        @active_ignoring_tags.delete(ignoring_internal_name)
        @active_qualifying_tags.delete(qualifying_internal_name)
      end
    end
  end

  def text(text)
    #STDERR.puts "text: -#{text}-"
    if text !~ /^[\n]+$/ and text !~ /^\n +\n?/ and text !~ /\n? +\n/ # To avoid extra carriage return
      if @inside_sentence
        @expression << StringUtils.replace_xml_conflicting_characters(text)
        new_text = text
        new_text = text.gsub("<", " < ")
        new_text.gsub!(">", " > ")
        @chunk << "#{StringUtils.replace_xml_entities(new_text)}"
        @to = @to + new_text.length
        # STDERR.puts "new @to: #{@to}"

        # STDERR.puts "@expression: #{@expression}"
        # STDERR.puts "@chunk: #{@chunk}"
      else
        print "#{StringUtils.replace_xml_conflicting_characters(text)}"
      end
    end
  end

  def xmldecl(version, encoding, standalone)
    puts "<?xml version=\"#{version}\" encoding=\"#{encoding}\"?>"
  end

  def doctype(name, pub_sys, long_name, uri)
    puts "<!DOCTYPE #{name} #{pub_sys} \"#{long_name}\">"
  end

  def method_missing(*args)
    puts "missing: #{args.inspect}"
  end

  private

  def extra_info_format(name, attributes)
    result = "#{name}"
    if attributes and !attributes.empty?
      attributes.each do |attr_name, attr_value|
        result << "[#{attr_name}=#{attr_value}]"
      end
    end
    return result
  end

  def compound_tag_attrs_str(name, attributes)
    tag_attrs_str = "<" + name
    attributes.each do |attr_name, attr_value|
      tag_attrs_str << " #{attr_name}=\"#{attr_value}\""
    end
    tag_attrs_str << ">"
    return tag_attrs_str
  end

  def compound_only_attrs_str(attributes)
    tag_attrs_str = ""
    attributes.each do |attr_name, attr_value|
      tag_attrs_str << " #{attr_name}=\"#{attr_value}\""
    end
    return tag_attrs_str
  end

  def tag_attributes_included?(tag, attr_names, hash)
    # STDERR.puts "(tag_attributes_included?)tag: #{tag} / attr_names: #{attr_names} / hash_keys: #{hash.keys}"
    # STDERR.puts "hash[tag]:#{hash[tag]}"
    result = nil
    value = hash[tag]
    unless value
      return nil
    else
      result = Hash.new
      if value == "true"
        content = Array.new
        content << "true"
        result[tag] = content
        return result
      else
        found = false
        content = Array.new
        attr_names.each do |attr_name|
          # STDERR.puts "attr_name: #{attr_name}, value: #{value}"
          if attr_name == value or attr_name =~ /#{value}\|/ or attr_name =~ /\|#{value}/ # temporal workaround
            # STDERR.puts "true"
            found = true
            content << attr_name
          end
        end
        if found
          result[tag] = content
          return result
        else
          return nil
        end
      end
    end
  end

  def tag_included?(tag, hash)
    # STDERR.puts "tag: #{tag} hash: #{hash.keys}"
    # STDERR.puts "hash[tag]:#{hash[tag]}"
    unless hash[tag]
      return false
    else
      return true
    end
  end

  def load_ignore_info
    if @xml_values["ignoring_tags"]
      @xml_values["ignoring_tags"].each do |tag|
        if tag =~ /(.+)\[(.*)\]/
          tag_name = $1
          tag_attribute = $2
          @ignoring_tags[tag_name] = tag_attribute
          @ignoring_internal_tags[tag_name] = tag_name
        else
          @ignoring_tags[tag] = "true"
          # @exclude_from_chunk_tags[tag] = true
          @ignoring_internal_tags[tag] = tag
        end
      end
    end

    ignoring_inline_start_tags = @xml_values["ignoring_inline_start_tags"]
    ignoring_inline_end_tags = @xml_values["ignoring_inline_end_tags"]

    start_tag = nil
    end_tag = nil

    if ignoring_inline_start_tags
      ignoring_inline_start_tags.each_index do |index|
        if index % 2 == 0
          start_tag = ignoring_inline_start_tags[index]
          end_tag = ignoring_inline_end_tags[index]
          # @ignoring_tags[start_tag] = end_tag
          @ignoring_inline_start_tags[start_tag] = end_tag
          # @ignoring_inline_end_tags[end_tag] = start_tag
          # @exclude_from_chunk_tags[start_tag] = true
          # @exclude_from_chunk_tags[end_tag] = true
        else
          common_tag = ignoring_inline_start_tags[index]
          # @ignoring_inline_conversions[start_tag] = common_tag
          # @ignoring_inline_conversions[end_tag] = common_tag
          @ignoring_internal_tags[start_tag] = common_tag
          @ignoring_internal_tags[end_tag] = common_tag
          @ignoring_tags[common_tag] = "true"
        end
      end
    end

    # STDERR.puts "\nIgnoring tags:"
    # @ignoring_tags.keys.each do |tag|
    #   STDERR.puts "#{tag} => #{@ignoring_tags[tag]}"
    # end

    # STDERR.puts "\nIgnoring internal tags:"
    # @ignoring_internal_tags.keys.each do |tag|
    #   STDERR.puts "#{tag} => #{@ignoring_internal_tags[tag]}"
    # end

    # STDERR.puts "Ignore content inline start tags:"
    # @ignoring_inline_start_tags.keys.each do |tag|
    #  STDERR.puts "tag: #{tag} #{@ignoring_inline_start_tags[tag]}"
    # end

    # STDERR.puts "Ignore content inline end tags:"
    # @ignoring_inline_end_tags.keys.each do |tag|
    #  STDERR.puts "tag: #{tag} #{@ignoring_inline_end_tags[tag]}"
    # end
  end

  def load_qualifying_info
    if @xml_values["qualifying_tags"]
      @xml_values["qualifying_tags"].each do |tag|
        if tag =~ /(.+)\[(.*)\]/
          tag_name = $1
          tag_attribute = $2
          @qualifying_tags[tag_name] = tag_attribute
          @qualifying_internal_tags[tag_name] = tag_name
        else
          @qualifying_tags[tag] = "true"
          @qualifying_internal_tags[tag] = tag
        end
      end
      #STDERR.puts "@xml_values[\"qualifying_tags\"]"
      #STDERR.puts @xml_values["qualifying_tags"]
      #STDERR.puts "@qualifying_tags"
      #STDERR.puts @qualifying_tags
    end

    qualifying_inline_start_tags = @xml_values["qualifying_inline_start_tags"]
    qualifying_inline_end_tags = @xml_values["qualifying_inline_end_tags"]

    start_tag = nil
    end_tag = nil

    if qualifying_inline_start_tags
      qualifying_inline_start_tags.each_index do |index|
        if index % 2 == 0
          start_tag = qualifying_inline_start_tags[index]
          end_tag = qualifying_inline_end_tags[index]
          @qualifying_inline_start_tags[start_tag] = end_tag
          # @qualifying_inline_start_tags[start_tag] = "true"
          # @qualifying_inline_end_tags[end_tag] = start_tag
          # @exclude_from_chunk_tags[start_tag] = true
          # @exclude_from_chunk_tags[end_tag] = true
        else
          common_tag = qualifying_inline_start_tags[index]
          # @qualifying_inline_conversions[start_tag] = common_tag
          # @qualifying_inline_conversions[end_tag] = common_tag
          @qualifying_internal_tags[start_tag] = common_tag
          @qualifying_internal_tags[end_tag] = common_tag
          @qualifying_tags[common_tag] = "true"
        end
      end
    end

    # STDERR.puts "\nQualifying tags:"
    # @qualifying_tags.keys.each do |tag|
    # STDERR.puts "#{tag} => #{@qualifying_tags[tag]}"
    # end

    # STDERR.puts "\nQualifying internal tags:"
    # @qualifying_internal_tags.keys.each do |tag|
    # STDERR.puts "#{tag} => #{@qualifying_internal_tags[tag]}"
    # end

    # STDERR.puts "Qualifying inline conversions:"
    # @qualifying_inline_conversions.keys.each do |tag|
    # STDERR.puts "tag: #{tag} #{@qualifying_inline_conversions[tag]}"
    # end

    # STDERR.puts "Qualifying inline start tags:"
    # @qualifying_inline_start_tags.keys.each do |tag|
    #  STDERR.puts "tag: #{tag} #{@qualifying_inline_start_tags[tag]}"
    # end
  end

  def load_empty_tags_included_info
    if @xml_values["empty_tags_included_info"]
      @xml_values["empty_tags_included_info"].each do |tag|
        @empty_tags_included_info[tag] = "true"
      end
    end
    # STDERR.puts "\nEmpty tags included info:"
    # @empty_tags_included_info.keys.each do |tag|
    #   STDERR.puts "#{tag} => #{@empty_tags_included_info[tag]}"
    # end
  end

  def load_not_segment_content_tags_info
    if @xml_values["not_segment_content_tags"]
      @xml_values["not_segment_content_tags"].each do |tag|
        @not_segment_content_tags[tag] = "true"
      end
    end
    # STDERR.puts "\n@not_segment_content_tags info:"
    # @not_segment_content_tags.keys.each do |tag|
    #  STDERR.puts "#{tag} => #{@not_segment_content_tags[tag]}"
    # end
  end

  def sentence_tag?(name)
    if name == @xml_values["sentence_tag"][0]
      return true
    else
      return false
    end
  end

  def process_chunk(active_ignoring_tags, active_qualifying_tags)
    #STDERR.puts "@chunk: ---#{@chunk}---, @active_ignoring_tags: #{active_ignoring_tags.values}, @active_qualifying_tags: #{active_qualifying_tags.values}"
    #STDERR.puts "@chunk_entity_exclude_transform: #{@chunk_entity_exclude_transform}"
    @sentence.add_chunk(@chunk, active_ignoring_tags.values, active_qualifying_tags.values, @chunk_entity_exclude_transform, @chunk_exclude_segmentation)
    @chunk = ""
    @chunk_entity_exclude_transform = Array.new
    @to = -1
    @chunk_exclude_segmentation = Array.new
    @chunk_exclude_segmentation[0] = Array.new
    @chunk_exclude_segmentation[1] = Array.new
  end

  #  def load_tag_all_content_with_one_tag_elements
  #    @xml_values["tag_all_content_with_one_tag_elements"].each do |element|
  #      components = element.gsub(/\[|\]/," ").split(" ")
  #      tag = components[1]
  #      @tag_all_content_with_one_tag_elements[components[0]] = tag
  #    end
  #  end

  def analize
    STDERR.puts "Analizing sentence..."
    STDERR.puts "Sentence text: #{@sentence.text}"
    qualifying_tag = @xml_values["qualifying_tag"]
    qualifying_tag = @xml_values["qualifying_tag"][0] if qualifying_tag

    # STDERR.puts "@remove_join_opt:#{@remove_join_opt}, @full_ignored:#{@sentence.full_ignored?}"
    #if not @sentence.full_ignored? or (@sentence.full_ignored? and @remove_join_opt)
    #@sentence.print(STDERR)
    STDERR.puts "Processing proper nouns..."
    @sentence.proper_nouns_processing(@trained_proper_nouns, @remove_join_opt)
    #@sentence.print(STDERR)
    STDERR.puts "Processing contractions..."
    @sentence.contractions_processing
    #@sentence.print(STDERR)
    STDERR.puts "Processing idioms..."
    @sentence.idioms_processing unless @remove_join_opt # Must be processed before numerals
    #@sentence.print(STDERR)
    STDERR.puts "Processing numerals..."
    @sentence.numerals_processing
    STDERR.puts "Processing enclitics..."
    @sentence.enclitics_processing
    @sentence.print(STDERR)

    STDERR.puts "Applying Viterbi..."
    #@sentence.print(STDERR)
    viterbi = Viterbi.new(@dw)
    viterbi.run(@sentence)
    #@sentence.print(STDERR)
    #@sentence.print_reverse
    if @valid_opt
      viterbi.print_best_way_xml_without_alternatives(@xml_values["sentence_tag"][0], @xml_values["expression_tag"][0], @sentence_tag_attributes,
                                                      @xml_values["analysis_tag"][0], @xml_values["analysis_unit_tag"][0],
                                                      @xml_values["unit_tag"][0], @xml_values["tag_lemma_tag"][0], @xml_values["constituent_tag"][0], @xml_values["form_tag"][0],
                                                      @xml_values["tag_tag"][0], @xml_values["lemma_tag"][0], @xml_values["hiperlemma_tag"][0], @xml_values["valid_attr"][0],
                                                      @xml_values["valid_values"][0], @expression, qualifying_tag)
    else
      viterbi.print_best_way_xml_with_alternatives(@xml_values["sentence_tag"][0], @xml_values["expression_tag"][0], @sentence_tag_attributes, @xml_values["analysis_tag"][0],
                                                   @xml_values["analysis_unit_tag"][0],
                                                   @xml_values["unit_tag"][0], @xml_values["alternatives_tag"][0], @xml_values["alternative_tag"][0],
                                                   @xml_values["tag_lemma_tag"][0], @xml_values["constituent_tag"][0], @xml_values["form_tag"][0],
                                                   @xml_values["tag_tag"][0], @xml_values["lemma_tag"][0], @xml_values["hiperlemma_tag"][0], @xml_values["valid_attr"][0],
                                                   @xml_values["valid_values"][0], @expression, qualifying_tag)
      #      end
      #    else
      # STDERR.puts "entra"
      #      @sentence.print_only_units(@xml_values['sentence_tag'][0], @xml_values['expression_tag'][0], @sentence_tag_attributes, @xml_values['analysis_tag'][0], @xml_values['analysis_unit_tag'][0], @xml_values['unit_tag'][0], @xml_values['tag_lemma_tag'][0], @xml_values['constituent_tag'][0], @xml_values['form_tag'][0], @xml_values['tag_tag'][0], @xml_values['lemma_tag'][0], @xml_values['valid_attr'][0], @xml_values['valid_values'][0], @expression, qualifying_tag)
    end
  end
end
