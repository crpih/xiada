require "csv"
require "sqlite3"
require_relative "../../lib/db_utils"
require_relative "ngrams"
require_relative "words"
require_relative "basic_suffixes"

class HMMTrainer
  include DbUtils

  EMPTY_TAG = "###"
  EMPTY_WORD = "###"
  MAX_SUFFIX_LENGTH = 10
  MAX_OCCURRENCES = 10

  def initialize(corpus_file_name, tags_info_file)
    @corpus_file_name = corpus_file_name
    @tags_info = load_tags_info(tags_info_file)
    @ngrams = Ngrams.new(EMPTY_TAG)
    @words = Words.new(EMPTY_WORD)
    @suffixes = nil
  end

  def preload_external_lexicon(lexicon_file_name)
    puts "Preloading external lexicon... (#{lexicon_file_name})"
    lexicon_words_count = 0
    CSV.foreach(lexicon_file_name, col_sep: "\t") do |word, tag, lemma, hyperlemma, normative|
      hyperlemma = "" if hyperlemma.nil?
      normative = normative == 's'
      puts "word:#{word} does not have tag and/or lemma" if tag.nil? || tag == '' || lemma.nil? || lemma == ''
      @words.add_word(word, tag, lemma, hyperlemma, true, normative)
      lexicon_words_count = lexicon_words_count + 1
    end
    puts "Lexicon:"
    puts "\twords:#{lexicon_words_count}"
  end

  def train
    puts "Training... (#{@corpus_file_name})"
    corpus_words_count = 0
    sentences_count = 0
    unigrams_num = 0
    bigrams_num = 0
    trigrams_num = 0
    tag_prev = EMPTY_TAG
    tag_prev_prev = EMPTY_TAG
    @ngrams.add_unigram(EMPTY_TAG)
    @ngrams.add_unigram(EMPTY_TAG)
    @words.add_word(EMPTY_WORD, EMPTY_TAG, EMPTY_WORD, EMPTY_WORD, false)
    @words.add_word(EMPTY_WORD, EMPTY_TAG, EMPTY_WORD, EMPTY_WORD, false)
    @ngrams.add_bigram(EMPTY_TAG, EMPTY_TAG)
    last_line = nil
    File.open(@corpus_file_name, "r") do |file|
      while line = file.gets
        line.chomp!
        #puts "line:-#{line}-"
        if not line.empty?
          word, tag, lemma = line.split(/\t/)
          hiperlemma = @words.get_hiperlemma(lemma, tag)
          corpus_words_count = corpus_words_count + 1
          # puts "word,tag,lemma:#{word},#{tag},#{lemma}\n"
          @ngrams.add_unigram(tag)
          @ngrams.add_bigram(tag_prev, tag)
          @ngrams.add_trigram(tag_prev_prev, tag_prev, tag)
          normative = @words.get_normative(word, tag, lemma)
          @words.add_word(word, tag, lemma, hiperlemma, false, normative)
          tag_prev_prev = tag_prev
          tag_prev = tag
        else
          sentences_count = sentences_count + 1
          @ngrams.add_unigram(EMPTY_TAG)
          @ngrams.add_unigram(EMPTY_TAG)
          @words.add_word(EMPTY_WORD, EMPTY_TAG, EMPTY_WORD, EMPTY_WORD, false)
          @words.add_word(EMPTY_WORD, EMPTY_TAG, EMPTY_WORD, EMPTY_WORD, false)
          @ngrams.add_bigram(tag, EMPTY_TAG)
          @ngrams.add_bigram(EMPTY_TAG, EMPTY_TAG)
          @ngrams.add_trigram(tag_prev_prev, tag_prev, EMPTY_TAG)
          @ngrams.add_trigram(tag, EMPTY_TAG, EMPTY_TAG)
          tag_prev = EMPTY_TAG
          tag_prev_prev = EMPTY_TAG
        end
        last_line = line
      end
      unless last_line.empty? # If file does not end with new line
        sentences_count = sentences_count + 1
        @ngrams.add_unigram(EMPTY_TAG)
        @ngrams.add_unigram(EMPTY_TAG)
        @words.add_word(EMPTY_WORD, EMPTY_TAG, EMPTY_WORD, EMPTY_WORD, false)
        @words.add_word(EMPTY_WORD, EMPTY_TAG, EMPTY_WORD, EMPTY_WORD, false)
        @ngrams.add_bigram(tag, EMPTY_TAG)
        @ngrams.add_bigram(EMPTY_TAG, EMPTY_TAG)
        @ngrams.add_trigram(tag_prev_prev, tag_prev, EMPTY_TAG)
        @ngrams.add_trigram(tag, EMPTY_TAG, EMPTY_TAG)
      end
    end

    puts "Calculating lambdas..."
    @ngrams.calculate_lambdas
    puts "Calculating ngrams probabilities..."
    @ngrams.calculate_as
    puts "Calculating word emission probabilities..."
    @words.calculate_probabilities
    puts "Building suffixes..."
    @suffixes = BasicSuffixes.new(EMPTY_WORD, MAX_SUFFIX_LENGTH, MAX_OCCURRENCES, @words, @tags_info)
    @suffixes.calculate_frequencies
    puts "Calculating suffixes probabilities..."
    @suffixes.calculate_probabilities

    unigrams_num = @ngrams.unigrams.keys.size
    bigrams_num = @ngrams.bigrams.keys.size
    trigrams_num = @ngrams.trigrams.keys.size

    puts "Ngrams:"
    puts "\tLambdas:"
    puts "\t\tlambda1 = #{@ngrams.lambda1},\tlambda2 = #{@ngrams.lambda2},\tlambda3 = #{@ngrams.lambda3}"
    puts "\tFrequencies:"
    puts "\t\tunigrams = #{unigrams_num},\tbigrams = #{bigrams_num},\ttrigrams = #{trigrams_num}"
    puts "\tTraining corpus only data:"
    puts "\t\tsentences = #{sentences_count}, words = #{corpus_words_count}"
    puts "\tGlobal data:"
    # Each sentence has two EMPTY_WORDS at the beginning and two more at the ending
    puts "\t\ttotal_words = #{@words.corpus_size},\ttotal_real_words = #{@words.real_corpus_size}"

    puts "Suffixes:"
    puts "\tMaximum length suffix = #{@suffixes.max_suffix_length}"
    puts "\tMaximum occurrences = #{@suffixes.max_occurrences}"
    #puts "\tNumber of different suffix/tag pairs included: #{@suffixes.get_suffixes_tags_freqs_number}"
    #puts "\tTheta: #{@suffixes.theta}"
  end

  def db_insert(db_name)
    db = SQLite3::Database.open(db_name)

    puts "Building table unigram_frequencies..."
    db.execute("create table unigram_frequencies (tk text primary key, frequency integer, log_ak real)")
    unigram_data = @ngrams.unigrams.map { |u, f| [u, f, @ngrams.get_unigram_a(u)] }
    bulk_insert(db, "unigram_frequencies", %w[tk frequency log_ak], unigram_data)

    puts "Building table bigram_frequencies..."
    db.execute("create table bigram_frequencies (tj text, tk text, frequency integer, log_ajk real, primary key(tj,tk))")
    bigram_data = @ngrams.bigrams.map do |bigram, frequency|
      tj, tk = bigram.split("&")
      log_ajk = @ngrams.get_bigram_a(tj, tk)
      [tj, tk, frequency, log_ajk]
    end
    bulk_insert(db, "bigram_frequencies", %w[tj tk frequency log_ajk], bigram_data)

    puts "Building table trigram_frequencies..."
    db.execute("create table trigram_frequencies (ti text, tj text, tk text, frequency integer, log_aijk real, primary key(ti,tj,tk))")
    trigram_data = @ngrams.trigrams.map do |trigram, frequency|
      ti, tj, tk = trigram.split("&")
      log_aijk = @ngrams.get_trigram_a(ti, tj, tk)
      [ti, tj, tk, frequency, log_aijk]
    end
    bulk_insert(db, "trigram_frequencies", %w[ti tj tk frequency log_aijk], trigram_data)

    puts "Building table emission_frequencies..."
    db.execute("create table emission_frequencies (word text, tag text, lemma text, hiperlemma text, frequency integer, log_b real, from_lexicon boolean, primary key(word,tag,lemma))")
    emission_data = @words.frequencies.flat_map do |key, frequency|
      word, tag = key.split("&&&")
      lemmas = @words.get_lemmas(word, tag)
      log_b = @words.get_probability(word, tag)
      from_lexicon = @words.get_from_lexicon(word, tag)
      lemmas.map do |lemma, hiperlemma|
        [word, tag, lemma, hiperlemma, frequency, log_b, from_lexicon ? 1 : 0]
      end
    end
    bulk_insert(db, "emission_frequencies", %w[word tag lemma hiperlemma frequency log_b from_lexicon], emission_data)

    puts "Building table word_tag_lemma_frequencies..."
    db.execute("create table word_tag_lemma_frequencies (word text, tag text, lemma text, normative boolean, frequency integer, primary key(word,tag,lemma,normative))")
    word_tag_lemma_data = @words.word_tag_lemma_count.map { |(w, t, l, n), c| [w, t, l, n ? 1 : 0, c] }
    bulk_insert(db, "word_tag_lemma_frequencies", %w[word tag lemma normative frequency], word_tag_lemma_data)

    db.execute("create table integer_values (variable_name text, value integer)")
    db.execute("insert into integer_values (variable_name, value) values ('corpus_size','#{@ngrams.corpus_size}')")
    db.execute("insert into integer_values (variable_name, value) values ('real_corpus_size','#{@ngrams.real_corpus_size}')") # excluding nils
    db.execute("insert into integer_values (variable_name, value) values ('total_corpus_size','#{@words.corpus_size}')") # including lexicons
    db.execute("insert into integer_values (variable_name, value) values ('total_real_corpus_size','#{@words.real_corpus_size}')") # excluding nils

    puts "Building table guesser_frequencies..."
    db.execute("create table guesser_frequencies (suffix text, length integer, tag text, frequency integer, log_b real, primary key(suffix, tag))")
    guesser_data = @suffixes.frequencies.each_index.flat_map do |length_index|
      @suffixes.frequencies[length_index].map do |key, frequency|
        suffix, tag = key.split("&&&")
        [suffix, length_index + 1, tag, frequency, @suffixes.get_probability(length_index + 1, suffix, tag)]
      end
    end
    bulk_insert(db, "guesser_frequencies", %w[suffix length tag frequency log_b], guesser_data)

    # @suffixes.suffixes_tags_freqs.keys.each do |key|
    #  suffix_component = @suffixes.get_suffix_component(key)
    #  tag_component = @suffixes.get_tag_component(key)
    #  frequency = @suffixes.get_frequency(suffix_component, tag_component)
    #  log_b = @suffixes.get_probability(suffix_component, tag_component)
    #  db.execute("insert into guesser_frequencies (suffix, length, tag, frequency, log_b) values ('#{SQLUtils.escape_SQL(suffix_component)}',#{suffix_component.length},'#{SQLUtils.escape_SQL(tag_component)}',#{frequency},#{log_b})")
    #end

    # create indexes to fast access ???
    # create indexes for primary key or unique ???

    puts "Building indexes..."
    db.execute("create index emission_word_index on emission_frequencies(word)")
    db.execute("create index emission_word_tag_index on emission_frequencies(word,tag)")

    # For DatabaseWrapper#get_recovery_info
    db.execute("create index emission_frequencies_lemma_tag_index ON emission_frequencies (lemma, tag)")

    db.close
  end

  private

  def load_tags_info(file_name)
    tags_info = {}
    File.open(file_name, "r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          category, category_class, name = line.split(/\t/)
          #puts "#{category}, #{category_class}, #{name}"
          if !tags_info[category_class]
            tags_info[category_class] = Array.new
          end
          if !tags_info[name]
            tags_info[name] = Array.new
          end
          tags_info[category_class] << category
          tags_info[name] << category
        end
      end
    end
    #puts "tags_info:"
    #tags_info.each do |key, values|
    #  puts "key: #{key}"
    #  values.each do |value|
    #    puts "value: #{value}"
    #  end
    #end
    return tags_info
  end
end
