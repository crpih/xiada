# -*- coding: utf-8 -*-
require "rubygems"
require "dbi"
require "sqlite3"
require_relative "../../lib/sql_utils.rb"
require_relative "../bin/lemmatizer.rb"
require_relative "../galician_xiada/lemmas/lemmatizer_corga.rb"

class DatabaseWrapper
  CARDINALS_MAX_NUM_COMPONENTS = 4
  PROPER_NOUNS_MAX_NUM_COMPONENTS = 15

  def initialize(db_name)
    @db = SQLite3::Database.open(db_name)
    xiada_profile = ENV["XIADA_PROFILE"]
    @lemmatizer = Lemmatizer.new(self)
    case xiada_profile
    when "spanish_eslora"
      @lemmatizer.extend(LemmatizerSpanishEslora)
    when "galician_xiada"
      @lemmatizer.extend(Lemmas::LemmatizerCorga::ClassMethods)
    when "galician_xiada_oral"
      @lemmatizer.extend(Lemmas::LemmatizerCorga::ClassMethods)
    end
  end

  def get_emissions_info(word, tags)
    #STDERR.puts "word:#{word}, tags:#{tags}"
    result = Array.new
    if (tags == nil) or (tags.empty?)
      # STDERR.puts "tags nil"
      @db.execute("select tag,lemma,hiperlemma,log_b from emission_frequencies where word='#{SQLUtils.escape_SQL(word)}'") do |row|
        result << row
      end
    else
      #STDERR.puts "tags not nil"
      tag_string = get_possible_tags(tags)
      #STDERR.puts "tag_string: #{tag_string}"
      @db.execute("select tag,lemma,hiperlemma,log_b from emission_frequencies where word='#{SQLUtils.escape_SQL(word)}' and tag in (#{tag_string})") do |row|
        result << row
      end
    end
    #STDERR.puts "result:#{result}"
    return result
  end

  def get_emissions_info_variants(word, tags, variants)
    result = get_emissions_info(word, tags)
    if result.empty?
      variants.each do |variant|
        if variant
          result = get_emissions_info(variant, tags)
          return result unless result.empty?
        end
      end
    end
    return result
  end

  def get_tags_lemmas_emissions_strict(word, tags)
    # this function doen't check for suffix analysis nor open tags.
    return get_emissions_info(word, tags)
  end

  def get_tags_lemmas_emissions(word, tags)
    #STDERR.puts "(get_tags_lemmas_emissions) word: #{word} tags:#{tags}"
    max_length = 0
    result = get_emissions_info(word, tags)
    if result.empty?
      result = @lemmatizer.lemmatize(word, tags)
      # result = get_emissions_info(word, tags)
      # STDERR.puts "result.empty: next result: #{}"
      if result.empty?
        if (tags == nil) or (tags.empty?)
          suffixes = get_possible_suffixes(word)
          result = get_guesser_result(suffixes, nil, nil)
          # STDERR.puts "suffixes: #{suffixes} result:#{result}"
          if (result == nil) or (result.empty?)
            query = "select tk,null,null,log_ak from unigram_frequencies"
            opened_category_regexp = get_opened_category_regexp
            # STDERR.puts "opened_category_regexp: #{opened_category_regexp}"
            @db.execute(query) do |row|
              result << row if row[0] =~ /#{opened_category_regexp}/
            end
          end
        end
      end
    end
    #STDERR.puts "(get_tags_lemmas_emissions) word: #{word}, tags: #{tags}, result: #{result}"
    return result
  end

  def get_guesser_result(suffixes, lemma, tags)
    result = []
    query = "select tag,null,null,log_b from guesser_frequencies where suffix in (#{suffixes})"
    query << "and tag in (#{get_possible_tags(tags)})" if tags
    query << "order by length desc"

    row_index = 1
    @db.execute(query) do |row|
      row[1] = lemma if lemma
      if row_index == 1
        max_length = Integer(row[3])
        result << row
      elsif Integer(row[3]) == max_length
        result << row
      else
        # max_length_undefined
        break
      end
      row_index = row_index + 1
    end
    result
  end

  def get_open_tags_lemmas_emissions(word)
    result = Array.new
    query = "select tk,null,null,log_ak from unigram_frequencies"
    opened_category_regexp = get_opened_category_regexp
    @db.execute(query) do |row|
      result << row if row[0] =~ /#{opened_category_regexp}/
    end
    return result
  end
  def get_bigram_probability(tag_j, tag_k)
    result = @db.get_first_value("select log_ajk from bigram_frequencies where tj='#{SQLUtils.escape_SQL(tag_j)}' and tk='#{SQLUtils.escape_SQL(tag_k)}'")
    if result == nil
      return Float(0.0)
    else
      return Float(result)
    end
  end

  TRIGRAM_MUTEX = Mutex.new

  def get_trigram_probability(tag_i, tag_j, tag_k)
    # Prepared statements are not thread safe, so we need to synchronize access to them.
    # Even with synchronization, this is faster than dynamic queries.
    TRIGRAM_MUTEX.synchronize do
      # Cache prepared statements. This will run only the first time.
      @trigram_stm ||= @db.prepare("select log_aijk from trigram_frequencies where ti=? and tj=? and tk=? limit 1")
      @bigram_stm ||= @db.prepare("select log_ajk from bigram_frequencies where tj=? and tk=? limit 1")
      @unigram_stm ||= @db.prepare("select log_ak from unigram_frequencies where tk=? limit 1")

      #STDERR.puts "Getting trigram probability: -#{tag_i}-, -#{tag_j}-, -#{tag_k}-"
      result = @trigram_stm.execute!(tag_i, tag_j, tag_k).first&.first ||
        @bigram_stm.execute!(tag_j, tag_k).first&.first ||
        @unigram_stm.execute!(tag_k).first&.first

      # Statements must be reset before they can be used again.
      # See: https://github.com/sparklemotion/sqlite3-ruby/issues/158
      @trigram_stm.reset!
      @bigram_stm.reset!
      @unigram_stm.reset!
      result
    end
  end

  def close
    @trigram_stm&.close
    @bigram_stm&.close
    @unigram_stm&.close
    @db.close
  end

  def get_contractions(token_text)
    result = Array.new

    @db.execute("select contraction, first_component_word, first_component_tag, first_component_lemma, first_component_hiperlemma,
                 second_component_word, second_component_tag, second_component_lemma, second_component_hiperlemma,
                 third_component_word, third_component_tag, third_component_lemma, third_component_hiperlemma
                 from contractions where contraction = '#{SQLUtils.escape_SQL(token_text)}'") do |row|
      result << row
    end
    return result
  end

  def get_idioms_match(substring)
    result = Array.new

    @db.execute("select idiom, tag, lemma, hiperlemma, sure
                 from idioms where idiom like '#{SQLUtils.escape_SQL(substring)}%'") do |row|
      result << row
    end
    return result
  end

  def get_idioms_full(idiom)
    result = Array.new

    @db.execute("select idiom, tag, lemma, hiperlemma, sure
                 from idioms where idiom = '#{SQLUtils.escape_SQL(idiom)}'") do |row|
      result << row
    end
    return result
  end

  def is_idiom_sure?(idiom)
    result = @db.get_first_value("select sure from idioms where idiom = '#{SQLUtils.escape_SQL(idiom)}'")
    if result == nil
      return false
    else
      result == 1 ? true : false
    end
  end

  def get_multiword_match(substring)
    result = Array.new

    @db.execute("select idiom as word, tag, lemma, hiperlemma
                 from idioms where word like '#{SQLUtils.escape_SQL(substring)}%'") do |row|
      result << row
    end
    return result
  end

  def get_multiword_full(idiom)
    result = Array.new

    @db.execute("select idiom as word, tag, lemma, hiperlemma
                 from idioms where word = '#{SQLUtils.escape_SQL(idiom)}'") do |row|
      result << row
    end
    return result
  end

  def get_proper_nouns_links
    result = Array.new
    @db.execute("select link from proper_nouns_links") do |row|
      result << row
    end
    return result
  end

  def get_proper_nouns_candidate_tags
    result = Array.new
    @db.execute("select tag from proper_nouns_candidate_tags") do |row|
      result << row[0]
    end
    return result
  end

  def get_proper_nouns_match(proper_noun_component, column_index, ids)
    result = Array.new
    unless column_index > PROPER_NOUNS_MAX_NUM_COMPONENTS
      column_name = "c#{column_index}"
      if ids == nil
        query = "select id from proper_nouns where #{column_name} = '#{SQLUtils.escape_SQL(proper_noun_component)}'"
      else
        ids_string = get_possible_ids(ids)
        query = "select id from proper_nouns where #{column_name} = '#{SQLUtils.escape_SQL(proper_noun_component)}' and id in (#{ids_string})"
      end
      @db.execute(query) do |row|
        result << row[0]
      end
    end
    return result
  end

  def get_proper_noun_ids(proper_noun)
    result = Array.new
    @db.execute("select id from proper_nouns where proper_noun = '#{SQLUtils.escape_SQL(proper_noun)}'") do |row|
      result << row[0]
    end
    return result
  end

  def get_proper_noun_info_by_ids(ids_array)
    result = Array.new
    ids_string = get_possible_ids(ids_array)
    #puts "ids_string:#{ids_string}"
    @db.execute("select proper_noun, tag, lemma, hiperlemma, from proper_nouns where id in (#{ids_string})") do |row|
      result << row
    end
    return result
  end

  def get_proper_noun_tags(proper_noun)
    proper_noun_components = proper_noun.split(/ /)
    result = Array.new
    while result.empty?
      proper_noun = proper_noun_components.join(" ")
      @db.execute("select tag from proper_nouns where proper_noun = '#{SQLUtils.escape_SQL(proper_noun)}'") do |row|
        result << row[0]
      end
      proper_noun_components.pop
    end
    return result
  end

  def get_numerals_values
    result = Array.new
    @db.execute("select variable_name, value from numerals_values") do |row|
      result << row
    end
    return result
  end

  def get_cardinals_match(cardinal_component, column_index, ids)
    result = Array.new
    unless column_index > CARDINALS_MAX_NUM_COMPONENTS
      column_name = "c#{column_index}"
      if ids == nil
        query = "select id from cardinals where #{column_name} = '#{SQLUtils.escape_SQL(cardinal_component)}'"
      else
        ids_string = get_possible_ids(ids)
        query = "select id from cardinals where #{column_name} = '#{SQLUtils.escape_SQL(cardinal_component)}' and id in (#{ids_string})"
      end
      @db.execute(query) do |row|
        result << row[0]
      end
    end
    return result
  end

  def get_cardinal_ids(cardinal)
    result = Array.new
    @db.execute("select id from cardinals where cardinal = '#{SQLUtils.escape_SQL(cardinal)}'") do |row|
      result << row[0]
    end
    return result
  end

  def get_cardinal_tags_lemmas(cardinal)
    result = Array.new
    @db.execute("select tag, lemma, hiperlemma from cardinals where cardinal = '#{SQLUtils.escape_SQL(cardinal)}'") do |row|
      result << row
    end
    return result
  end

  def get_abbreviations
    result = Array.new
    @db.execute("select abbreviation, tag, lemma, hiperlemma from abbreviations") do |row|
      result << row[0]
    end
    return result
  end

  def get_acronyms
    result = Array.new
    @db.execute("select acronym, tag, lemma, hiperlemma from acronyms") do |row|
      result << row[0]
    end
    return result
  end

  def get_enclitic_verbs_roots_info(left_candidate)
    #STDERR.puts "left_candidate: #{left_candidate}"
    result = []
    @db.execute("select root,tag,lemma, hiperlemma from enclitic_verbs_roots where root='#{SQLUtils.escape_SQL(left_candidate)}'") do |row|
      result << row
    end
    if result.empty?
      #STDERR.puts "kk: #{@lemmatizer.lemmatize_verb_with_enclitics(left_candidate)}"
      @db.execute("select root,tag,lemma, hiperlemma from enclitic_verbs_roots where root='#{SQLUtils.escape_SQL(@lemmatizer.lemmatize_verb_with_enclitics(left_candidate))}'") do |row|
        result << row
      end
    end
    return result
  end

  def get_enclitic_verbs_roots_tags(left_candidate)
    #STDERR.puts "left_candidate: #{left_candidate}"
    result = Array.new
    @db.execute("select tag from enclitic_verbs_roots where root='#{SQLUtils.escape_SQL(left_candidate)}'") do |row|
      result << row[0]
    end
    if result.empty?
      #STDERR.puts "result.empty"
      #temp = SQLUtils.escape_SQL(@lemmatizer.lemmatize_verb_with_enclitics(left_candidate))
      #STDERR.puts "temp:#{temp}"
      @db.execute("select tag from enclitic_verbs_roots where root='#{SQLUtils.escape_SQL(@lemmatizer.lemmatize_verb_with_enclitics(left_candidate))}'") do |row|
        result << row[0]
      end
    end
    return result
  end

  def enclitic_combination_exists?(combination)
    result = Array.new
    @db.execute("select combination, length from enclitic_combinations where combination='#{SQLUtils.escape_SQL(combination)}'") do |row|
      result << row
    end
    if result.empty?
      return false
    else
      return true
    end
  end

  def get_enclitics_number(combination)
    result = @db.get_first_value("select length from enclitic_combinations where combination='#{SQLUtils.escape_SQL(combination)}'")
    if result == nil
      return 0
    else
      return Integer(result).to_i
    end
  end

  # It does not work for segmental ambiguity inside enclitic pronouns. It does not
  # exist for Galician language. It does not work if we have two different token decomposition for the main contraction too:
  # contracted_form = token1 + token2 and contracted_form = token3 + token4, where token3 is different from token1 or token4 is different from token2.
  def insert_word_tag_lemma(result, entry, word, tag, lemma, position)
    #STDERR.puts "inserting... entry:#{entry}, word:#{word}, tag:#{tag}, lemma:#{lemma}, position:#{position}"
    #STDERR.puts "result:#{result}"
    if result[entry] == nil
      result[entry] = Array.new
    end

    if result[entry][position - 1] == nil
      result[entry][position - 1] = Array.new
      result[entry][position - 1][0] = word
    end

    new_tag_lemma = [tag, lemma]

    if result[entry][position - 1][0] == word
      if result[entry][position - 1].size == 1
        result[entry][position - 1][1] = Array.new
        result[entry][position - 1][1] << new_tag_lemma
      else
        tags_lemmas = result[entry][position - 1][1]
        tags_lemmas << new_tag_lemma
      end
      return true
    end

    return false
  end

  def get_enclitics_info
    result = Hash.new
    @db.execute("select contraction, first_component_word, first_component_tag, first_component_lemma, second_component_word, second_component_tag, second_component_lemma from contractions") do |row|
      pronoun_category = @db.get_first_value("select category from tags_info where name='pronoun'")
      #STDERR.puts "\nrow:#{row}"
      if row[2] =~ /#{pronoun_category}/
        unless insert_word_tag_lemma(result, row[0], row[1], row[2], row[3], 1)
          puts "Insertion error for contraction:#{row[0]} (first component)"
          exit(1)
        end
        unless insert_word_tag_lemma(result, row[0], row[4], row[5], row[6], 2)
          puts "Insertion error for contraction:#{row[0]} (second component)"
          exit(1)
        end
      end
    end

    @db.execute("select enclitic, tag, lemma from enclitics") do |row|
      unless insert_word_tag_lemma(result, row[0], row[0], row[1], row[2], 1)
        puts "Insertion error for enclitic:#{row[0]}"
        exit(1)
      end
    end

    return result
  end

  def get_enclitic_verb_roots_info(root, tags)
    result = []
    if (tags == nil) or (tags.empty?)
      @db.execute("select tag,lemma,hiperlemma,extra from enclitic_verbs_roots where root='#{SQLUtils.escape_SQL(root)}'") do |row|
        result << row
      end
      if result.empty?
        @db.execute("select tag,lemma,hiperlemma,extra from enclitic_verbs_roots where root='#{SQLUtils.escape_SQL(@lemmatizer.lemmatize_verb_with_enclitics(root))}'") do |row|
          result << row
        end
      end
    else
      tag_string = get_possible_tags(tags)
      @db.execute("select tag,lemma,hiperlemma,extra from enclitic_verbs_roots where root='#{SQLUtils.escape_SQL(root)}' and tag in (#{tag_string})") do |row|
        result << row
      end
      if result.empty?
        @db.execute("select tag,lemma,hiperlemma,extra from enclitic_verbs_roots where root='#{SQLUtils.escape_SQL(@lemmatizer.lemmatize_verb_with_enclitics(root))}' and tag in (#{tag_string})") do |row|
          result << row
        end
      end
    end
    return result
  end

  def get_recovery_info(verb_part, tag, lemma, from_lexicon)
    #STDERR.puts "(get_recovery_info) verb_part: #{verb_part}, tag #{tag}, lemma: #{lemma}"
    from_lexicon_integer = 0
    from_lexicon_integer = 1 if from_lexicon
    result = Array.new
    @db.execute("select word,tag,lemma,hiperlemma,log_b from emission_frequencies where tag='#{SQLUtils.escape_SQL(tag)}' and lemma='#{SQLUtils.escape_SQL(lemma)}' and from_lexicon = #{from_lexicon_integer}") do |row|
      if verb_part =~ /gh/ && row[0] !~ /gh/
        row[0].gsub!("g","gh")
      end
      unless ENV['XIADA_SESEO'].nil?
        s_positions = verb_part.each_char.with_index.filter_map { |c, i| i if c == 's' }
        s_positions.each do |index|
          row[0][index] = 's' if row[0][index] == 'c'
        end
      end
      result << row
    end
    return restore_lemmatization(verb_part, result)
  end

  def get_peripheric_regexp
    category_regexp = nil
    @db.execute("select category from tags_info where name='peripheric'") do |row|
      category = row[0]
      if category_regexp == nil
        category_regexp = "^#{category}"
      else
        category_regexp << "|#{category}"
      end
    end
    return category_regexp
  end

  def closed_category?(text_token)
    closed_regexp = get_closed_category_regexp
    #puts "closed_regexp: #{closed_regexp}"
    result = get_emissions_info(text_token, nil)
    result.each do |row|
      tag = row[0]
      if tag =~ /#{closed_regexp}/
        return true
      end
    end
    return false
  end

  def adverb?(text_token)
    adverb_regexp = get_adverb_category_regexp
    result = get_emissions_info(text_token, nil)
    result.each do |row|
      tag = row[0]
      if tag =~ /#{adverb_regexp}/
        return true
      end
    end
    return false
  end

  def not_in_lexicon_or_only_substantive?(text_token)
    substantive_regexp = get_substantive_category_regexp
    result = get_emissions_info(text_token, nil)
    result.each do |row|
      tag = row[0]
      if tag !~ /#{substantive_regexp}/
        return false
      end
    end
    return true
  end

  def get_possible_tags(tags)
    result = ""
    tags.each do |tag|
      result << "," unless result.empty?
      if tag =~ /[\*\_]/
        result << get_tags_from_regexp(SQLUtils.escape_SQL_wildcards(tag))
      else
        result << "'#{SQLUtils.escape_SQL(tag)}'"
      end
    end
    result
  end

  def get_most_frequent_lemma(word, tag, lemmas)
    query = <<~SQL
      SELECT lemma
      FROM word_tag_lemma_frequencies
      WHERE word = ? AND tag = ? AND lemma IN (#{(['?'] * lemmas.length).join(',')})
      ORDER BY normative DESC, frequency DESC
      LIMIT 1
    SQL
    # If (word, tag, lemma) is not found, return the first lemma in the list
    @db.execute(query, word, tag, *lemmas)&.first&.first || lemmas.first
  end

  private

  def get_tags_from_regexp(tag_regexp)
    result = ""
    @db.execute("select distinct(tk) from unigram_frequencies where tk like '#{tag_regexp}'") do |row|
      tag = row[0]
      result << "," unless result.empty?
      result << "'#{SQLUtils.escape_SQL(tag)}'"
    end
    result
  end

  def get_possible_suffixes(word)
    result = nil
    (1..word.length - 1).each do |suffix_length|
      suffix = word[word.length - suffix_length, word.length]
      if result == nil
        result = "'#{SQLUtils.escape_SQL(suffix)}'"
      else
        result = result + ",'#{SQLUtils.escape_SQL(suffix)}'"
      end
    end
    return result
  end

  def get_possible_ids(ids)
    result = nil
    ids.each do |id|
      if result == nil
        result = "'#{id}'"
      else
        result = result + ",'#{id}'"
      end
    end
    return result
  end

  def get_opened_category_regexp
    category_regexp = nil
    @db.execute("select category from tags_info where class='opened'") do |row|
      category = row[0]
      if category_regexp == nil
        category_regexp = "^#{category}"
      else
        category_regexp << "|#{category}"
      end
    end
    return category_regexp
  end

  def get_closed_category_regexp
    category_regexp = nil
    @db.execute("select category from tags_info where class='closed'") do |row|
      category = row[0]
      if category_regexp == nil
        category_regexp = "^#{category}"
      else
        category_regexp << "|#{category}"
      end
    end
    return category_regexp
  end

  def get_adverb_category_regexp
    category_regexp = nil
    @db.execute("select category from tags_info where name='adverb'") do |row|
      category = row[0]
      if category_regexp == nil
        category_regexp = "^#{category}"
      else
        category_regexp << "|#{category}"
      end
    end
    return category_regexp
  end

  def get_substantive_category_regexp
    category_regexp = nil
    @db.execute("select category from tags_info where name='substantive'") do |row|
      category = row[0]
      if category_regexp == nil
        category_regexp = "^#{category}"
      else
        category_regexp << "|#{category}"
      end
    end
    return category_regexp
  end

  def restore_lemmatization(verb_part, result)
    result.each do |row|
      row[0] = @lemmatizer.lemmatize_verb_with_enclitics_reverse_word(verb_part, row[0])
      row[2] = @lemmatizer.lemmatize_verb_with_enclitics_reverse_lemma(verb_part, row[2])
      row[3] = @lemmatizer.lemmatize_verb_with_enclitics_reverse_hiperlemma(verb_part, row[3])
    end
    return result
  end
end
