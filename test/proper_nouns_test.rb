require 'csv'
require_relative './test_helper'

def process_line(line, dw, acronyms_hash, abbreviations_hash, enclitics_hash)
  sentence = Sentence.new(dw, acronyms_hash, abbreviations_hash, enclitics_hash, false)
  sentence.add_chunk(line)
  sentence.finish

  sentence.proper_nouns_processing({}, false)
  sentence
end

describe 'ProperNounsTest' do
  describe 'galician_xiada' do
    # Setup
    ENV['XIADA_PROFILE'] = 'galician_xiada'
    require_relative '../running/bin/database_wrapper'
    require_relative '../running/bin/sentence'

    db_file = "training/databases/galician_xiada/training_galician_xiada_escrita.db"
    dw = DatabaseWrapper.new(db_file)
    acronyms_hash = dw.get_acronyms.map { |a| [a, 1] }.to_h
    abbreviations_hash = dw.get_abbreviations.map { |a| [a, 1] }.to_h
    enclitics_hash = dw.get_enclitics_info

    CSV.foreach("training/lexicons/galician_xiada/lexicon_propios.txt", col_sep: "\t").each_with_index do |(noun, tag, lemma, hyperlemma, *_rest), i|
      it "#{i + 1}: #{noun} should be a proper noun" do
        sentence = process_line(noun, dw, acronyms_hash, abbreviations_hash, enclitics_hash)
        begin_alternative = sentence.first_token.nexts.first.first
        proper_noun = begin_alternative.token_type == :standard ? begin_alternative : begin_alternative.nexts.keys.last
        assert_equal noun, proper_noun.text
        assert_includes proper_noun.tags.values.flat_map(&:lemmas).flat_map(&:keys), lemma
        assert_includes proper_noun.tags.values.flat_map(&:hiperlemmas).flat_map(&:keys), hyperlemma unless hyperlemma.nil?
      end
    end
  end
end
