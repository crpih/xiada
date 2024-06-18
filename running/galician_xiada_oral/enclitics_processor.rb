# -*- coding: utf-8 -*-
require_relative "../bin/database_wrapper.rb"
require_relative "../../lib/string_utils.rb"
require_relative "../bin/enclitics_processor_custom.rb"

class EncliticsProcessor
  def initialize(sentence, dw, enclitics_hash)
    @sentence = sentence
    @dw = dw
    @enclitics_hash = enclitics_hash
    xiada_profile = ENV["XIADA_PROFILE"]
    @enclitics_processor_custom = EncliticsProcessorCustom.new(@sentence, @dw, @enclitics_hash)
    case xiada_profile
    when "galician_xiada"
      @enclitics_processor_custom.extend(EncliticsProcessorCustomGalicianXiada)
    end
  end

  def process
    token = @sentence.first_token.next
    process_recursive(token, 1, false)
  end

  private

  def process_recursive(token, way, inside_alternative) # modified ???
    #puts "processing token:#{token.text}, way:#{way}, type:#{token.token_type} tagged:#{token.tagged?}"
    if token.token_type != :end_sentence
      if token.token_type == :standard
        if !token.tagged?
          try_enclitics(token, inside_alternative)
        end
        process_recursive(token.next, way, inside_alternative)
      elsif token.token_type == :begin_alternative
        # Follow all ways recursively
        way = 1
        token.nexts.keys.each do |token_aux|
          process_recursive(token_aux, way, true)
          way = way + 1
        end
      elsif token.token_type == :end_alternative
        # Join alternatives an follow only one way
        process_recursive(token.next, 1, false) if way == 1
      elsif token.token_type == :begin_sentence
        process_recursive(token.next, 1, inside_alternative)
      end
    end
  end

  def try_enclitics(token, inside_alternative)
    # STDERR.puts "try_enclitics(#{token.text})"
    some_valid = false
    prev_token = token.prev
    next_token = token.next
    begin_alternative_token = Token.new(@sentence.text, nil, :begin_alternative, token.from, token.to)
    end_alternative_token = Token.new(@sentence.text, nil, :end_alternative, token.from, token.to)
    begin_alternative_token.qualifying_info = token.qualifying_info.clone
    end_alternative_token.qualifying_info = token.qualifying_info.clone
    end_alternative_token.nexts_ignored = token.nexts_ignored.clone
    word = token.text
    max_index = word.length - 2
    (0..max_index).each do |index|
      left = word[0, index + 1]
      right = word[index + 1, max_index - index + 1]
      left_tags = @dw.get_enclitic_verbs_roots_tags(left)
      left_tags_string = left_tags.join(" ")
      unless left_tags.empty? or !@dw.enclitic_combination_exists?(right)
        result = validate_decomposition(left, left_tags_string, right)
        valid = result[0]
        verb_part = result[1]
        enclitic_part = result[2]
        verb_tags = result[3]
        if valid
          some_valid = true
          # Valid enclitics decomposition was found
          # STDERR.puts "VALID DECOMPOSITION: #{token.text}"
          # STDERR.puts "verb_part: #{verb_part}"
          # STDERR.puts "enclitic_part: #{enclitic_part}"
          # STDERR.puts "verb_tags: #{verb_tags}"
          # verb_part processing
          # pending: solution for non recovery mode (spanish)???
          recovery = true
          relevant_verb_part_tokens = nil
          if recovery
            relevant_verb_part_tokens = @enclitics_processor_custom.restore_source_form(verb_part, verb_tags, enclitic_part, syllable_count(enclitic_part), begin_alternative_token, end_alternative_token, token.from, token.to, token)
          end

          # enclitic_part processing
          enclitics_processing(verb_part, relevant_verb_part_tokens, enclitic_part, begin_alternative_token, end_alternative_token, token.from, token.to, token)
          #if inside_alternative
          #  token_aux = next_token
          #  prev_tokens = end_alternative_token.prevs.keys
          #  while token_aux.token_type != :end_alternative
          #    new_prev_tokens = Array.new
          #    prev_tokens.each do |prev_token|
          #      prev_token.reset_nexts
          #      new_token = Token.new(@sentence.text, token_aux.text, token_aux.token_type, token_aux.from, token_aux.to)
          #      new_token.qualifying_info = token.qualifying_info.clone
          #      prev_token.add_next(new_token)
          #      new_token.add_prev(prev_token)
          #      prev_token = new_token
          #      new_prev_tokens << new_token
          #    end
          #    prev_tokens = new_prev_tokens
          #    token_aux = token_aux.next
          #  end
          #  end_alternative_token.reset_prevs
          #  prev_tokens.each do |prev_token|
          #    prev_token.add_next(end_alternative_token)
          #    end_alternative_token.add_prev(prev_token)
          #  end
          #end
        end # from if valid
      end # from unless
    end # from 0..max_index
    if some_valid
      # insert created new ways inside Sentence structure
      insert_enclitic_alternatives(token, inside_alternative, begin_alternative_token, end_alternative_token)
    end
  end

  # Function which process the enclitic part and create necessary
  # tokens linked to de verb_part(s) one(s)
  def enclitics_processing(verb_part, relevant_verb_part_tokens, enclitic_part, begin_alternative_token, end_alternative_token, from, to, token)
    #STDERR.puts "enclitics_processing verb_part: #{verb_part}, enclitic_part: #{enclitic_part}"
    end_alternative_token.reset_prevs
    relevant_verb_part_tokens.each do |relevant_verb_part_token|
      begin_alternative_token.add_next(relevant_verb_part_token)
      relevant_verb_part_token.add_prev(begin_alternative_token)
      prev_token = relevant_verb_part_token

      enclitic_elements = split_elements(enclitic_part)
      enclitics = split_enclitics(enclitic_elements)
      enclitics_forms = enclitics[0]
      enclitics_tags = enclitics[1]
      enclitics_lemmas = enclitics[2]

      new_token = nil
      enclitics_forms.each_index do |index|
        result = filter_tags_enclitic(verb_part, enclitics_forms, enclitics_forms[index], enclitics_tags[index], enclitics_lemmas[index], index)
        enclitic = result[0]
        tags = result[1]
        lemmas = result[2]
        hiperlemmas = result[3]

        #STDERR.puts "enclitic: #{enclitic}"
        #STDERR.puts "tags: #{tags}"
        #STDERR.puts "lemmas: #{lemmas}"
        infos = @dw.get_emissions_info(enclitic, tags.split(" "))

        # FIXME: Ugly hack to remove hyphen in enclitics for galician_xiada
        # These cases must be searched with the hyphen, but the token text must not have the hyphen.
        enclitic.delete_prefix!('-')  if %w[-lo -la -los -las].include?(enclitic) && ENV["XIADA_PROFILE"] == "galician_xiada"
        new_token = Token.new(@sentence.text, enclitic, :standard, from, to)
        new_token.qualifying_info = token.qualifying_info.clone
        #STDERR.puts "getting info, enclitic:#{enclitic}, tags:#{tags}"
        infos.each do |info|
          tag_value = info[0]
          lemma = info[1]
          hiperlemma = info[2]
          log_b = Float(info[3])
          #puts "adding tag:#{tag_value}"
          new_token.add_tag_lemma_emission(tag_value, lemma, hiperlemma, log_b, false)
        end
        prev_token.reset_nexts
        prev_token.add_next(new_token)
        new_token.add_prev(prev_token)
        prev_token = new_token
      end
      prev_token.add_next(end_alternative_token)
      end_alternative_token.add_prev(prev_token)
    end
  end

  # Function which process the enclitic part and create necessary
  # tokens linked to de verb_part(s) one(s)
  def enclitics_processing_orig(verb_part, relevant_verb_part_tokens, enclitic_part, begin_alternative_token, end_alternative_token, from, to, token)
    # puts "enclitics_processing verb_part: #{verb_part}, enclitic_part: #{enclitic_part}"
    #prev_tokens = end_alternative_token.prevs.keys
    prev_tokens = relevant_verb_part_tokens
    enclitic_elements = split_elements(enclitic_part)
    #puts "enclitic_elements"
    #enclitic_elements.each do |element|
    #  puts "  --#{element}--"
    #end
    enclitics = split_enclitics(enclitic_elements)

    enclitics_forms = enclitics[0]
    enclitics_tags = enclitics[1]
    enclitics_lemmas = enclitics[2]

    #puts "enclitics_forms"
    #enclitics_forms.each do |enclitic_form|
    #  puts "  --#{enclitic_form}--"
    #end

    #puts "enclitics_tags"
    #enclitics_tags.each do |enclitic_tags|
    #  puts "  --#{enclitic_tags}--"
    #end

    #puts "enclitics_lemmas"
    #enclitics_lemmas.each do |enclitic_lemma|
    #  puts "  --#{enclitic_lemma}--"
    #end

    new_token = nil
    enclitics_forms.each_index do |index|
      result = filter_tags_enclitic(verb_part, enclitics_forms, enclitics_forms[index], enclitics_tags[index], enclitics_lemmas[index], index)
      enclitic = result[0]
      tags = result[1]
      lemmas = result[2]
      hiperlemmas = result[3]
      new_prev_tokens = Array.new
      prev_tokens.each do |prev_token|
        #puts "enclitic: #{enclitic}"
        #puts "tags: #{tags}"
        #puts "lemmas: #{lemmas}"
        new_token = Token.new(@sentence.text, enclitic, :standard, from, to)
        new_token.qualifying_info = token.qualifying_info.clone
        #puts "getting info, enclitic:#{enclitic}, tags:#{tags}"
        infos = @dw.get_emissions_info(enclitic, tags.split(" "))
        infos.each do |info|
          tag_value = info[0]
          lemma = info[1]
          hiperlemma = info[2]
          log_b = Float(info[3])
          #puts "adding tag:#{tag_value}"
          new_token.add_tag_lemma_emission(tag_value, lemma, hiperlemma, log_b, false)
        end
        prev_token.reset_nexts
        prev_token.add_next(new_token)
        new_token.add_prev(prev_token)
        new_token.add_next(end_alternative_token)
        new_prev_tokens << new_token
      end
      prev_tokens = new_prev_tokens
    end

    #end_alternative_token.reset_prevs
    prev_tokens.each do |prev_token|
      prev_token.add_next(end_alternative_token)
      prev_token.nexts_ignored = token.nexts_ignored.dup
      end_alternative_token.add_prev(prev_token)
    end
  end

  # Function which determines if a verb_part/enclitic_part decomposition is valid
  # It returns an array of four elements:
  # 1) Boolean which indicates if it is a valid verb_part/enclitic_part decomposition
  # 2) verb_part
  # 3) enclitic_part
  # 4) A string with space separated valid verb tags
  def validate_decomposition(verb_part, verb_tags, enclitic_part)
  # validate_decomposition verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
    check_default = true
# before rule 1 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 1
# RULE: 1 DEPTH:1 CONDITION:1
    if verb_part !~ /á/ and verb_part !~ /é/ and verb_part !~ /í/ and verb_part !~ /ó/ and verb_part !~ /ú/
# RULE: 1 DEPTH:2 CONDITION:1
    if syllable_count(enclitic_part) > 1
      result = [false, nil, nil, nil]
      return result
    end
    end
# before rule 2 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 2
# RULE: 2 DEPTH:1 CONDITION:1
    if verb_part =~ /ói$/
# RULE: 2 DEPTH:2 CONDITION:1
    if verb_tags =~ /Vei30s/
# RULE: 2 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 3 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 3
# RULE: 3 DEPTH:1 CONDITION:1
    if verb_part =~ /rás$/
# RULE: 3 DEPTH:2 CONDITION:1
    if verb_tags =~ /Vfi20s/
# RULE: 3 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 4 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 4
# RULE: 4 DEPTH:1 CONDITION:1
    if verb_part =~ /rá$/
# RULE: 4 DEPTH:2 CONDITION:1
    if verb_tags =~ /^Vfi30s$/
# RULE: 4 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 5 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 5
# RULE: 5 DEPTH:1 CONDITION:1
    if verb_part =~ /rán$/
# RULE: 5 DEPTH:2 CONDITION:1
    if verb_tags =~ /Vfi30p/
# RULE: 5 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 6 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 6
# RULE: 6 DEPTH:1 CONDITION:1
    if verb_part =~ /ár$/
# RULE: 6 DEPTH:2 CONDITION:1
    if verb_tags =~ /Vfs10s|Vfs30s|Vfsa0s|V0f10s|V0f30s|V0f000/
# RULE: 6 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 7 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 7
# RULE: 7 DEPTH:1 CONDITION:1
    if verb_part =~ /ín$/
# RULE: 7 DEPTH:2 CONDITION:1
    if verb_part !~ /^abstraín$/ and verb_part !~ /^acaín$/ and verb_part !~ /^atraín$/ and verb_part !~ /^caín$/ and verb_part !~ /^choín$/ and verb_part !~ /^condoín$/ and verb_part !~ /^contraín$/ and verb_part !~ /^corroín$/ and verb_part !~ /^debaín$/ and verb_part !~ /^decaín$/ and verb_part !~ /^degraín$/ and verb_part !~ /^deschoín$/ and verb_part !~ /^descontraín$/ and verb_part !~ /^detraín$/ and verb_part !~ /^distraín$/ and verb_part !~ /^doín$/ and verb_part !~ /^esvaín$/ and verb_part !~ /^extraín$/ and verb_part !~ /^maltraín$/ and verb_part !~ /^moín$/ and verb_part !~ /^proín$/ and verb_part !~ /^raín$/ and verb_part !~ /^recaín$/ and verb_part !~ /^remoín$/ and verb_part !~ /^retraín$/ and verb_part !~ /^retrotraín$/ and verb_part !~ /^roín$/ and verb_part !~ /^substraín$/ and verb_part !~ /^subtraín$/ and verb_part !~ /^sustraín$/
# RULE: 7 DEPTH:3 CONDITION:1
    if verb_part !~ /^desoín$/ and verb_part !~ /^entreoín$/ and verb_part !~ /^esvaín$/ and verb_part !~ /^oín$/ and verb_part !~ /^saín$/ and verb_part !~ /^sobresaín$/
# RULE: 7 DEPTH:4 CONDITION:1
    if verb_part !~ /^abluín$/ and verb_part !~ /^afluín$/ and verb_part !~ /^argüín$/ and verb_part !~ /^atribuín$/ and verb_part !~ /^atuín$/ and verb_part !~ /^concluín$/ and verb_part !~ /^confluín$/ and verb_part !~ /^constituín$/ and verb_part !~ /^construín$/ and verb_part !~ /^contribuín$/ and verb_part !~ /^derruín$/ and verb_part !~ /^desatuín$/ and verb_part !~ /^desobstruín$/ and verb_part !~ /^desposuín$/ and verb_part !~ /^destituín$/ and verb_part !~ /^destruín$/ and verb_part !~ /^difluín$/ and verb_part !~ /^diluín$/ and verb_part !~ /^diminuín$/ and verb_part !~ /^disminuín$/ and verb_part !~ /^distribuín$/ and verb_part !~ /^efluín$/ and verb_part !~ /^esluín$/ and verb_part !~ /^estatuín$/ and verb_part !~ /^excluín$/ and verb_part !~ /^extruín$/ and verb_part !~ /^fluín$/ and verb_part !~ /^imbuín$/ and verb_part !~ /^incluín$/ and verb_part !~ /^influín$/ and verb_part !~ /^inmiscuín$/ and verb_part !~ /^instituín$/ and verb_part !~ /^instruín$/ and verb_part !~ /^intuín$/ and verb_part !~ /^luín$/ and verb_part !~ /^obstruín$/ and verb_part !~ /^ocluín$/ and verb_part !~ /^posuín$/ and verb_part !~ /^protuín$/ and verb_part !~ /^prostituín$/ and verb_part !~ /^puín$/ and verb_part !~ /^recluín$/ and verb_part !~ /^reconstituín$/ and verb_part !~ /^reconstruín$/ and verb_part !~ /^redistribuín$/ and verb_part !~ /^refluín$/ and verb_part !~ /^restituín$/ and verb_part !~ /^redargüín$/ and verb_part !~ /^retribuín$/ and verb_part !~ /^substituín$/ and verb_part !~ /^sustituín$/
# RULE: 7 DEPTH:5 CONDITION:1
    if verb_tags =~ /Vei10s/
# RULE: 7 DEPTH:6 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
    end
    end
    end
# before rule 8 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 8
# RULE: 8 DEPTH:1 CONDITION:1
    if verb_part =~ /ér$/
# RULE: 8 DEPTH:2 CONDITION:1
    if verb_tags =~ /Vfs10s|Vfs30s|Vfsa0s|V0f10s|V0f30s|V0f000/
# RULE: 8 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 9 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 9
# RULE: 9 DEPTH:1 CONDITION:1
    if verb_part =~ /ír$/
# RULE: 9 DEPTH:2 CONDITION:1
    if verb_part !~ /^desoír$/ and verb_part !~ /^entreoír$/ and verb_part !~ /^esvaír$/ and verb_part !~ /^oír$/ and verb_part !~ /^saír$/ and verb_part !~ /^sobresaír$/
# RULE: 9 DEPTH:3 CONDITION:1
    if verb_part !~ /^abluír$/ and verb_part !~ /^afluír$/ and verb_part !~ /^argüír$/ and verb_part !~ /^atribuír$/ and verb_part !~ /^atuír$/ and verb_part !~ /^concluír$/ and verb_part !~ /^confluír$/ and verb_part !~ /^constituír$/ and verb_part !~ /^construír$/ and verb_part !~ /^contribuír$/ and verb_part !~ /^derruír$/ and verb_part !~ /^desatuír$/ and verb_part !~ /^desobstruír$/ and verb_part !~ /^desposuír$/ and verb_part !~ /^destituír$/ and verb_part !~ /^destruír$/ and verb_part !~ /^difluír$/ and verb_part !~ /^diluír$/ and verb_part !~ /^diminuír$/ and verb_part !~ /^disminuír$/ and verb_part !~ /^distribuír$/ and verb_part !~ /^efluír$/ and verb_part !~ /^esluír$/ and verb_part !~ /^estatuír$/ and verb_part !~ /^excluír$/ and verb_part !~ /^extruír$/ and verb_part !~ /^fluír$/ and verb_part !~ /^imbuír$/ and verb_part !~ /^incluír$/ and verb_part !~ /^influír$/ and verb_part !~ /^inmiscuír$/ and verb_part !~ /^instituír$/ and verb_part !~ /^instruír$/ and verb_part !~ /^intuír$/ and verb_part !~ /^luír$/ and verb_part !~ /^obstruír$/ and verb_part !~ /^ocluír$/ and verb_part !~ /^posuír$/ and verb_part !~ /^protuír$/ and verb_part !~ /^prostituír$/ and verb_part !~ /^puír$/ and verb_part !~ /^recluír$/ and verb_part !~ /^reconstituír$/ and verb_part !~ /^reconstruír$/ and verb_part !~ /^redargüír$/ and verb_part !~ /^redistribuír$/ and verb_part !~ /^refluír$/ and verb_part !~ /^restituír$/ and verb_part !~ /^retribuír$/ and verb_part !~ /^substituír$/ and verb_part !~ /^sustituír$/
# RULE: 9 DEPTH:4 CONDITION:1
    if verb_tags =~ /Vfs10s|Vfs30s|Vfsa0s|V0f10s|V0f30s|V0f000/
# RULE: 9 DEPTH:5 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
    end
    end
# before rule 10 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 10
# RULE: 10 DEPTH:1 CONDITION:1
    if verb_part =~ /én$/
# RULE: 10 DEPTH:2 CONDITION:1
    if verb_part !~ /^vén$/
# RULE: 10 DEPTH:3 CONDITION:1
    if verb_tags =~ /V0m20s|Vpi30s/
# RULE: 10 DEPTH:4 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
    end
# before rule 11 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 11
# RULE: 11 DEPTH:1 CONDITION:1
    if verb_part =~ /és$/
# RULE: 11 DEPTH:2 CONDITION:1
    if verb_part !~ /^vés$/
# RULE: 11 DEPTH:3 CONDITION:1
    if verb_tags =~ /Vpi20s/
# RULE: 11 DEPTH:4 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
    end
# before rule 12 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 12
# RULE: 12 DEPTH:1 CONDITION:1
    if verb_part =~ /ón$/
# RULE: 12 DEPTH:2 CONDITION:1
    if verb_tags =~ /V0m20s|Vpi30s|Vpi30p/
# RULE: 12 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 13 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 13
# RULE: 13 DEPTH:1 CONDITION:1
    if verb_part =~ /ór$/
# RULE: 13 DEPTH:2 CONDITION:1
    if verb_part !~ /^pór$/
# RULE: 13 DEPTH:3 CONDITION:1
    if verb_tags =~ /V0f000|V0f10s|V0f30s/
# RULE: 13 DEPTH:4 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
    end
# before rule 14 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 14
# RULE: 14 DEPTH:1 CONDITION:1
    if verb_part =~ /ós$/
# RULE: 14 DEPTH:2 CONDITION:1
    if verb_tags =~ /Vpi20s/
# RULE: 14 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 15 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 15
# RULE: 15 DEPTH:1 CONDITION:1
    if verb_part =~ /ís$/
# RULE: 15 DEPTH:2 CONDITION:1
    if verb_tags =~ /Vpi20s/
# RULE: 15 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 16 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 16
# RULE: 16 DEPTH:1 CONDITION:1
    if verb_part =~ /i$/
# RULE: 16 DEPTH:2 CONDITION:1
    if enclitic_part =~ /^o|^a|^os|^as/
      result = [false, nil, nil, nil]
      return result
    end
    end
# before rule 17 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 17
# RULE: 17 DEPTH:1 CONDITION:1
    if verb_part =~ /ín$/
# RULE: 17 DEPTH:2 CONDITION:1
    if verb_tags =~ /Vpi30p/
# RULE: 17 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 18 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 18
# RULE: 18 DEPTH:1 CONDITION:1
    if verb_part =~ /án$/
# RULE: 18 DEPTH:2 CONDITION:1
    if verb_tags =~ /Vpi30p/
# RULE: 18 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 19 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 19
# RULE: 19 DEPTH:1 CONDITION:1
    if verb_part =~ /ás$/
# RULE: 19 DEPTH:2 CONDITION:1
    if verb_part !~ /^dás$/
# RULE: 19 DEPTH:3 CONDITION:1
    if verb_tags =~ /Vpi20s/
# RULE: 19 DEPTH:4 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
    end
# before rule 20 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 20
# RULE: 20 DEPTH:1 CONDITION:1
    if verb_part =~ /fái$/
# RULE: 20 DEPTH:2 CONDITION:1
    if verb_tags =~ /V0m20s|Vpi30p/
# RULE: 20 DEPTH:3 CONDITION:1
    if syllable_count(enclitic_part) == 1
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 21 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 21
# RULE: 21 DEPTH:1 CONDITION:1
    if verb_part =~ /ei$|éi$|eu$|éu$|ou$|óu$|iu$|íu$|ai$|ái$|oi$|ói$/
      check_default = false
# RULE: 21 DEPTH:2 CONDITION:1
    if enclitic_part =~ /^o|^os|^a|^as|^la|^las|^lo|^los|^-lo|^-la|^-los|^-las/
      result = [false, nil, nil, nil]
      return result
    end
    end
# before rule 22 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 22
# RULE: 22 DEPTH:1 CONDITION:1
    if verb_tags =~ /V0f10s|V0f30s|Vfs10s|Vfs30s|Vfsa0s|V0f000|..[^m]2.s|..[^m]2.p|...1.p/
# RULE: 22 DEPTH:2 CONDITION:1
    if verb_part =~ /s$|r$/
      check_default = false
# RULE: 22 DEPTH:3 CONDITION:1
    if enclitic_part =~ /^o|^os|^a|^as|^lo|^la|^los|^las|^-lo|^-la|^-los|^-las/
      result = [false, nil, nil, nil]
      return result
    end
    end
# RULE: 22 DEPTH:2 CONDITION:2
    if verb_part =~ /s$|r$/
      check_default = false
# RULE: 22 DEPTH:3 CONDITION:1
    if enclitic_part =~ /^no$|^na$|^nas$/
      result = [false, nil, nil, nil]
      return result
    end
    end
# RULE: 22 DEPTH:2 CONDITION:3
    if verb_part =~ /s$/
      check_default = false
# RULE: 22 DEPTH:3 CONDITION:1
    if verb_tags =~ /...1.p/
# RULE: 22 DEPTH:4 CONDITION:1
    if enclitic_part =~ /^me|^mo|^mos|^ma|^mas|^no|^na|^nos|^nas/
    if verb_tags != nil
      verb_tags_array = verb_tags.split(/ /)
      new_verb_tags_array = Array.new
      verb_tags_array.each do |verb_tag|
        if verb_tag =~ /...1.p/
        # tag removing
        else
          new_verb_tags_array << verb_tag
        end
      end
      if new_verb_tags_array.empty?
        verb_tags = nil
      else
        verb_tags = new_verb_tags_array.join(" ")
      end
    end
    end
    end
    end
# RULE: 22 DEPTH:2 CONDITION:4
    if verb_part =~ /s$|r$/
      check_default = false
# RULE: 22 DEPTH:3 CONDITION:1
    if verb_tags =~ /...2.p/
# RULE: 22 DEPTH:4 CONDITION:1
    if enclitic_part =~ /^te|^che|^cho|^cha|^chos|^chas/
    if verb_tags != nil
      verb_tags_array = verb_tags.split(/ /)
      new_verb_tags_array = Array.new
      verb_tags_array.each do |verb_tag|
        if verb_tag =~ /...2.p/
        # tag removing
        else
          new_verb_tags_array << verb_tag
        end
      end
      if new_verb_tags_array.empty?
        verb_tags = nil
      else
        verb_tags = new_verb_tags_array.join(" ")
      end
    end
    end
    end
    end
# RULE: 22 DEPTH:2 CONDITION:5
    if verb_part !~ /s$/ and verb_part !~ /r$/
# RULE: 22 DEPTH:3 CONDITION:1
    if enclitic_part =~ /^nos/
      check_default = false
    if verb_tags != nil
      verb_tags_array = verb_tags.split(/ /)
      new_verb_tags_array = Array.new
      verb_tags_array.each do |verb_tag|
        if verb_tag =~ /V0f10s|V0f30s|Vfs10s|Vfs30s|Vfsa0s|V0f000|...2.s|...2.p/ and verb_tag !~ /V0m20s/ and verb_tag !~ /V0m20p/
        # tag removing
        else
          new_verb_tags_array << verb_tag
        end
      end
      if new_verb_tags_array.empty?
        verb_tags = nil
      else
        verb_tags = new_verb_tags_array.join(" ")
      end
    end
    end
    end
# RULE: 22 DEPTH:2 CONDITION:6
    if verb_part !~ /s$/ and verb_part !~ /r$/
# RULE: 22 DEPTH:3 CONDITION:1
    if enclitic_part =~ /^no$/
      check_default = false
      result = [false, nil, nil, nil]
      return result
    end
    end
# RULE: 22 DEPTH:2 CONDITION:7
    if verb_part !~ /s$/ and verb_part !~ /r$/
# RULE: 22 DEPTH:3 CONDITION:1
    if enclitic_part =~ /^no.$/
    if verb_tags != nil
      verb_tags_array = verb_tags.split(/ /)
      new_verb_tags_array = Array.new
      verb_tags_array.each do |verb_tag|
        if verb_tag =~ /V0f10s|V0f30s|Vfs10s|Vfs30s|Vfsa0s|V0f000|...2.s|...2.p/ and verb_tag !~ /V0m20s/ and verb_tag !~ /V0m20p/
        # tag removing
        else
          new_verb_tags_array << verb_tag
        end
      end
      if new_verb_tags_array.empty?
        verb_tags = nil
      else
        verb_tags = new_verb_tags_array.join(" ")
      end
    end
    end
    end
# RULE: 22 DEPTH:2 CONDITION:8
    if verb_part !~ /s$/ and verb_part !~ /r$/
# RULE: 22 DEPTH:3 CONDITION:1
    if enclitic_part =~ /^-lo|^-la|^-los|^-las|^lo|^la|^los|^las/
      check_default = false
    if verb_tags != nil
      verb_tags_array = verb_tags.split(/ /)
      new_verb_tags_array = Array.new
      verb_tags_array.each do |verb_tag|
        if verb_tag !~ /V0f10s/ and verb_tag !~ /V0f30s/ and verb_tag !~ /Vfs10s/ and verb_tag !~ /Vfs30s/ and verb_tag !~ /Vfsa0s/ and verb_tag !~ /V0f000/ and verb_tag !~ /..[^m]2.s/ and verb_tag !~ /..[^m]2.p/ and verb_tag !~ /...1.p/
        # tag removing
        else
          new_verb_tags_array << verb_tag
        end
      end
      if new_verb_tags_array.empty?
        verb_tags = nil
      else
        verb_tags = new_verb_tags_array.join(" ")
      end
    end
    end
    end
# RULE: 22 DEPTH:2 CONDITION:9
    if verb_part !~ /s$/ and verb_part !~ /r$/
# RULE: 22 DEPTH:3 CONDITION:1
    if enclitic_part !~ /^-lo/ and enclitic_part !~ /^-la/ and enclitic_part !~ /^lo/ and enclitic_part !~ /^la/ and enclitic_part !~ /^-los/ and enclitic_part !~ /^-las/ and enclitic_part !~ /^los/ and enclitic_part !~ /^las/ and enclitic_part !~ /^nos/ and enclitic_part !~ /^no/
    if verb_tags != nil
      verb_tags_array = verb_tags.split(/ /)
      new_verb_tags_array = Array.new
      verb_tags_array.each do |verb_tag|
        if verb_tag =~ /V0f10s|V0f30s|Vfs10s|Vfs30s|Vfsa0s|V0f000|...2.s|...2.p|...1.p/ and verb_tag !~ /V0m20s/ and verb_tag !~ /V0m20p/ and verb_tag !~ /Vei20s/
        # tag removing
        else
          new_verb_tags_array << verb_tag
        end
      end
      if new_verb_tags_array.empty?
        verb_tags = nil
      else
        verb_tags = new_verb_tags_array.join(" ")
      end
    end
    end
    end
    end
# before rule 23 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 23
# RULE: 23 DEPTH:1 CONDITION:1
    if enclitic_part =~ /^se/
    if verb_tags != nil
      verb_tags_array = verb_tags.split(/ /)
      new_verb_tags_array = Array.new
      verb_tags_array.each do |verb_tag|
        if verb_tag !~ /V0f000/ and verb_tag !~ /V0x000/ and verb_tag !~ /V..3/
        # tag removing
        else
          new_verb_tags_array << verb_tag
        end
      end
      if new_verb_tags_array.empty?
        verb_tags = nil
      else
        verb_tags = new_verb_tags_array.join(" ")
      end
    end
    end
# before rule 24 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 24
# RULE: 24 DEPTH:1 CONDITION:1
    if verb_part =~ /se$/
# RULE: 24 DEPTH:2 CONDITION:1
    if verb_tags =~ /Ves30s/
# RULE: 24 DEPTH:3 CONDITION:1
    if enclitic_part =~ /^se/
      result = [false, nil, nil, nil]
      return result
    end
    end
    end
# before rule 25 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 25
# RULE: 25 DEPTH:1 CONDITION:1
    if verb_part =~ /^es$/
# RULE: 25 DEPTH:2 CONDITION:1
    if enclitic_part =~ /^te$/
      result = [false, nil, nil, nil]
      return result
    end
    end
# before rule 26 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 26
# RULE: 26 DEPTH:1 CONDITION:1
    if verb_tags =~ /...2.s/
# RULE: 26 DEPTH:2 CONDITION:1
    if enclitic_part =~ /^vo|^vos/
    if verb_tags != nil
      verb_tags_array = verb_tags.split(/ /)
      new_verb_tags_array = Array.new
      verb_tags_array.each do |verb_tag|
        if verb_tag =~ /...2.s/
        # tag removing
        else
          new_verb_tags_array << verb_tag
        end
      end
      if new_verb_tags_array.empty?
        verb_tags = nil
      else
        verb_tags = new_verb_tags_array.join(" ")
      end
    end
    end
    end
# before rule 27 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
# RULE: 27
# RULE: 27 DEPTH:1 CONDITION:1
    if verb_tags =~ /Vei20s/
# RULE: 27 DEPTH:2 CONDITION:1
    if enclitic_part =~ /^che|^ches|^cha|^chas|^cho|^chos/
      result = [false, nil, nil, nil]
      return result
    end
    end
# before default rule 28 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
#    DEFAULT RULE: 28
    if check_default
# RULE: 28 DEPTH:1 CONDITION:1
    if verb_part =~ /á$|a$|e$|é$|i$|í$|o$|ó$|u$|ú$|n$/
# RULE: 28 DEPTH:2 CONDITION:1
    if enclitic_part =~ /^lo|^la|^las|^los|^-lo|^-la|^-los|^-las|^na|^nas/
      result = [false, nil, nil, nil]
      return result
    end
# RULE: 28 DEPTH:2 CONDITION:2
    if enclitic_part =~ /no$/
      result = [false, nil, nil, nil]
      return result
    end
    end
    end # from default_rule
    if verb_tags == nil or verb_tags.empty?
      result = [false, nil, nil, nil]
      return result
    else
      result = [true, verb_part, enclitic_part, verb_tags]
      return result
    end
  end # from def validate_decomposition

  # Function which filters the tags of an enclitic within a decomposition sequence
  # It return an array of three elements:
  # 1) The form of the enclitic, which could be changed.
  # 2) A string with space separated valid enclitic tags
  # 3) A string with space separated corresponding lemmas
  def filter_tags_enclitic(verb_part, enclitics, enclitic, enclitic_tags, enclitic_lemmas, index)
# RULE: 1
# RULE: 1 DEPTH:1 CONDITION:1
# Not OR nor AND expressions
    if index < enclitics.length-1 and enclitic =~ /^lle$/
# RULE: 1 DEPTH:2 CONDITION:1
    if  index < enclitics.length-1 and enclitics[index+1] =~ /^lo$|^la$|^los$|^las$|^-lo$|^-la$|^-los$|^-las$/
    enclitic_tags_array = enclitic_tags.split(/ /)
    enclitic_lemmas_array = enclitic_lemmas.split(/ /)
    new_enclitic_tags_array = Array.new
    new_enclitic_lemmas_array = Array.new
    enclitic_tags_array.each_index do |index_aux|
    enclitic_tag = enclitic_tags_array[index_aux]
    enclitic_lemma = enclitic_lemmas_array[index_aux]
      if enclitic_tag =~ /Rad3as|Rad3ms|Rad3fs/
      # tag removing
      else
        new_enclitic_tags_array << enclitic_tag
        new_enclitic_lemmas_array << enclitic_lemma
      end
    end
    if new_enclitic_tags_array.empty?
      enclitic_lemmas = nil
      enclitic_tags = nil
    else
      enclitic_tags = new_enclitic_tags_array.join(" ")
      enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
    end
    enclitic = replace_form("lles")
    end
    end
# RULE: 2
# RULE: 2 DEPTH:1 CONDITION:1
# Not OR nor AND expressions
    if index < enclitics.length-1 and enclitic =~ /^lle$/
# RULE: 2 DEPTH:2 CONDITION:1
    if index < enclitics.length-1 and enclitics[index+1] !~ /^lo$/ and enclitics[index+1] !~ /^la$/ and enclitics[index+1] !~ /^los$/ and enclitics[index+1] !~ /^las$/ and enclitics[index+1] !~ /^-lo$/ and enclitics[index+1] !~ /^-la$/ and enclitics[index+1] !~ /^-los$/ and enclitics[index+1] !~ /^-las$/
    enclitic_tags_array = enclitic_tags.split(/ /)
    enclitic_lemmas_array = enclitic_lemmas.split(/ /)
    new_enclitic_tags_array = Array.new
    new_enclitic_lemmas_array = Array.new
    enclitic_tags_array.each_index do |index_aux|
    enclitic_tag = enclitic_tags_array[index_aux]
    enclitic_lemma = enclitic_lemmas_array[index_aux]
      if enclitic_tag =~ /Rad3ap|Rad3mp|Rad3fp/
      # tag removing
      else
        new_enclitic_tags_array << enclitic_tag
        new_enclitic_lemmas_array << enclitic_lemma
      end
    end
    if new_enclitic_tags_array.empty?
      enclitic_lemmas = nil
      enclitic_tags = nil
    else
      enclitic_tags = new_enclitic_tags_array.join(" ")
      enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
    end
    end
    end
# RULE: 3
# RULE: 3 DEPTH:1 CONDITION:1
# Not OR nor AND expressions
    if index == enclitics.length-1 and (enclitic =~ /^lle$/) and (index == enclitics.length-1)
    enclitic_tags_array = enclitic_tags.split(/ /)
    enclitic_lemmas_array = enclitic_lemmas.split(/ /)
    new_enclitic_tags_array = Array.new
    new_enclitic_lemmas_array = Array.new
    enclitic_tags_array.each_index do |index_aux|
    enclitic_tag = enclitic_tags_array[index_aux]
    enclitic_lemma = enclitic_lemmas_array[index_aux]
      if enclitic_tag =~ /Rad3ap|Rad3mp|Rad3fp/
      # tag removing
      else
        new_enclitic_tags_array << enclitic_tag
        new_enclitic_lemmas_array << enclitic_lemma
      end
    end
    if new_enclitic_tags_array.empty?
      enclitic_lemmas = nil
      enclitic_tags = nil
    else
      enclitic_tags = new_enclitic_tags_array.join(" ")
      enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
    end
    end
# RULE: 4
# RULE: 4 DEPTH:1 CONDITION:1
# Not OR nor AND expressions
    if index < enclitics.length-1 and enclitic =~ /^nos$/
    enclitic_tags_array = enclitic_tags.split(/ /)
    enclitic_lemmas_array = enclitic_lemmas.split(/ /)
    new_enclitic_tags_array = Array.new
    new_enclitic_lemmas_array = Array.new
    enclitic_tags_array.each_index do |index_aux|
    enclitic_tag = enclitic_tags_array[index_aux]
    enclitic_lemma = enclitic_lemmas_array[index_aux]
      if enclitic_tag =~ /Raa3mp/
      # tag removing
      else
        new_enclitic_tags_array << enclitic_tag
        new_enclitic_lemmas_array << enclitic_lemma
      end
    end
    if new_enclitic_tags_array.empty?
      enclitic_lemmas = nil
      enclitic_tags = nil
    else
      enclitic_tags = new_enclitic_tags_array.join(" ")
      enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
    end
    end
# RULE: 5
# RULE: 5 DEPTH:1 CONDITION:1
# Not OR nor AND expressions
    if index < enclitics.length-1 and enclitic =~ /^no$/
    enclitic_tags_array = enclitic_tags.split(/ /)
    enclitic_lemmas_array = enclitic_lemmas.split(/ /)
    new_enclitic_tags_array = Array.new
    new_enclitic_lemmas_array = Array.new
    enclitic_tags_array.each_index do |index_aux|
    enclitic_tag = enclitic_tags_array[index_aux]
    enclitic_lemma = enclitic_lemmas_array[index_aux]
      if enclitic_tag =~ /Raa3ms/
      # tag removing
      else
        new_enclitic_tags_array << enclitic_tag
        new_enclitic_lemmas_array << enclitic_lemma
      end
    end
    if new_enclitic_tags_array.empty?
      enclitic_lemmas = nil
      enclitic_tags = nil
    else
      enclitic_tags = new_enclitic_tags_array.join(" ")
      enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
    end
    end
# RULE: 6
# RULE: 6 DEPTH:1 CONDITION:1
# Not OR nor AND expressions
    if index < enclitics.length-1 and enclitic =~ /^no$/
# RULE: 6 DEPTH:2 CONDITION:1
    if  index < enclitics.length-1 and enclitics[index+1] =~ /^lo$|^la$|^los$|^las$|^-lo$|^-la$|^-los$|^-las$/
    enclitic_tags_array = enclitic_tags.split(/ /)
    enclitic_lemmas_array = enclitic_lemmas.split(/ /)
    new_enclitic_tags_array = Array.new
    new_enclitic_lemmas_array = Array.new
    enclitic_tags_array.each_index do |index_aux|
    enclitic_tag = enclitic_tags_array[index_aux]
    enclitic_lemma = enclitic_lemmas_array[index_aux]
      if enclitic_tag =~ /Raa1ap|Raa1fp|Raa1mp/
      # tag removing
      else
        new_enclitic_tags_array << enclitic_tag
        new_enclitic_lemmas_array << enclitic_lemma
      end
    end
    if new_enclitic_tags_array.empty?
      enclitic_lemmas = nil
      enclitic_tags = nil
    else
      enclitic_tags = new_enclitic_tags_array.join(" ")
      enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
    end
    enclitic = replace_form("nos")
    end
    end
# RULE: 7
# RULE: 7 DEPTH:1 CONDITION:1
# Not OR nor AND expressions
    if index < enclitics.length-1 and enclitic =~ /^vo$/
# RULE: 7 DEPTH:2 CONDITION:1
    if  index < enclitics.length-1 and enclitics[index+1] =~ /^lo$|^la$|^los$|^las$|^-lo$|^-la$|^-los$|^-las$/
    enclitic = replace_form("vos")
    end
    end
# RULE: 8
# RULE: 8 DEPTH:1 CONDITION:1
# Not OR nor AND expressions
    if index == enclitics.length-1 and (enclitic =~ /^no$/) and (index == enclitics.length-1)
    enclitic_tags_array = enclitic_tags.split(/ /)
    enclitic_lemmas_array = enclitic_lemmas.split(/ /)
    new_enclitic_tags_array = Array.new
    new_enclitic_lemmas_array = Array.new
    enclitic_tags_array.each_index do |index_aux|
    enclitic_tag = enclitic_tags_array[index_aux]
    enclitic_lemma = enclitic_lemmas_array[index_aux]
      if enclitic_tag =~ /Raa1ap|Rad1ap|Raa1mp|Raa1fp|Rad1mp|Rad1fp/
      # tag removing
      else
        new_enclitic_tags_array << enclitic_tag
        new_enclitic_lemmas_array << enclitic_lemma
      end
    end
    if new_enclitic_tags_array.empty?
      enclitic_lemmas = nil
      enclitic_tags = nil
    else
      enclitic_tags = new_enclitic_tags_array.join(" ")
      enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
    end
    end
# RULE: 9
# RULE: 9 DEPTH:1 CONDITION:1
# Not OR nor AND expressions
    if index == enclitics.length-1 and (enclitic =~ /^nos$/) and (index == enclitics.length-1)
# RULE: 9 DEPTH:2 CONDITION:1
    if  verb_part !~ /ei$/ and verb_part !~ /éi$/ and verb_part !~ /eu$/ and verb_part !~ /éu$/ and verb_part !~ /ou$/ and verb_part !~ /óu$/ and verb_part !~ /iu$/ and verb_part !~ /íu$/ and verb_part !~ /ai$/ and verb_part !~ /ái$/
    enclitic_tags_array = enclitic_tags.split(/ /)
    enclitic_lemmas_array = enclitic_lemmas.split(/ /)
    new_enclitic_tags_array = Array.new
    new_enclitic_lemmas_array = Array.new
    enclitic_tags_array.each_index do |index_aux|
    enclitic_tag = enclitic_tags_array[index_aux]
    enclitic_lemma = enclitic_lemmas_array[index_aux]
      if enclitic_tag =~ /Raa3mp/
      # tag removing
      else
        new_enclitic_tags_array << enclitic_tag
        new_enclitic_lemmas_array << enclitic_lemma
      end
    end
    if new_enclitic_tags_array.empty?
      enclitic_lemmas = nil
      enclitic_tags = nil
    else
      enclitic_tags = new_enclitic_tags_array.join(" ")
      enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
    end
    end
    end
    if enclitic_tags == nil or enclitic_tags.empty?
      result = [nil, nil]
    else
      result = [enclitic, enclitic_tags, enclitic_lemmas]
    end
    return result
  end # from def filter_tags_enclitic

  # This function returns an array of enclitics (or enclitics with contraction), that is,
  # it returns the entries in enclitics_hash to be used to process each "portion" of
  # enclitic_part
  def split_elements(enclitic_part)
    #puts "split_element enclitic_part:#{enclitic_part}"
    result = Array.new
    start_index = 0
    start_index_aux = 0
    while (start_index < enclitic_part.length)
      enclitic = nil
      substr = nil
      #puts "start_index:#{start_index}"
      (start_index..enclitic_part.length - 1).each do |index|
        #puts "index:#{index}"
        substr = enclitic_part[start_index, index - start_index + 1]
        #puts "substr:#{substr}"
        unless @enclitics_hash[substr] == nil
          enclitic = substr
          start_index_aux = index + 1
          #puts "selected_index: #{index} start_index_aux:#{start_index_aux}"
        end
      end
      #puts "adding enclitic: #{enclitic}"
      result << enclitic
      start_index = start_index_aux
    end
    return result
  end

  # Function which splits all enclitics components of a sequence
  def split_enclitics(enclitic_elements)
    enclitics = Array.new
    tags = Array.new
    lemmas = Array.new
    component_index = 0
    enclitic_elements.each do |element|
      values_array = @enclitics_hash[element]
      values_array.each do |component|
        component.each_index do |index|
          if index == 0
            form = component[index]
            enclitics << form
          else
            tags_lemmas = component[index]
            tags_lemmas.each do |tag_lemma|
              tag = tag_lemma[0]
              lemma = tag_lemma[1]
              if tags[component_index] == nil
                tags[component_index] = tag
                lemmas[component_index] = lemma
              else
                tags[component_index] << " " << tag
                lemmas[component_index] << " " << lemma
              end
            end # from tags_lemmas.each
          end # from if index == 0
        end # from component.each_index
        component_index = component_index + 1
      end # from values_array.each
    end # from enclitic_elements.each
    result = Array.new
    result << enclitics << tags << lemmas
    return result
  end

  def insert_enclitic_alternatives_basic(token, inside_alternative, begin_alternative_token, end_alternative_token)
    prev_token = token.prevs.keys.first
    next_token = token.nexts.keys.first
    #STDERR.puts "prev_token:#{prev_token.text}"
    #STDERR.puts "next_token:#{next_token.text}"

    prev_token.remove_next(token)
    #token.remove_prev(prev_token)

    next_token.remove_prev(token)
    #token.remove_next(next_token) # Old token can't be unlinked because of the main recursive processing function

    prev_token.add_next(begin_alternative_token.nexts.keys.first)
    #STDERR.puts "prev_token.next: #{begin_alternative_token.nexts.keys.first.text}"

    begin_alternative_token.nexts.keys.first.reset_prevs
    begin_alternative_token.nexts.keys.first.add_prev(prev_token)

    end_alternative_token.prevs.keys.first.nexts_ignored = end_alternative_token.nexts_ignored.clone
    next_token.add_prev(end_alternative_token.prevs.keys.first)
    #STDERR.puts "next_token.prev: #{end_alternative_token.prevs.keys.first.text}"
    end_alternative_token.prevs.keys.first.reset_nexts
    end_alternative_token.prevs.keys.first.add_next(next_token)

    begin_alternative_token.reset_nexts
    end_alternative_token.reset_prevs
  end

  def insert_enclitic_alternatives(token, inside_alternative, begin_alternative_token, end_alternative_token)
    # STDERR.puts "insert_enclitic_alternatives: token:#{token.text}, inside_alternative: #{inside_alternative}"
    preserve_source_token = false

    results = @dw.get_emissions_info(token.text, nil)
    preserve_source_token = true unless results.empty?
    if begin_alternative_token.nexts.size == 1 and !preserve_source_token
      insert_enclitic_alternatives_basic(token, inside_alternative, begin_alternative_token, end_alternative_token)
    elsif inside_alternative
      #puts "inside_alternative"
      start_point_token = token
      before_start_point = token
      while start_point_token.token_type != :begin_alternative
        before_start_point = start_point_token
        start_point_token = start_point_token.prev
      end

      finish_point_token = token
      before_finish_point = token
      while finish_point_token.token_type != :end_alternative
        before_finish_point = finish_point_token
        finish_point_token = finish_point_token.next
      end

      unless preserve_source_token
        before_start_point.reset_prevs
        before_finish_point.reset_nexts
        start_point_token.remove_next(before_start_point)
        finish_point_token.remove_prev(before_finish_point)
      end
      #puts "adding all ways"
      add_all_ways(begin_alternative_token, start_point_token, finish_point_token)
      #puts "end adding all ways"
      begin_alternative_token.reset_nexts
      end_alternative_token.reset_prevs
    else
      prev_token = token.prev
      next_token = token.next
      prev_token.reset_nexts
      next_token.reset_prevs
      start_point_token = begin_alternative_token
      finish_point_token = end_alternative_token

      if preserve_source_token
        # Insert token in alternatives
        token.reset_prevs
        token.reset_nexts
        begin_alternative_token.add_next(token)
        token.add_prev(begin_alternative_token)
        token.add_next(end_alternative_token)
        end_alternative_token.add_prev(token)
      end

      if begin_alternative_token.size_nexts == 1
        # Finally there are not alternatives
        start_point_token = begin_alternative_token.next
        start_point_token.reset_prevs
        finish_point_token = end_alternative_token.prev
        finish_point_token.reset_nexts

        begin_alternative_token.reset_nexts
        end_alternative_token.reset_prevs
      end

      # Insert new way in the sentence
      prev_token.add_next(start_point_token)
      start_point_token.add_prev(prev_token)
      next_token.add_prev(finish_point_token)
      finish_point_token.add_next(next_token)
    end
  end

  def add_all_ways(begin_alternative_token, start_point_token, finish_point_token)
    begin_alternative_token.nexts.keys.each do |token|
      add_way(token, start_point_token, finish_point_token)
    end
  end

  def add_way(first_alternative_token, start_point_token, finish_point_token)
    start_point_token.add_next(first_alternative_token)
    first_alternative_token.reset_prevs
    first_alternative_token.add_prev(start_point_token)
    prev_token = first_alternative_token
    first_alternative_token = first_alternative_token.next
    while first_alternative_token.token_type != :end_alternative
      prev_token = first_alternative_token
      first_alternative_token = first_alternative_token.next
    end
    prev_token.reset_nexts
    prev_token.add_next(finish_point_token)
    finish_point_token.add_prev(prev_token)
  end

  ##############################################################################
  # Private functions for enclitic_verbs_rules_compiler generated function
  ##############################################################################

  def syllable_count(enclitic_part)
    count = @dw.get_enclitics_number(enclitic_part)
    return count
  end

  ##############################################################################
  # Private functions for enclitic_pronouns_rules_compiler generated function
  ##############################################################################

  def replace_form(new_form)
    return (new_form)
  end

  def remove_initial_character(string, character)
    if string.start_with?("#{character}")
      return string[1, string.length - 1]
    end
  end
end
