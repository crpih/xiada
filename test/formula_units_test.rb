require_relative './test_helper'
require_relative '../running/bin/config'
require_relative '../running/bin/xiada_tagger'

describe 'Formula units' do
  before do
    profile = YAML.load_file('profiles.example.yml', symbolize_names: true).find { it[:profile] == 'galician_xiada' }
    @config = Config::Tagger.new(**profile)
    @tagger = XiadaTagger.new(@config)
    @document = Config::Document.new(seseo: true, gheada: true)
  end

  def output(text)
    proper_nouns = @config.proper_nouns_processor.with_trained([text])
    @tagger.send(:tag_text, @document, proper_nouns, text).best_way
  end

  it 'keeps the complete C-15 formula as one annotated unit with source offsets' do
    text = '¿Que significa para ti a fórmula Al<subíndice>2</subíndice>O<subíndice>3</subíndice>?'
    formula = 'Al<subíndice>2</subíndice>O<subíndice>3</subíndice>'
    formula_start = text.index(formula)
    formula_finish = formula_start + formula.length - 1

    assert_equal [
      { token: '¿', tag: 'Q¿', lemma: '¿', hiperlemma: '¿', start: 0, finish: 0 },
      { token: 'que', tag: 'Gnaa', lemma: 'que', hiperlemma: 'que', start: 1, finish: 3 },
      { token: 'significa', tag: 'Vpi30s', lemma: 'significar', hiperlemma: 'significar', start: 5, finish: 13 },
      { token: 'para', tag: 'P', lemma: 'para', hiperlemma: 'para', start: 15, finish: 18 },
      { token: 'ti', tag: 'Rtp2as', lemma: 'ti', hiperlemma: 'ti', start: 20, finish: 21 },
      { token: 'a', tag: 'Ddfs', lemma: 'o', hiperlemma: 'o', start: 23, finish: 23 },
      { token: 'fórmula', tag: 'Scfs', lemma: 'fórmula', hiperlemma: 'fórmula', start: 25, finish: 31 },
      { token: formula, tag: 'Zs00', lemma: '*', hiperlemma: '*', start: formula_start, finish: formula_finish },
      { token: '?', tag: 'Q?', lemma: '?', hiperlemma: '?', start: text.length - 1, finish: text.length - 1 }
    ], output(text)
  end

  it 'keeps minimal subscript and superscript units together' do
    %w[subíndice superíndice].each do |mark|
      text = "Mide Al<#{mark}>2</#{mark}>."
      unit = "Al<#{mark}>2</#{mark}>"
      unit_start = text.index(unit)
      tokens = output(text)

      assert_equal unit, tokens[-2][:token]
      assert_equal unit_start, tokens[-2][:start]
      assert_equal unit_start + unit.length - 1, tokens[-2][:finish]
      assert_equal '.', tokens[-1][:token]
    end
  end

  it 'keeps unrelated XML outside the formula rule' do
    text = 'Falei Al<marca>2</marca>.'
    tokens = output(text)

    assert_equal ['falei', 'Al', '<marca>2</marca>', '.'], tokens.map { |token| token[:token] }
    assert_equal text.index('Al'), tokens[1][:start]
    assert_equal text.index('<marca>2</marca>'), tokens[2][:start]
  end
end
