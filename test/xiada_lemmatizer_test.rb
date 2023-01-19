require_relative 'test_helper'
require_relative '../running/bin/lemmatizer'
require_relative '../running/galician_xiada/lemmatizer'

def lemmatizer(dw)
  Lemmatizer.new(dw).extend(LemmatizerGalicianXiada)
end

Word = Struct.new(
  :word,
  :search_word,
  :search_tags,
  :dw_result,
  :lemmatizer_result,
)

describe LemmatizerGalicianXiada do
  it 'should get "mente" results with tag W if word ends in "mente"' do
    word = 'amablemente'
    dw_result = [['Wm', word, nil]]
    dw = Minitest::Mock.new

    dw.expect :get_guesser_result, dw_result, ["'mente'", word, ['W*']]
    result = lemmatizer(dw).lemmatize(word, nil)

    assert_mock dw
    assert_equal [['Wm', word, word]], result
  end

  describe '"isimo" suffix' do
    [
      # amabilísimo => amable
      Word.new('amabilísimo', 'amable', %w[A*m*], ['A0ms', 'amable', nil], ['Asms', 'amable', nil]),
      Word.new('amabilísimos', 'amables', %w[A*m*], ['A0mp', 'amable', nil], ['Asmp', 'amable', nil]),
      Word.new('amabilísima', 'amable', %w[A*f*], ['A0fs', 'amable', nil], ['Asfs', 'amable', nil]),
      Word.new('amabilísimas', 'amables', %w[A*f*], ['A0fp', 'amable', nil], ['Asfp', 'amable', nil]),
      # # riquísimo => rico
      Word.new('riquísimo', 'rico', %w[A*], ['A0ms', 'rico', nil], ['Asms', 'rico', nil]),
      Word.new('riquísimos', 'ricos', %w[A*], ['A0mp', 'rico', nil], ['Asmp', 'rico', nil]),
      Word.new('riquísima', 'rica', %w[A*], ['A0fs', 'rico', nil], ['Asfs', 'rico', nil]),
      Word.new('riquísimas', 'rica', %w[A*], ['A0fp', 'rico', nil], ['Asfp', 'rico', nil]),
      # # vaguísimo => vago
      Word.new('vaguísimo', 'vago', %w[A*], ['A0ms', 'vago', nil], ['Asms', 'vago', nil]),
      Word.new('vaguísimos', 'vagos', %w[A*], ['A0mp', 'vago', nil], ['Asmp', 'vago', nil]),
      Word.new('vaguísima', 'vaga', %w[A*], ['A0fs', 'vago', nil], ['Asfs', 'vago', nil]),
      Word.new('vaguísimas', 'vagas', %w[A*], ['A0fp', 'vago', nil], ['Asfp', 'vago', nil]),
      # # ambigüísimo => ambiguo
      Word.new('ambigüísimo', 'ambiguo', %w[A*], ['A0ms', 'ambiguo', nil], ['Asms', 'ambiguo', nil]),
      Word.new('ambigüísimos', 'ambiguos', %w[A*], ['A0mp', 'ambiguo', nil], ['Asmp', 'ambiguo', nil]),
      Word.new('ambigüísima', 'ambigua', %w[A*], ['A0fs', 'ambiguo', nil], ['Asfs', 'ambiguo', nil]),
      Word.new('ambigüísimas', 'ambiguas', %w[A*], ['A0fp', 'ambiguo', nil], ['Asfp', 'ambiguo', nil]),
      # pingüísimo => pingüe
      # FIXME: dw called twice
      Word.new('pingüísimo', 'pingüe', %w[A*m*], ['A0ms', 'pingüe', nil], ['Asms', 'pingüe', nil]),
      Word.new('pingüísimos', 'pingües', %w[A*m*], ['A0mp', 'pingüe', nil], ['Asmp', 'pingüe', nil]),
      Word.new('pingüísima', 'pingüe', %w[A*f*], ['A0fs', 'pingüe', nil], ['Asfs', 'pingüe', nil]),
      Word.new('pingüísimas', 'pingües', %w[A*f*], ['A0fp', 'pingüe', nil], ['Asfp', 'pingüe', nil]),
      # friísimo => frío
      Word.new('pingüísimo', 'frío', %w[A*], ['A0ms', 'frío', nil], ['Asms', 'frío', nil]),
      Word.new('pingüísimos', 'fríos', %w[A*], ['A0mp', 'frío', nil], ['Asmp', 'frío', nil]),
      Word.new('pingüísima', 'fría', %w[A*], ['A0fs', 'frío', nil], ['Asfs', 'frío', nil]),
      Word.new('pingüísimas', 'frías', %w[A*], ['A0fp', 'frío', nil], ['Asfp', 'frío', nil]),
    ].each do |word|
      it "#{word.word} should be lemmatized as #{word.lemmatizer_result}" do
        dw = Minitest::Mock.new
        pp word
        dw.expect :get_emissions_info, [word.dw_result], [word.search_word, word.search_tags]

        result = lemmatizer(dw).lemmatize(word.word, nil)

        assert_mock dw
        assert_equal [word.lemmatizer_result], result
      end
    end
  end
end
