require 'tempfile'
require 'stringio'
require 'json'
require 'diff-lcs'
require 'nxml'

CORPUS = %w[galician_xiada spanish_eslora].freeze

srand(42)

def read_tagged_sentences(filename_prefix)
  tagged_file = Dir.glob("#{filename_prefix}.tagged").first
  tagged = File.read(tagged_file).split("\n\n")
  sentences_file = Dir.glob("#{filename_prefix}.sentences").first
  sentences = File.readlines(sentences_file, chomp: true)

  raise "Different number of sentences in #{tagged_file} and #{sentences_file}" if sentences.size != tagged.size
  sentences.zip(tagged)
end

def training_test_split(corpus)
  _lang, name = corpus.split('_')

  tagged_sentences = read_tagged_sentences("training/corpus/#{corpus}/src_test/corpus_#{name}_without_kernel")

  training, test = tagged_sentences.partition { rand < 0.8 }

  kernel_sentences = read_tagged_sentences("training/corpus/#{corpus}/src_test/#{name}_kernel")

  training_with_kernel = kernel_sentences.concat(training)

  File.write("test/precision/corpus/#{corpus}_training.sentences", training_with_kernel.map(&:first).join("\n"))
  File.write("test/precision/corpus/#{corpus}_training.tagged", training_with_kernel.map(&:last).join("\n\n"))

  File.write("test/precision/corpus/#{corpus}_test.sentences", test.map(&:first).join("\n"))
  File.write("test/precision/corpus/#{corpus}_test.tagged", test.map(&:last).join("\n\n"))
end

def parse_sentences(text)
  text.split("\n\n")
      .map { |s| s.split("\n") }
      .map { |s| s.map { |t| t.split("\t") } }
end

def build_sentences(sentences)
  sentences.map do |sentence|
    sentence.map do |element|
      element.join("\t")
    end.join("\n")
  end.join("\n\n")
end

def build_input_document!(sentences, io)
  io << '<?xml version="1.0" encoding="UTF-8"?>'
  io << '<document>'
  io << '<document_content>'
  sentences.each do |sentence|
    io << "<oración>#{sentence.encode(xml: :text)}</oración>"
  end
  io << '</document_content>'
  io << '</document>'
  io.rewind
end

def parse_output_document(text)
  rules = Nxml.root :document, format: ->(e) { e[:document_content] } do
    element :document_content, format: ->(e) { e[:oración] } do
      sequence :oración, format: ->(e) { e[:análise] } do
        element :análise, format: ->(e) { e[:análise_unidade].flatten(1) } do
          sequence :análise_unidade, format: ->(e) { e[:constituínte] } do
            sequence :constituínte, format: ->(e) { e.values_at(:forma, :etiqueta, :lema) } do
              element_content :forma
              element_content :etiqueta
              element_content :lema
            end
          end
        end
      end
    end
  end
  Nxml.build(rules, StringIO.new(text))[:document]
end

CORPUS.each do |corpus|
  file("test/precision/corpus/#{corpus}_training.sentences") { training_test_split(corpus) }
  file("test/precision/corpus/#{corpus}_training.tagged") { training_test_split(corpus) }

  file("test/precision/corpus/#{corpus}_test.sentences") { training_test_split(corpus) }
  file("test/precision/corpus/#{corpus}_test.tagged") { training_test_split(corpus) }

  file("test/precision/databases/#{corpus}.db" => %W[
      test/precision/corpus/#{corpus}_training.tagged
    ]) do
    system <<~BASH
      cd training/bin && \
      XIADA_PROFILE=#{corpus} ruby xiada_training.rb \
      ../../test/precision/corpus/#{corpus}_training.tagged \
      ../../test/precision/databases/#{corpus}.db \
      ../../training/corpus/#{corpus}/tags_info.txt \
      ../../training/lexicons/#{corpus}/lexicon_principal.txt
    BASH
    system <<~BASH
      cd training/lexicons/bin && \
      XIADA_PROFILE=#{corpus} ruby add_lexicons.rb \
      ../../../test/precision/databases/#{corpus}.db \
      ../#{corpus}/contraccions.txt \
      ../#{corpus}/lexicon_locucions_seguras.txt \
      ../#{corpus}/lexicon_locucions_inseguras.txt \
      ../#{corpus}/lexicon_abreviaturas.txt \
      ../#{corpus}/lexicon_siglas.txt \
      ../#{corpus}/lexicon_propios.txt \
      ../#{corpus}/proper_nouns_links.txt \
      ../#{corpus}/proper_nouns_candidate_tags.txt \
      ../#{corpus}/lexicon_numerais_cardinais.txt \
      ../#{corpus}/numerals_values.txt \
      ../#{corpus}/lexicon_verbos_cliticos.txt \
      ../#{corpus}/lexicon_cliticos.txt \
      ../#{corpus}/lexicon_combinacions_cliticos.txt \
       ../../corpus/#{corpus}/tags_info.txt
    BASH
  end

  file("test/precision/results/#{corpus}_result.tagged" => %W[
    test/precision/databases/#{corpus}.db
    test/precision/corpus/#{corpus}_test.sentences
  ]) do |t|
    _, test_sentences_file = t.sources
    test_sentences = File.readlines(test_sentences_file, chomp: true)

    input = Tempfile.new
    build_input_document!(test_sentences, input)

    result_document = `XIADA_PROFILE=#{corpus} ruby running/bin/xiada_tagger.rb -x running/#{corpus}/xml_values.txt -t -v -f #{input.path} test/precision/databases/#{corpus}.db 2> /dev/null`
    result_sentences = parse_output_document(result_document)
    File.write(t.name, build_sentences(result_sentences))
  ensure
    input.close
    input.unlink
  end

  file("test/precision/summary/#{corpus}.json" => %W[
    test/precision/results/#{corpus}_result.tagged
    test/precision/corpus/#{corpus}_test.tagged
  ]) do |t|
    result_file, test_file = t.sources
    summary = {
      sentences: 0,
      elements: 0,
      segmentation_errors: Hash.new(0),
      category_errors: 0,
      tag_errors: 0,
      lemma_errors: 0
    }

    result = parse_sentences(File.read(result_file))
    test = parse_sentences(File.read(test_file))
    summary[:sentences] = test.size
    test.zip(result).each do |reference, predicted|
      summary[:elements] += reference.size
      length_difference = predicted.size - reference.size
      summary[:segmentation_errors][length_difference] += 1 unless length_difference.zero?
      _, reference_tags, reference_lemmas = reference.transpose
      _, predicted_tags, predicted_lemmas = predicted.transpose
      reference_categories = reference_tags.map { |t| t[0] }
      predicted_categories = predicted_tags.map { |t| t[0] }
      summary[:category_errors] += Diff::LCS.sdiff(reference_categories, predicted_categories).count { |c| c.action == "!" }
      summary[:tag_errors] += Diff::LCS.sdiff(reference_tags, predicted_tags).count { |c| c.action == "!" }
      summary[:lemma_errors] += Diff::LCS.sdiff(reference_lemmas, predicted_lemmas).count { |c| c.action == "!" }
    end
    File.write(t.name, JSON.pretty_generate(summary))
  end
end
