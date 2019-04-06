# -*- coding: utf-8 -*-
require "rubygems"
require "dbi"
require "sqlite3"
require_relative "ngrams.rb"
require_relative "words.rb"
require_relative "basic_suffixes.rb"
require_relative "../../lib/sql_utils.rb"

class HMMTrainer
  EMPTY_TAG = "###"
  EMPTY_WORD = "###"
  MAX_SUFFIX_LENGTH = 10
  MAX_OCCURRENCES = 10
  MEMMORY = true

  def initialize(corpus_file_name, tags_info_file)
    @corpus_file_name = corpus_file_name
    @tags_info = load_tags_info(tags_info_file)
    @ngrams = Ngrams.new(EMPTY_TAG, MEMMORY)
    @words = Words.new(EMPTY_WORD, MEMMORY)
    @suffixes = nil
  end

  def preload_external_lexicon(lexicon_file_name)
    puts "Preloading external lexicon... (#{lexicon_file_name})"
    lexicon_words_count = 0
    File.open(lexicon_file_name, "r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          content = line.split(/\t/)
          if content.size == 4
            word, tag, lemma, hiperlemma = content
          else
            word, tag, lemma = content
            hiperlemma = lemma
          end
          puts "word:#{word} does not have tag and/or lemma" if tag.empty? or lemma.empty?
          @words.add_word(word, tag, lemma, hiperlemma, true)
          lexicon_words_count = lexicon_words_count + 1
        end
      end
      puts "Lexicon:"
      puts "\twords:#{lexicon_words_count}"
    end
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
          if @words.get_lemmas(word, tag) and @words.get_lemmas(word, tag)[0][1]
            hiperlemma = @words.get_lemmas(word, tag)[0][1]
          else
            hiperlemma = lemma
          end
          corpus_words_count = corpus_words_count + 1
          # puts "word,tag,lemma:#{word},#{tag},#{lemma}\n"
          @ngrams.add_unigram(tag)
          @ngrams.add_bigram(tag_prev, tag)
          @ngrams.add_trigram(tag_prev_prev, tag_prev, tag)
          @words.add_word(word, tag, lemma, hiperlemma, false)
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
    @suffixes = BasicSuffixes.new(EMPTY_WORD, MAX_SUFFIX_LENGTH, MAX_OCCURRENCES, @words, @tags_info, MEMMORY)
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

    db.transaction
    puts "Building table unigram_frequencies..."
    db.execute("create table unigram_frequencies (tk text primary key, frequency integer, log_ak real)")
    @ngrams.unigrams.keys.each do |unigram|
      frequency = @ngrams.get_unigram_frequency(unigram)
      log_ak = @ngrams.get_unigram_a(unigram)
      db.execute("insert into unigram_frequencies (tk, frequency, log_ak) values ('#{SQLUtils.escape_SQL(unigram)}',#{frequency},#{log_ak})")
    end

    puts "Building table bigram_frequencies..."
    db.execute("create table bigram_frequencies (tj text, tk text, frequency integer, log_ajk real, primary key(tj,tk))")
    @ngrams.bigrams.keys.each do |bigram|
      tj = @ngrams.get_first_component(bigram)
      tk = @ngrams.get_second_component(bigram)
      frequency = @ngrams.get_bigram_frequency(tj, tk)
      log_ajk = @ngrams.get_bigram_a(tj, tk)
      db.execute("insert into bigram_frequencies (tj, tk, frequency, log_ajk) values ('#{SQLUtils.escape_SQL(tj)}','#{SQLUtils.escape_SQL(tk)}',#{frequency},#{log_ajk})")
    end

    puts "Building table trigram_frequencies..."
    db.execute("create table trigram_frequencies (ti text, tj text, tk text, frequency integer, log_aijk real, primary key(ti,tj,tk))")
    @ngrams.trigrams.keys.each do |trigram|
      ti = @ngrams.get_first_component(trigram)
      tj = @ngrams.get_second_component(trigram)
      tk = @ngrams.get_third_component(trigram)
      frequency = @ngrams.get_trigram_frequency(ti, tj, tk)
      log_aijk = @ngrams.get_trigram_a(ti, tj, tk)
      db.execute("insert into trigram_frequencies (ti, tj, tk, frequency, log_aijk) values ('#{SQLUtils.escape_SQL(ti)}','#{SQLUtils.escape_SQL(tj)}','#{SQLUtils.escape_SQL(tk)}',#{frequency},#{log_aijk})")
    end

    puts "Building table emission_frequencies..."
    db.execute("create table emission_frequencies (word text, tag text, lemma text, hiperlemma text, frequency integer, log_b real, from_lexicon boolean, primary key(word,tag,lemma))")
    @words.frequencies.keys.each do |key|
      # STDERR.puts "key:#{key}"
      word_component = @words.get_word_component(key)
      tag_component = @words.get_tag_component(key)
      frequency = @words.get_frequency(word_component, tag_component)
      lemmas = @words.get_lemmas(word_component, tag_component)
      log_b = @words.get_probability(word_component, tag_component)
      from_lexicon = @words.get_from_lexicon(word_component, tag_component)
      # STDERR.puts "#{word_component}\t#{tag_component}\t#{frequency}\t#{lemmas}\t#{log_b}\t#{from_lexicon}"
      from_lexicon_integer = 0
      from_lexicon_integer = 1 if from_lexicon == true
      lemmas.each do |lemma, hiperlemma|
        # STDERR.puts "word: #{word_component}, tag: #{tag_component}, lemma: #{lemma}, hiperlemma: #{hiperlemma}"
        db.execute("insert into emission_frequencies (word, tag, lemma, hiperlemma, frequency, log_b, from_lexicon) values ('#{SQLUtils.escape_SQL(word_component)}','#{SQLUtils.escape_SQL(tag_component)}','#{SQLUtils.escape_SQL(lemma)}','#{SQLUtils.escape_SQL(hiperlemma)}',#{frequency},#{log_b},#{from_lexicon_integer})")
      end
    end

    db.execute("create table integer_values (variable_name text, value integer)")
    db.execute("insert into integer_values (variable_name, value) values ('corpus_size','#{@ngrams.corpus_size}')")
    db.execute("insert into integer_values (variable_name, value) values ('real_corpus_size','#{@ngrams.real_corpus_size}')") # excluding nils
    db.execute("insert into integer_values (variable_name, value) values ('total_corpus_size','#{@words.corpus_size}')") # including lexicons
    db.execute("insert into integer_values (variable_name, value) values ('total_real_corpus_size','#{@words.real_corpus_size}')") # excluding nils

    puts "Building table guesser_frequencies..."
    db.execute("create table guesser_frequencies (suffix text, length integer, tag text, frequency integer, log_b real, primary key(suffix, tag))")
    @suffixes.frequencies.each_index do |length_index|
      @suffixes.frequencies[length_index].each do |key, frequency|
        suffix_component = @suffixes.get_suffix_component(key)
        tag_component = @suffixes.get_tag_component(key)
        log_b = @suffixes.get_probability(length_index + 1, suffix_component, tag_component)
        #puts "insert into guesser_frequencies (suffix, length, tag, frequency, log_b) values ('#{SQLUtils.escape_SQL(suffix_component)}',#{length_index+1},'#{SQLUtils.escape_SQL(tag_component)}',#{frequency},#{log_b})"
        db.execute("insert into guesser_frequencies (suffix, length, tag, frequency, log_b) values ('#{SQLUtils.escape_SQL(suffix_component)}',#{length_index + 1},'#{SQLUtils.escape_SQL(tag_component)}',#{frequency},#{log_b})")
      end
    end

    # @suffixes.suffixes_tags_freqs.keys.each do |key|
    #  suffix_component = @suffixes.get_suffix_component(key)
    #  tag_component = @suffixes.get_tag_component(key)
    #  frequency = @suffixes.get_frequency(suffix_component, tag_component)
    #  log_b = @suffixes.get_probability(suffix_component, tag_component)
    #  db.execute("insert into guesser_frequencies (suffix, length, tag, frequency, log_b) values ('#{SQLUtils.escape_SQL(suffix_component)}',#{suffix_component.length},'#{SQLUtils.escape_SQL(tag_component)}',#{frequency},#{log_b})")
    #end

    # create indexes to fast access ???
    # create indexes for primary key or unique ???
    db.commit

    puts "Building indexes..."
    db.execute("create index emission_word_index on emission_frequencies(word)")
    db.execute("create index emission_word_tag_index on emission_frequencies(word,tag)")

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
