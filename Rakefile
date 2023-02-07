require 'fileutils'
require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

CorpusInfo = Struct.new(:name, :corpus_file_name)

CORPUS = [
  CorpusInfo.new('galician_xiada', 'corpus_xiada_escrita'),
  CorpusInfo.new('spanish_eslora', 'corpus_eslora'),
]

task :testing_corpus do
  srand(42)
  CORPUS.each do |info|
    corpus_file = Dir.glob("training/corpus/**/#{info.corpus_file_name}.tagged").first
    sentences = File.read(corpus_file).split("\n\n")
    training, test = sentences.partition { rand < 0.8 }
    File.write("test/precision/corpus/#{info.name}_training.tagged", training.join("\n\n"))
    File.write("test/precision/corpus/#{info.name}_test.tagged", test.join("\n\n"))

    FileUtils.rm_f("test/precision/databases/#{info.name}.db")

    command = <<~BASH
      cd training/bin && \
      XIADA_PROFILE=#{info.name} ruby xiada_training.rb \
      ../../test/precision/corpus/#{info.name}_training.tagged \
      ../../test/precision/databases/#{info.name}.db \
      ../../training/corpus/#{info.name}/tags_info.txt \
      ../../training/lexicons/#{info.name}/lexicon_principal.txt
    BASH

    system(command)
  end
end
