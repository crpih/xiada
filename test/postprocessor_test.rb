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

  it 'overrides a proper noun with a conflicting known gender' do
    assert_equal [
      ['unha', 'Difs', 'un', 'un'],
      ['Pedro', 'Spfs', 'Pedro', '']
    ], output('unha Pedro')
  end

  it 'overrides a proper noun whose gender and number contradict the context' do
    assert_equal [
      ['unha', 'Difs', 'un', 'un'],
      ['Acordos de Oslo', 'Spfs', 'Acordos de Oslo', '']
    ], output('unha Acordos de Oslo')
  end

  it 'overrides a known feminine proper noun in a masculine plural context' do
    assert_equal [
      ['os', 'Ddmp', 'o', 'o'],
      ['Ana', 'Spmp', 'Ana', '']
    ], output('os Ana')
  end

  it 'keeps the form and lemma when correcting a specified analysis' do
    assert_equal [
      ['as', 'Ddfp', 'o', 'o'],
      ['Madrid', 'Spfp', 'Madrid', '']
    ], output('as Madrid')
  end

  it 'does not force agreement without a sufficient determiner context' do
    assert_equal [
      ['con', 'P', 'con', 'con'],
      ['Galicia', 'Sp00', 'Galicia', '']
    ], output('con Galicia')
  end

  it 'does not carry agreement across a coordination' do
    assert_equal [
      ['unha', 'Difs', 'un', 'un'],
      ['Ana', 'Spfs', 'Ana', ''],
      ['e', 'Cc', 'e', 'e'],
      ['Pedro', 'Spm0', 'Pedro', '']
    ], output('unha Ana e Pedro')
  end

  it 'does not carry agreement across punctuation' do
    assert_equal [
      ['unha', 'Difs', 'un', 'un'],
      ['Ana', 'Spfs', 'Ana', ''],
      [',', 'Q,', ',', ','],
      ['Pedro', 'Spm0', 'Pedro', '']
    ], output('unha Ana, Pedro')
  end

  it 'does not carry agreement across an intervening preposition' do
    assert_equal [
      ['unha', 'Difs', 'un', 'un'],
      ['casa', 'Scfs', 'casa', 'casa'],
      ['de', 'P', 'de', 'de'],
      ['Galicia', 'Sp00', 'Galicia', '']
    ], output('unha casa de Galicia')
  end

  it 'keeps the token tag index synchronized when replacing a tag value' do
    Token.reset_class
    token = Token.new('Galicia', 'Galicia', :standard, 0, 6)
    token.add_tag_lemma_emission('Sp00', 'Galicia', '', 0.0, false)
    tag = token.tags.fetch('Sp00')

    tag.replace_value('Spfs')

    assert_same tag, token.tags['Spfs']
    refute token.tags.key?('Sp00')
  end
end
