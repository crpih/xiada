# -*- coding: utf-8 -*-
require "socket"
require "optparse"
require "rexml"
require "csv"
require_relative "xml_listener_train_propernouns.rb"
require_relative "sentence.rb"
require_relative "viterbi.rb"
require_relative "database_wrapper.rb"

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
  end

  def run
    if @options[:socket]
      puts "Litening on socket: #{@options[:socket]}"
      hostname = "0.0.0.0"
      server = TCPServer.new(hostname, @options[:socket])
      while (socket = server.accept)
        trained_proper_nouns = {}
        loop do
          command = socket.gets
          command&.chomp!
          if command == 'TRAIN_PROPER_NOUNS'
            listener = XMLListenerTrainProperNouns.new(@xml_values, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash)
            REXML::Document.parse_stream(socket, listener)
            trained_proper_nouns = listener.get_trained_proper_nouns
          elsif command.nil? || command == 'CLOSE'
            socket.close
            break
          else
            sentence = socket.gets
            next if sentence.nil?

            sentence.chomp!
            result = nil
            if command == 'ONLY_UNITS'
              result = process_line_socket(sentence, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, trained_proper_nouns, @options[:force_proper_nouns], true)
            elsif command == 'STANDARD'
              result = process_line_socket(sentence, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, trained_proper_nouns, @options[:force_proper_nouns], false)
            end
            socket.puts(result.gsub("\n", "\t\t\t\t\t\t\t\t\t\t")) # Separate 10 tab for socket. This way it can be read with socket#gets.
          end
        end
      end
    else
      if @options[:file]
        trained_proper_nouns = {}
        File.open(@options[:file], "r") do |file|
          while line = file.gets
            line.chomp!
            STDERR.puts "Creating sentence..."
            STDERR.puts line
            sentence = Sentence.new(@dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, false)
            sentence.add_chunk(line)
            sentence.finish
            sentence.add_proper_nouns(trained_proper_nouns)
            STDERR.puts "Processing contractions..."
            sentence.contractions_processing
          end
          #STDERR.puts "BEGIN TRAINED PROPER NOUNS"
          #trained_proper_nouns.keys.each do |proper_noun|
          #  STDERR.puts proper_noun
          #end
          #STDERR.puts "END TRAINED PROPER NOUNS"
        end
        File.open(@options[:file], "r") do |file|
          while line = file.gets
            line = line.chomp!
            process_line(line, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, trained_proper_nouns, @options[:force_proper_nouns])
          end
        end
      else
        while line = @input.gets
          line.chomp!
          process_line(line, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, nil, @options[:force_proper_nouns])
        end
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

  def process_line(line, dw, acronyms_hash, abbreviations_hash, enclitics_hash, trained_proper_nouns, force_proper_nouns)
    STDERR.puts "Creating sentence..."
    STDERR.puts line
    sentence = Sentence.new(dw, acronyms_hash, abbreviations_hash, enclitics_hash, force_proper_nouns)
    sentence.add_chunk(line)
    sentence.finish
    #sentence.print(STDERR)
    STDERR.puts "Processing proper nouns..."
    sentence.proper_nouns_processing(trained_proper_nouns, @options[:remove_join])
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

  def process_line_socket(line, dw, acronyms_hash, abbreviations_hash, enclitics_hash, trained_proper_nouns, force_proper_nouns, remove_join)
    sentence = Sentence.new(dw, acronyms_hash, abbreviations_hash, enclitics_hash, force_proper_nouns)
    line.force_encoding("UTF-8") if line.encoding.name == "ASCII-8BIT"
    #encoded_line = line.encode("UTF-8")
    #sentence.add_chunk(encoded_line,nil,nil,nil,nil)
    sentence.add_chunk(line)
    sentence.finish
    sentence.proper_nouns_processing(trained_proper_nouns, remove_join)
    sentence.contractions_processing unless remove_join
    sentence.idioms_processing unless remove_join # Must be processed before numerals
    sentence.numerals_processing
    sentence.enclitics_processing
    viterbi = Viterbi.new(dw)
    viterbi.run(sentence)
    CSV.generate(col_sep: "\t") { |csv| viterbi.best_way.each { |r| csv << r.values } }
  end

  def load_xml_values(xml_values_file)
    File.open(xml_values_file, "r") do |file|
      while line = file.gets
        line.chomp!
        unless line =~ /^#/
          elements = line.split(/\t/)
          variable_name = elements[0]
          values = elements[1..elements.length - 1]
          @xml_values[variable_name] = values
          #STDERR.puts "@xml_values[#{variable_name}] = #{values}"
        end
      end
      @xml_values["hiperlemma_tag"] = [nil] unless @xml_values["hiperlemma_tag"]
    end
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
    load_xml_values(options[:xml]) if options[:xml]
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
