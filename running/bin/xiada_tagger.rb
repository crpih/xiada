# -*- coding: utf-8 -*-
require "socket"
require "optparse"
require "rexml"
require "csv"
require_relative "sentence.rb"
require_relative "viterbi.rb"
require_relative "database_wrapper.rb"
require_relative "./proper_nouns"

class XiadaTagger
  def initialize(input, output, training_db_file, options)
    @input = input
    @output = output
    @options = options
    @input_file = nil
    @directory = nil
    @training_db_file = training_db_file
    @port = nil
    @xml_values = {}
    @dw = DatabaseWrapper.new(@training_db_file)
    load_acronyms_abbreviations_enclitics
    @proper_noun_processor = ProperNouns.new(
      ProperNouns.parse_literals_file("training/lexicons/#{ENV['XIADA_PROFILE']}/lexicon_propios.txt"),
      CSV.read("training/lexicons/#{ENV['XIADA_PROFILE']}/proper_nouns_links.txt", col_sep: "\t").map(&:first),
      CSV.read("training/lexicons/#{ENV['XIADA_PROFILE']}/proper_nouns_candidate_tags.txt", col_sep: "\t").map(&:first)
    )
  end

  def run
    if @options[:file]
      lines = File.readlines(@options[:file])
      trained_proper_nouns_processor = @proper_noun_processor.with_trained(lines)
      lines.each do |line|
        process_line(line, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, trained_proper_nouns_processor)
      end
    else
      while line = @input.gets
        line.chomp!
        process_line(line, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, @proper_noun_processor)
      end
    end
  end

  def finalize
    @dw.close
  end

  private

  def print_enclitics_hash(enclitics_hash)
    enclitics_hash.each do |key, values_array|
      @output.puts "#{key}"
      values_array.each do |component|
        component.each_index do |index|
          form = component[index] if index == 0
          @output.puts "\t#{form}"
          unless index == 0
            tags_lemmas = component[index]
            tags_lemmas.each do |tag_lemma|
              tag = tag_lemma[0]
              lemma = tag_lemma[1]
              @output.puts "\t\t(#{tag},#{lemma})"
            end
          end # from unless index == 0
        end # from component.each_index
      end # from values_array.each
    end # from enclitics_hash.each
  end

  def process_line(line, dw, acronyms_hash, abbreviations_hash, enclitics_hash, proper_nouns_processor)
    STDERR.puts "Creating sentence..."
    STDERR.puts line

    sentence = Sentence.new(dw, acronyms_hash, abbreviations_hash, enclitics_hash, proper_nouns_processor, line)
    STDERR.puts "Processing contractions..."
    sentence.contractions_processing
    #sentence.print
    STDERR.puts "Processing idioms..."
    sentence.idioms_processing # Must be processed before numerals
    # sentence.print(STDERR)
    # sentence.print(STDERR)
    STDERR.puts "Processing numerals..."
    sentence.numerals_processing
    # sentence.print(STDERR)
    STDERR.puts "Processing enclitics..."
    sentence.enclitics_processing
    #sentence.print(STDERR)
    #sentence.print_reverse
    STDERR.puts "Applying Viterbi..."
    viterbi = Viterbi.new(dw)
    viterbi.run(sentence)
    #sentence.print(STDERR)
    #sentence.print_reverse
    @output.write(CSV.generate(col_sep: "\t") { |csv| viterbi.best_way.each { |r| csv << r.values } })
    @output.flush
  end

  def load_acronyms_abbreviations_enclitics
    @acronyms_hash = @dw.get_acronyms.map { |a| [a, 1] }.to_h
    @abbreviations_hash = @dw.get_abbreviations.map { |a| [a, 1] }.to_h
    @enclitics_hash = @dw.get_enclitics_info
  end
end

# main #

if $PROGRAM_NAME == __FILE__
  def parse_args
    options = {}
    opts = OptionParser.new
    opts.banner = "Usage: ruby xiada_tagger.rb [-x xml_values_file] [-v] [-p] [-t] [-f <input_file>] <training_db_file>"
    opts.banner << "\n       ruby xiada_tagger.rb [-x xml_values_file] [-v] [-p] [-t] -d <directory>  <training_db_file>"
    opts.banner << "\n       ruby xiada_tagger.rb -s <port> <training_db_file>"
    opts.banner << "\n       ruby xiada_tagger.rb -h"
    opts.banner << "\n\n"

    opts.on("-v", "--valid", "Only valid tags are included on output") do |v|
      options[:valid] = true
    end

    opts.on("-f", "--file INPUTFILE", "Input is obtained from <input_file> and not from STDIN") do |f|
      options[:file] = f
    end

    opts.on("-d", "--directory DIRECTORY", "All xml files from directory are processed and the output is written to corresponding .out files") do |d|
      options[:directory] = d
    end

    opts.on("-s", "--socket PORT_NUMBER", "Input is obtained from socket and output is sended to socket also") do |s|
      options[:socket] = s
    end

    opts.on("-r", "--remove_join", "Disable modules related to joining units (proper nouns and idioms) and tagging at all") do |r|
      options[:remove_join] = true
    end

    opts.on("-p", "--force_proper_nouns", "Force proper noun detection when uppercase") do |fp|
      options[:force_proper_nouns] = true
    end

    opts.on("-t", "--train_proper_nouns", "Train proper nouns to try to identify proper nouns in sentence start position") do |t|
      options[:trained_proper_nouns] = true
    end

    opts.on("-h", "--help", "Usage information") do |h|
      options[:help] = true
    end

    begin
      opts.parse!
    rescue OptionParser::InvalidOption => e
      puts e
      puts opts
      exit(-1)
    end

    if options[:help] or ARGV.size != 1
      puts opts
      exit(-1)
    end

    unless options[:file] or (options[:directory] and options[:xml]) or options[:socket] or options.size == 0
      puts opts
      exit(-1)
    end
    options
  end

  begin
    tagger = XiadaTagger.new(STDIN, STDOUT, ARGV[0], parse_args)
    tagger.run
    tagger.finalize
  rescue => e
    puts e.message
    puts e.backtrace.each(&method(:puts))
    exit(-1)
  end
end
