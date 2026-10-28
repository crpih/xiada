require_relative './test_helper'
require 'yaml'
require_relative '../running/bin/config'
require_relative '../running/bin/postprocessor'
require_relative '../running/bin/token'
require_relative '../running/bin/xiada_tagger'

describe 'AmbiguousPositionCapitalization' do
  def process(text, token_specs, profile: 'galician_xiada', force_proper_nouns: false)
    Token.reset_class
    sentence = Object.new
    sentence.define_singleton_method(:acronym_or_abbreviation?) { |_word| false }
    config = Struct.new(:keep_uppercase_tokens_for, :profile, :force_proper_nouns)
      .new(/\A(?:Z|Sp)/, profile, force_proper_nouns)

    tags = token_specs.map do |word, tag_value, from, to, proper_noun|
      token = Token.new(text, word, :standard, from, to)
      token.proper_noun = proper_noun
      token.add_tag_lemma_emission(tag_value, word.downcase, '', 0.0, false)
      token.tags.fetch(tag_value)
    end

    Postprocessor.new(sentence, config).call(tags)
  end

  it 'lowercases an ambiguous capitalized token after closing question and exclamation marks' do
    ['?', '!'].each do |punctuation|
      text = "Dixo#{punctuation} Estudantes"
      tags = process(text, [
        ['Dixo', 'V', 0, 3, false],
        [punctuation, "Q#{punctuation}", 4, 4, false],
        ['Estudantes', 'Scmp', 6, 15, false]
      ])

      assert_equal ['dixo', punctuation, 'estudantes'], tags.map { |tag| tag.token.text }, text
      assert_equal ['V', "Q#{punctuation}", 'Scmp'], tags.map(&:value), text
    end
  end

  it 'leaves opening marks and full stops outside the closing-question/exclamation rule' do
    ['¿', '¡'].each do |punctuation|
      text = "Dixo#{punctuation} Estudantes"
      tags = process(text, [
        ['Dixo', 'V', 0, 3, false],
        [punctuation, "Q#{punctuation}", 4, 4, false],
        ['Estudantes', 'Scmp', 6, 15, false]
      ])

      assert_equal 'Estudantes', tags.last.token.text, text
    end

    text = 'Dixo? "Estudantes"'
    tags = process(text, [
      ['Dixo', 'V', 0, 3, false],
      ['?', 'Fia', 4, 4, false],
      ['"', 'Fq', 6, 6, false],
      ['Estudantes', 'Scmp', 7, 16, false]
    ])
    assert_equal 'estudantes', tags.last.token.text, text

    text = 'Dixo. Estudantes'
    tags = process(text, [
      ['Dixo', 'V', 0, 3, false],
      ['.', 'Fp', 4, 4, false],
      ['Estudantes', 'Scmp', 6, 15, false]
    ])
    assert_equal 'Estudantes', tags.last.token.text
  end

  it 'treats the first lexical token after opening marks as sentence-initial' do
    tags = process('¿Estudantes', [
      ['¿', 'Fia', 0, 0, false],
      ['Estudantes', 'Scmp', 1, 10, false]
    ])
    assert_equal 'estudantes', tags.last.token.text

    tags = process('¡Casa', [
      ['¡', 'Fia', 0, 0, false],
      ['Casa', 'Scfs', 1, 4, true]
    ], profile: 'galician_xiada_oral', force_proper_nouns: true)
    assert_equal 'Casa', tags.last.token.text
  end

  it 'preserves capitalization when the selected analysis is a proper noun' do
    text = 'Dixo? Xiana'
    tags = process(text, [
      ['Dixo', 'V', 0, 3, false],
      ['?', 'Fia', 4, 4, false],
      ['Xiana', 'Sp00', 6, 10, true]
    ])

    assert_equal 'Xiana', tags.last.token.text
    assert_equal 'Sp00', tags.last.value
  end

  it 'preserves oral forced proper-noun segments even when a common tag is selected' do
    text = 'Dixo? Casa'
    tags = process(text, [
      ['Dixo', 'V', 0, 3, false],
      ['?', 'Fia', 4, 4, false],
      ['Casa', 'Scfs', 6, 9, true]
    ], profile: 'galician_xiada_oral', force_proper_nouns: true)

    assert_equal 'Casa', tags.last.token.text
  end

  it 'keeps the existing lowercase conversion for an unprotected initial token' do
    tags = process('Estudantes', [['Estudantes', 'Scmp', 0, 9, false]])

    assert_equal 'estudantes', tags.first.token.text
  end

  it 'handles ordinary ambiguity and oral forced proper nouns through the public tagger' do
    profiles = YAML.load_file('profiles.example.yml', symbolize_names: true)
    oral_config = Config::Tagger.new(**profiles.find { it[:profile] == 'galician_xiada_oral' })
    oral_tagger = XiadaTagger.new(oral_config)
    document = Config::Document.new(seseo: true, gheada: true)

    ['Casa chegou.', '¿Casa chegou.', 'dixo? Casa.'].each do |text|
      token = oral_tagger.tag_texts(document, [text]).first.find { |entry| entry[:start] == text.index('Casa') }

      refute_nil token, text
      assert_equal 'Casa', token[:token], text
      assert_match(/\ASp/, token[:tag], text)
    end

    written_config = Config::Tagger.new(**profiles.find { it[:profile] == 'galician_xiada' })
    written_tagger = XiadaTagger.new(written_config)
    text = 'dixo? Estudantes'
    token = written_tagger.tag_texts(document, [text]).first.find { |entry| entry[:start] == text.index('Estudantes') }

    refute_nil token, text
    assert_equal 'estudantes', token[:token], text
    refute_match(/\ASp/, token[:tag], text)
  ensure
    oral_config&.dw&.close_database
    written_config&.dw&.close_database
  end
end
