# -*- coding: utf-8 -*-
require "socket"
require "optparse"
require "rexml/document"
require_relative "xml_listener.rb"
require_relative "xml_listener_train_propernouns.rb"
require_relative "sentence.rb"
require_relative "viterbi.rb"
require_relative "database_wrapper.rb"

class XiadaTagger
  def initialize
    @options = {}
    @input_file = nil
    @directory = nil
    @training_db_file = nil
    @port = nil
    @xml_values = {}
    parse_args
    @dw = DatabaseWrapper.new(@training_db_file)
    load_acronyms_abbreviations_enclitics
  end

  def run
    if @options[:directory]
      orig_stdout = $stdout
      trained_proper_nouns = {}
      Dir.chdir(@options[:directory]) do
        Dir.glob("*.xml").sort.each do |input_file_name|
          output_file_name = input_file_name + ".out"
          unless File.exist?(output_file_name)
            $stdout = File.open(output_file_name, "w")
            if @options[:trained_proper_nouns]
              File.open(input_file_name, "r") do |file|
                listener = XMLListenerTrainProperNouns.new(@xml_values, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash)
                REXML::Document.parse_stream(file, listener)
                trained_proper_nouns = listener.get_trained_proper_nouns
              end
            end
            File.open(input_file_name, "r") do |file|
              listener = XMLListener.new(@xml_values, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, trained_proper_nouns, @options[:valid], @options[:remove_join], @options[:force_proper_nouns])
              REXML::Document.parse_stream(file, listener)
            end
            $stdout.close
          end
        end
      end
      $stdout = orig_stdout
    elsif @options[:socket]
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
        if @options[:xml] # file and xml
          if @options[:trained_proper_nouns]
            File.open(@options[:file], "r") do |file|
              listener = XMLListenerTrainProperNouns.new(@xml_values, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash)
              REXML::Document.parse_stream(file, listener)
              trained_proper_nouns = listener.get_trained_proper_nouns
            end
          end
          File.open(@options[:file], "r") do |file|
            listener = XMLListener.new(@xml_values, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, trained_proper_nouns, @options[:valid], @options[:remove_join], @options[:force_proper_nouns])
            REXML::Document.parse_stream(file, listener)
          end
        else # file and !xml
          File.open(@options[:file], "r") do |file|
            while line = file.gets
              line.chomp!
              STDERR.puts "Creating sentence..."
              STDERR.puts line
              sentence = Sentence.new(@dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash)
              sentence.add_chunk(line, nil, nil, nil, nil)
              sentence.finish
              STDERR.puts "Processing contractions..."
              sentence.contractions_processing
              sentence.add_proper_nouns(trained_proper_nouns)
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
        end
      else
        if @options[:xml] # !file and xml
          listener = XMLListener.new(@xml_values, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, nil, @options[:valid], @options[:force_proper_nouns])
          REXML::Document.parse_stream($stdin, listener)
        else # !file and !xml
          while line = STDIN.gets
            line.chomp!
            process_line(line, @dw, @acronyms_hash, @abbreviations_hash, @enclitics_hash, nil, @options[:force_proper_nouns])
          end
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
      puts "#{key}"
      values_array.each do |component|
        component.each_index do |index|
          form = component[index] if index == 0
          puts "\t#{form}"
          unless index == 0
            tags_lemmas = component[index]
            tags_lemmas.each do |tag_lemma|
              tag = tag_lemma[0]
              lemma = tag_lemma[1]
              puts "\t\t(#{tag},#{lemma})"
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
    sentence.add_chunk(line, nil, nil, nil, nil)
    sentence.finish
    #sentence.print(STDERR)
    STDERR.puts "Processing contractions..."
    sentence.contractions_processing
    #sentence.print
    STDERR.puts "Processing idioms..."
    sentence.idioms_processing # Must be processed before numerals
    # sentence.print(STDERR)
    STDERR.puts "Processing proper nouns..."
    sentence.proper_nouns_processing(trained_proper_nouns, @options[:remove_join])
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
    viterbi.print_best_way
  end

  def process_line_socket(line, dw, acronyms_hash, abbreviations_hash, enclitics_hash, trained_proper_nouns, force_proper_nouns, remove_join)
    sentence = Sentence.new(dw, acronyms_hash, abbreviations_hash, enclitics_hash, force_proper_nouns)
    line.force_encoding("UTF-8") if line.encoding.name == "ASCII-8BIT"
    #encoded_line = line.encode("UTF-8")
    #sentence.add_chunk(encoded_line,nil,nil,nil,nil)
    sentence.add_chunk(line, nil, nil, nil, nil)
    sentence.finish
    sentence.contractions_processing unless remove_join
    sentence.idioms_processing unless remove_join # Must be processed before numerals
    sentence.proper_nouns_processing(trained_proper_nouns, remove_join)
    sentence.numerals_processing
    sentence.enclitics_processing
    viterbi = Viterbi.new(dw)
    viterbi.run(sentence)
    return viterbi.get_best_way
  end

  def parse_args
    opts = OptionParser.new
    opts.banner = "Usage: ruby xiada_tagger.rb [-x xml_values_file] [-v] [-p] [-t] [-f <input_file>] <training_db_file>"
    opts.banner << "\n       ruby xiada_tagger.rb [-x xml_values_file] [-v] [-p] [-t] -d <directory>  <training_db_file>"
    opts.banner << "\n       ruby xiada_tagger.rb -s <port> <training_db_file>"
    opts.banner << "\n       ruby xiada_tagger.rb -h"
    opts.banner << "\n\n"

    opts.on("-x", "--xml XMLFILE", "Input is an xml document instead of plain text") do |x|
      @options[:xml] = x
    end

    opts.on("-v", "--valid", "Only valid tags are included on output") do |v|
      @options[:valid] = true
    end

    opts.on("-f", "--file INPUTFILE", "Input is obtained from <input_file> and not from STDIN") do |f|
      @options[:file] = f
    end

    opts.on("-d", "--directory DIRECTORY", "All xml files from directory are processed and the output is written to corresponding .out files") do |d|
      @options[:directory] = d
    end

    opts.on("-s", "--socket PORT_NUMBER", "Input is obtained from socket and output is sended to socket also") do |s|
      @options[:socket] = s
    end

    opts.on("-r", "--remove_join", "Disable modules related to joining units (proper nouns and idioms) and tagging at all") do |r|
      @options[:remove_join] = true
    end

    opts.on("-p", "--force_proper_nouns", "Force proper noun detection when uppercase") do |fp|
      @options[:force_proper_nouns] = true
    end

    opts.on("-t", "--train_proper_nouns", "Train proper nouns to try to identify proper nouns in sentence start position") do |t|
      @options[:trained_proper_nouns] = true
    end

    opts.on("-h", "--help", "Usage information") do |h|
      @options[:help] = true
    end

    #STDERR.puts "ARGV.size:#{ARGV.size}"
    #ARGV.each_index do |index|
    #  STDERR.puts "index:#{index}, ARGV[index]:#{ARGV[index]}"
    #end

    begin
      opts.parse!
    rescue OptionParser::InvalidOption => e
      puts e
      puts opts
      exit(-1)
    end

    #STDERR.puts "ARGV.size:#{ARGV.size}"
    #ARGV.each_index do |index|
    #  STDERR.puts "index:#{index}, ARGV[index]:#{ARGV[index]}"
    #end

    if @options[:help] or ARGV.size != 1
      puts opts
      exit(-1)
    end

    @training_db_file = ARGV[0]
    unless @options[:file] or (@options[:directory] and @options[:xml]) or @options[:socket] or @options.size == 0
      puts opts
      exit(-1)
    end
    load_xml_values(@options[:xml]) if @options[:xml]
  end

  # def parse_args_old
  #   opts = OptionParser.new
  #   opts.banner = "Usage: ruby xiada_tagger.rb [-x] [-v] [-p] [-f <input_file>] <training_db_file> [<xml_values_file>]"
  #   opts.banner << "\n       ruby xiada_tagger.rb -d <directory> [-v] [-p] <training_db_file> <xml_values_file>"
  #   opts.banner << "\n       ruby xiada_tagger.rb -s [-p] <port> <training_db_file>"
  #   opts.banner << "\n       ruby xiada_tagger.rb -h"

  #   opts.on("-x", "--xml", "Input is an xml document instead of plain text") do |x|
  #     @options[:xml] = true
  #   end

  #   opts.on("-v", "--valid", "Only valid tags are included on output") do |x|
  #     @options[:valid] = true
  #   end

  #   opts.on("-f", "--file INPUTFILE", "Input is obtained from <input_file> and not from STDIN") do |f|
  #     @options[:file] = f
  #   end

  #   opts.on("-d", "--directory DIRECTORY", "All xml files from directory are processed and the output is written to corresponding .out files") do |d|
  #     @options[:directory] = d
  #   end

  #   opts.on("-s", "--socket", "Input is obtained from socket and output is sended to socket also") do |s|
  #     @options[:socket] = true
  #   end

  #   opts.on("-r", "--remove_join", "Disable modules related to joining units (proper nouns and idioms) and tagging at all. ") do |r|
  #     @options[:remove_join] = true
  #   end

  #   opts.on("-p", "--force_proper_nouns", "Force proper noun detection when uppercase") do |fp|
  #     @options[:force_proper_nouns] = true
  #   end

  #   opts.on("-h", "--help", "Usage information") do |h|
  #     @options[:help] = true
  #   end

  #   begin
  #     opts.parse!
  #   rescue OptionParser::InvalidOption => e
  #     puts e
  #     puts opts
  #     exit(-1)
  #   end

  #   if @options[:help]
  #     puts opts
  #     exit(0)
  #   end

  #   if ARGV.size == 0
  #     puts opts
  #     exit(-1)
  #   end

  #   if @options[:directory]
  #     if ARGV.size < 2
  #       puts opts
  #       exit(-1)
  #     end
  #     @directory = @options[:directory]
  #     @training_db_file = ARGV[0]
  #     xml_values_file = ARGV[1]
  #     STDERR.puts "@directory: #{@directory}\n@training_db_file:#{@training_db_file}\nxml_values_file:#{xml_values_file}"
  #   elsif @options[:socket]
  #     if ARGV.size != 2
  #       puts opts
  #       exit(-1)
  #     end
  #     @port = ARGV[0]
  #     @training_db_file = ARGV[1]
  #   elsif @options[:file]
  #     if @options[:xml] and (ARGV.size != 2 and ARGV.size != 3)
  #       puts opts
  #       exit(-1)
  #     elsif !@options[:xml] and ARGV.size != 2
  #       puts opts
  #       exit(-1)
  #     end
  #     @input_file = @options[:file]
  #     @training_db_file = ARGV[0]
  #     xml_values_file = ARGV[1] if @options[:xml]
  #     STDERR.puts "ARGV[0]:#{ARGV[0]}, ARGV[1]:#{ARGV[1]}, ARGV[2]:#{ARGV[2]}"
  #     STDERR.puts "@input_file: #{@input_file}, @training_db_file: #{@training_db_file}, xml_values_file: #{xml_values_file}"
  #   else
  #     if @options[:xml] and (ARGV.size != 1 and ARGV.size != 2)
  #       puts opts
  #       exit(-1)
  #     elsif !@options[:xml] and ARGV.size != 1
  #       puts opts
  #       exit(-1)
  #     end
  #     @training_db_file = ARGV[0]
  #     xml_values_file = ARGV[1] if @options[:xml]
  #   end
  #   STDERR.puts "xml_values_file:#{xml_values_file}"
  #   load_xml_values(xml_values_file) if @options[:xml] or @options[:directory]
  # end

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
    acronyms = @dw.get_acronyms
    @acronyms_hash = Hash.new
    acronyms.each do |acronym|
      @acronyms_hash[acronym] = 1
    end
    abbreviations = @dw.get_abbreviations
    @abbreviations_hash = Hash.new
    abbreviations.each do |abbreviation|
      @abbreviations_hash[abbreviation] = 1
    end
    @enclitics_hash = @dw.get_enclitics_info
  end
end

# main #

begin
  tagger = XiadaTagger.new
  tagger.run
  tagger.finalize
rescue => e
  puts e.message
  puts e.backtrace.each(&method(:puts))
  exit(-1)
end
