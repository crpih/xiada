# -*- coding: utf-8 -*-
require "optparse"
require "rexml"
require "csv"
require_relative "sentence.rb"
require_relative "viterbi.rb"
require_relative "database_wrapper.rb"
require_relative "./proper_nouns"

class XiadaTagger
  def initialize(input, output, options)
    @input = input
    @output = output
    @options = options
    @input_file = nil
    @directory = nil
    @port = nil
    @xml_values = {}
    @dw = DatabaseWrapper.new("training/databases/#{ENV['XIADA_PROFILE']}/training_#{ENV['XIADA_DATABASE']}.db")
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
    opts.banner = "Usage: ruby xiada_tagger.rb [-f <input_file>] <training_db_file>"
    opts.banner << "\n       ruby xiada_tagger.rb -h"
    opts.banner << "\n\n"

    opts.on("-f", "--file INPUTFILE", "Input is obtained from <input_file> and not from STDIN") do |f|
      options[:file] = f
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

    options
  end

  begin
    tagger = XiadaTagger.new(STDIN, STDOUT, parse_args)
    tagger.run
    tagger.finalize
  rescue => e
    puts e.message
    puts e.backtrace.each(&method(:puts))
    exit(-1)
  end
end
