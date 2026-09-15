require_relative './test_helper'
require_relative '../running/bin/config'
require_relative '../running/bin/xiada_tagger'

describe 'Postprocessor' do
  before do
    profile = YAML.load_file('profiles.example.yml', symbolize_names: true).find { it[:profile] == 'galician_xiada' }
    @tagger = XiadaTagger.new(Config::Tagger.new(**profile))
    @document = Config::Document.new(seseo: true, gheada: true)
  end

  def output(text)
    @tagger.tag_texts(@document, [text]).first.map { |token| token.values_at(:token, :tag, :lemma, :hiperlemma) }
  end

  it 'infers feminine singular agreement for a generic proper noun' do
    assert_equal [
      ['unha', 'Difs', 'un', 'un'],
      ['Galicia', 'Spfs', 'Galicia', '']
    ], output('unha Galicia')
  end

  it 'completes a proper noun whose gender is known when context agrees' do
    assert_equal [
      ['unha', 'Difs', 'un', 'un'],
      ['Ana', 'Spfs', 'Ana', '']
    ], output('unha Ana')
  end

  it 'infers masculine singular agreement for a generic proper noun' do
    assert_equal [
      ['o', 'Ddms', 'o', 'o'],
      ['Madrid', 'Spms', 'Madrid', '']
    ], output('o Madrid')
  end

  it 'infers feminine plural agreement for a generic proper noun' do
    assert_equal [
      ['as', 'Ddfp', 'o', 'o'],
      ['Coruña', 'Spfp', 'Coruña', '']
    ], output('as Coruña')
  end

  it 'does not override a proper noun with a conflicting known gender' do
    assert_equal [
      ['unha', 'Difs', 'un', 'un'],
      ['Pedro', 'Spm0', 'Pedro', '']
    ], output('unha Pedro')
  end

  it 'does not override a proper noun whose gender and number are complete' do
    assert_equal [
      ['unha', 'Difs', 'un', 'un'],
      ['Acordos de Oslo', 'Spmp', 'Acordos de Oslo', '']
    ], output('unha Acordos de Oslo')
  end

  it 'does not force agreement without a sufficient determiner context' do
    assert_equal [
      ['con', 'P', 'con', 'con'],
      ['Galicia', 'Sp00', 'Galicia', '']
    ], output('con Galicia')
  end

  it 'keeps the token tag index synchronized when replacing a tag value' do
    token = Token.new('Galicia', 'Galicia', :standard, 0, 6)
    token.add_tag_lemma_emission('Sp00', 'Galicia', '', 0.0, false)
    tag = token.tags.fetch('Sp00')

    tag.replace_value('Spfs')

    assert_same tag, token.tags['Spfs']
    refute token.tags.key?('Sp00')
  end
end
