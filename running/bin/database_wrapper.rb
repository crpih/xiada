require "sqlite3"
require "active_support/core_ext/object/blank"

# AutoRule is used in here as workaround
require_relative "../galician_xiada/lemmas/prefix_vowel"

class DatabaseWrapper
  CARDINALS_MAX_NUM_COMPONENTS = 4
  PROPER_NOUNS_MAX_NUM_COMPONENTS = 15

  def initialize(tagger_config)
    database_file = "training/databases/#{tagger_config.profile}/training_#{tagger_config.database}.db"
    raise "Database not found: #{database_file}" unless File.exist?(database_file)

    @tagger_config = tagger_config
    @database_file = database_file
    @db = SQLite3::Database.open(database_file)
  end

  def close_database = @db.close

  def get_emissions_info(word, tags)
    possible_tags = get_possible_tags(tags)
    query = <<~SQL
      SELECT tag, lemma, hiperlemma, log_b
      FROM emission_frequencies
      WHERE word = ?
      #{"AND from_lexicon = 1" if @tagger_config.only_lexicon && word != '###'}
      #{"AND tag IN (#{(['?'] * possible_tags.length).join(', ')})" if possible_tags&.any?}
    SQL
    execute(query, [word, *possible_tags])
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

  def get_tags_lemmas_emissions(document_config, word, tags)
    # STDERR.puts "(get_tags_lemmas_emissions) word: #{word} tags:#{tags}"
    max_length = 0
    result = get_emissions_info(word, tags)
    if result.empty?
      result = @tagger_config.lemmatizer.lemmatize(document_config, word, tags)
      # result = get_emissions_info(word, tags)
      # STDERR.puts "result.empty: next result: #{}"
      if result.empty?
        if (tags == nil) or (tags.empty?)
          result = get_guesser_result(get_possible_suffixes(word), nil, nil)
          # STDERR.puts "suffixes: #{suffixes} result:#{result}"
          if (result == nil) or (result.empty?)
            query = "select tk,null,null,log_ak from unigram_frequencies"
            opened_category_regexp = get_opened_category_regexp
            # STDERR.puts "opened_category_regexp: #{opened_category_regexp}"
            execute(query) do |row|
              result << row if row[0] =~ /#{opened_category_regexp}/
            end
          end
        end
      end
    end
    # STDERR.puts "(get_tags_lemmas_emissions) word: #{word}, tags: #{tags}, result: #{result}"
    return result
  end

  def get_guesser_result(suffixes, lemma, tags)
    # Skip tag filtering if all tags will be included
    possible_tags = includes_all_tags?(tags) ? [] : get_possible_tags(tags)
    query = <<~SQL
      SELECT tag, log_b, length
      FROM guesser_frequencies
      WHERE suffix IN (#{(['?'] * suffixes.length).join(',')})
      #{" AND tag IN (#{(['?'] * possible_tags.length).join(',')})" if possible_tags.any?}
      ORDER BY length DESC
    SQL

    rows = execute(query, [*suffixes, *possible_tags])
    return [] if rows.empty?

    max_length = rows.first.last

    rows.filter { |_tag, _lob_b, length| length == max_length }
        .map { |tag, lob_b| [tag, lemma, nil, lob_b] }
  end

  def get_open_tags_lemmas_emissions(word)
    result = Array.new
    query = "select tk,null,null,log_ak from unigram_frequencies"
    opened_category_regexp = get_opened_category_regexp
    execute(query) do |row|
      result << row if row[0] =~ /#{opened_category_regexp}/
    end
    return result
  end

  def get_bigram_probability(tag_j, tag_k)
    @db.get_first_value("select log_ajk from bigram_frequencies where tj=? and tk=?", [tag_j, tag_k]) || 0.0
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

      trigram_prob = @trigram_stm.execute!(tag_i, tag_j, tag_k).first&.first
      bigram_prob = @bigram_stm.execute!(tag_j, tag_k).first&.first unless trigram_prob
      unigram_prob = @unigram_stm.execute!(tag_k).first&.first unless bigram_prob || trigram_prob
      result = trigram_prob || bigram_prob || unigram_prob
      raise "No probability found for unigram: #{tag_k}" unless result

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
    execute <<~SQL, [token_text]
      SELECT contraction,
             first_component_word,
             first_component_tag,
             first_component_lemma,
             first_component_hiperlemma,
             second_component_word,
             second_component_tag,
             second_component_lemma,
             second_component_hiperlemma,
             third_component_word,
             third_component_tag,
             third_component_lemma,
             third_component_hiperlemma
      FROM contractions
      WHERE contraction = ?
    SQL
  end

  def get_idioms_match(substring)
    execute("SELECT idiom, tag, lemma, hiperlemma, sure FROM idioms WHERE idiom LIKE ?", ["#{substring}%"])
  end

  def get_idioms_full(idiom)
    execute("SELECT idiom, tag, lemma, hiperlemma, sure FROM idioms WHERE idiom = ?", [idiom])
  end

  def is_idiom_sure?(idiom)
    !@db.get_first_value("SELECT 1 FROM idioms WHERE idiom = ? AND sure = 1", [idiom]).nil?
  end

  def get_multiword_match(substring)
    execute("SELECT idiom AS word, tag, lemma, hiperlemma FROM idioms WHERE word LIKE ?", ["#{substring}%"])
  end

  def get_multiword_full(idiom)
    execute("SELECT idiom as word, tag, lemma, hiperlemma FROM idioms WHERE word = ?", [idiom])
  end

  def get_proper_nouns_links
    execute("SELECT link FROM proper_nouns_links")
  end

  def get_proper_nouns_candidate_tags
    execute("SELECT tag FROM proper_nouns_candidate_tags").map(&:first)
  end

  def get_proper_nouns_match(proper_noun_component, column_index, ids)
    return [] if column_index > PROPER_NOUNS_MAX_NUM_COMPONENTS

    query = <<~SQL
      SELECT id
      FROM proper_nouns
      WHERE c#{column_index} = ?
      #{"AND id IN (#{(['?'] * ids.length).join(',')})" if ids&.any?}
    SQL
    execute(query, [proper_noun_component, *ids]).map(&:first)
  end

  def get_proper_noun_ids(proper_noun)
    execute("SELECT id FROM proper_nouns WHERE proper_noun = ?", [proper_noun]).map(&:first)
  end

  def get_proper_noun_info_by_ids(ids_array)
    execute <<~SQL, ids_array
      SELECT proper_noun, tag, lemma, hiperlemma
      FROM proper_nouns
      WHERE id IN (#{(['?'] * ids_array.length).join(',')})
    SQL
  end

  def get_proper_noun_tags_lemma_hiperlemma(proper_noun)
    parts = proper_noun.split(" ")
    combinations = (0..(parts.length - 1)).map { |i| parts[0..i].join(" ") }

    execute <<~SQL, combinations
      SELECT tag, lemma, hiperlemma
      FROM proper_nouns
      WHERE proper_noun IN (#{(['?'] * combinations.length).join(',')})
      ORDER BY LENGTH(proper_noun) DESC
    SQL
  end

  def get_numerals_values
    @numerals_values ||= execute("SELECT variable_name, value FROM numerals_values")
  end

  def get_cardinals_match(cardinal_component, column_index, ids)
    return [] if column_index > PROPER_NOUNS_MAX_NUM_COMPONENTS

    query = <<~SQL
      SELECT id
      FROM cardinals
      WHERE c#{column_index} = ?
      #{"AND id IN (#{(['?'] * ids.length).join(',')})" if ids&.any?}
    SQL
    execute(query, [cardinal_component, *ids]).map(&:first)
  end

  def get_cardinal_ids(cardinal) = execute("SELECT id FROM cardinals WHERE cardinal = ?", [cardinal]).map(&:first)

  def get_cardinal_tags_lemmas(cardinal)
    execute("SELECT tag, lemma, hiperlemma FROM cardinals WHERE cardinal = ?", [cardinal])
  end

  def get_abbreviations
    @abbreviations ||= execute("SELECT abbreviation, tag, lemma, hiperlemma FROM abbreviations")
  end

  def get_acronyms
    @acronyms ||= execute("SELECT acronym, tag, lemma, hiperlemma FROM acronyms")
  end

  def enclitic_combination_exists?(combination)
    !@db.get_first_value("SELECT 1 FROM enclitic_combinations WHERE combination=?", [combination]).nil?
  end

  def get_enclitics_number(combination)
    @db.get_first_value("select length from enclitic_combinations where combination=?", [combination]) || 0
  end

  # It does not work for segmental ambiguity inside enclitic pronouns. It does not
  # exist for Galician language. It does not work if we have two different token decomposition for the main contraction too:
  # contracted_form = token1 + token2 and contracted_form = token3 + token4, where token3 is different from token1 or token4 is different from token2.
  def insert_word_tag_lemma(result, entry, word, tag, lemma, position)
    # STDERR.puts "inserting... entry:#{entry}, word:#{word}, tag:#{tag}, lemma:#{lemma}, position:#{position}"
    # STDERR.puts "result:#{result}"
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

    return true # FIXME: Ignore errors for now
  end

  def get_enclitics_info
    result = Hash.new
    execute("select contraction, first_component_word, first_component_tag, first_component_lemma, second_component_word, second_component_tag, second_component_lemma from contractions") do |row|
      pronoun_category = @db.get_first_value("select category from tags_info where name='pronoun'")
      # STDERR.puts "\nrow:#{row}"
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

    execute("select enclitic, tag, lemma from enclitics") do |row|
      unless insert_word_tag_lemma(result, row[0], row[0], row[1], row[2], 1)
        puts "Insertion error for enclitic:#{row[0]}"
        exit(1)
      end
    end

    return result
  end

  def get_enclitic_verbs_roots_info(document_config, left_candidate)
    get_enclitic_verb_roots_info(document_config, left_candidate, nil)
  end

  def get_enclitic_verbs_roots_tags(document_config, left_candidate)
    get_enclitic_verbs_roots_info(document_config, left_candidate).map { |_root, tag, _lemma, _hiperlemma| tag }
  end

  def get_enclitic_verb_roots_info(document_config, root, tags)
    variants = @tagger_config.lemmatizer.lemmatize_verb_with_enclitics(document_config, root)
    if tags.nil? || tags.empty?
      variants.each_with_object([]) do |variant, result|
        query = "SELECT root, tag, lemma, hiperlemma, extra FROM enclitic_verbs_roots WHERE root = ?"
        result.push(*execute(query, [variant]))
      end
    else
      variants.each_with_object([]) do |variant, result|
        query = "SELECT root, tag, lemma, hiperlemma, extra FROM enclitic_verbs_roots WHERE root = ? AND tag IN (#{(['?'] * tags.length).join(',')})"
        result.push(*execute(query, [variant, tags]))
      end
    end
  end

  def get_recovery_info(document_config, verb_part, tag, lemma, from_lexicon)
    # STDERR.puts "(get_recovery_info) verb_part: #{verb_part}, tag #{tag}, lemma: #{lemma}"
    from_lexicon_integer = 0
    from_lexicon_integer = 1 if from_lexicon
    query = "select word,tag,lemma,hiperlemma,log_b from emission_frequencies where tag=? and lemma=? and from_lexicon = ?"
    result = execute(query, [tag, lemma, from_lexicon_integer]).map do |word, *rest|
      # Replace gheada with gh if necessary
      word = word.gsub("g", "gh") if document_config.gheada && verb_part =~ /gh/ && word !~ /gh/

      if document_config.seseo
        word = word.dup # Make word mutable
        # Find all positions of 's' in the verb_part
        s_positions = verb_part.each_char.with_index.filter_map { |c, i| i if c == 's' }
        # Replace 'c' with 's' in the word at those positions, this avoids replacing 'c' in the enclitic part
        s_positions.each { |i| word[i] = 's' if word[i] == 'c' }
      end

      [word, *rest]
    end

    restore_lemmatization(verb_part, result)
  end

  def get_peripheric_regexp
    category_regexp = nil
    execute("select category from tags_info where name='peripheric'") do |row|
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
    # puts "closed_regexp: #{closed_regexp}"
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

  def all_tags
    @all_tags ||= execute("SELECT DISTINCT(tk) FROM unigram_frequencies").map(&:first).sort
  end

  # Check if the tags array includes all possible tags.
  # @return [Boolean]
  # true
  #  - if the tags array is nil (used to indicate all tags)
  #  - if the tags array includes all possible tags
  # false in case it cannot be determined.
  def includes_all_tags?(tags) = tags.nil? || tags == all_tags || tags.sort.uniq == all_tags

  def get_possible_tags(tags)
    return all_tags if tags.blank? || includes_all_tags?(tags)

    conditions, values = tags.map { |t| t.match?(/[*?]/) ? ["tk LIKE ?", t.tr("*?", "%_")] : ["tk = ?", t] }.transpose
    execute("SELECT DISTINCT(tk) FROM unigram_frequencies WHERE #{conditions.join(' OR ')}", values).map(&:first)
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
    @db.get_first_value(query, [word, tag, *lemmas]) || lemmas.first
  end

  private

  def execute(sql, bind_vars = [], &block)
    @db = SQLite3::Database.open(@database_file) if @db.nil? || @db.closed?
    @db.execute(sql, bind_vars, &block)
  end


  def get_possible_suffixes(word) = (1..(word.length - 1)).map { |i| word[i..] }

  def get_opened_category_regexp
    category_regexp = nil
    execute("select category from tags_info where class='opened'") do |row|
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
    execute("select category from tags_info where class='closed'") do |row|
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
    execute("select category from tags_info where name='adverb'") do |row|
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
    execute("select category from tags_info where name='substantive'") do |row|
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
    # This is a CORGA prefix rule, but it is the same as eslora one.
    # We use it in the common code by now.
    # Tags are irrelevant in this case, since the DB search was already done.
    auto_rule = Lemmas::PrefixVowel::AutoRule.new([])
    result.map do |word, tag, lemma, hiperlemma, log_b|
      next [word, tag, lemma, hiperlemma, log_b] unless verb_part.start_with?('auto')

      # Query was done before calling this function, so we build a query-result chain that simulates striping the prefix.
      original_query = Lemmas::Query.new(nil, verb_part, [])
      without_auto_query = Lemmas::Query.new(original_query, word, [])
      query_result = Lemmas::Result.new(without_auto_query, nil, tag, lemma, hiperlemma, log_b)
      # We only need to restore the lemma and hyperlemma, since the query is already correct.
      auto_result = auto_rule.apply_result(query_result)
      # TODO: Change rules and Result code to restore also the word.
      # It is irrelevant for most cases, but has to be done for enclitic verbs:
      # - autorresponsabilizándose => autorresponsabilizan + se
      # Current one, incorrect accent
      # - autorresponsabilizándose => autorresponsabilizán + se
      [auto_result.word, tag, auto_result.lemma, auto_result.hyperlemma, log_b]
    end
  end
end
