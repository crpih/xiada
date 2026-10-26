require_relative 'test_helper'
require_relative 'support/corga_document'

class OrdinaryPeriodTest < Minitest::Test
  # Original regression inputs: written 704 and manually selected 20/21.
  def output(text, profile = 'galician_xiada')
    CorgaDocument.output('profile' => profile, 'input' => text)
  end

  def assert_word_and_period(tokens, text, word, tag, lemma)
    start = text.index("#{word}.")
    index = tokens.index { |token| token['token'] == word && token['start'] == start }
    refute_nil index, "Expected separate lexical word #{word}: #{tokens.inspect}"
    assert_equal({ 'token' => word, 'tag' => tag, 'lemma' => lemma, 'hiperlemma' => lemma,
                   'start' => start, 'finish' => start + word.length - 1 }, tokens[index])
    assert_equal({ 'token' => '.', 'tag' => 'Q.', 'lemma' => '.', 'hiperlemma' => '.',
                   'start' => start + word.length, 'finish' => start + word.length }, tokens[index + 1])
    index
  end

  def test_preserves_the_registered_abbreviation_with_an_initial_capital
    assert_equal [
      ['Al.', 'Za00', 'al.', '', 0, 2],
      ['12', 'Ncnms', '12', '', 4, 5]
    ], output('Al. 12').map { |token| token.values_at('token', 'tag', 'lemma', 'hiperlemma', 'start', 'finish') }
  end

  def test_does_not_turn_no_into_a_contraction_or_chemical_symbol
    # No. is not registered here: retain the pre-existing whole-token analysis.
    assert_equal [
      ['No.', 'Zams', '*', '*', 0, 2],
      ['3', 'Ncnms', '3', '', 4, 4]
    ], output('No. 3').map { |token| token.values_at('token', 'tag', 'lemma', 'hiperlemma', 'start', 'finish') }
  end

  def test_does_not_turn_co_into_a_contraction_or_chemical_symbol
    assert_equal [
      ['Co.', 'Zams', '*', '*', 0, 2],
      ['ltd', 'Scms', '*', '*', 4, 6],
      ['.', 'Q.', '.', '.', 7, 7]
    ], output('Co. Ltd.').map { |token| token.values_at('token', 'tag', 'lemma', 'hiperlemma', 'start', 'finish') }
  end

  def test_preserves_profiles_without_a_peripheral_category
    ['spanish_eslora', 'galician_eslora'].each do |profile|
      assert_equal [
        ['para.', 'NCMS', '*', '*', 0, 4],
        ['3', 'Cifra', '3', '', 6, 6]
      ], output('para. 3', profile).map { |token| token.values_at('token', 'tag', 'lemma', 'hiperlemma', 'start', 'finish') }
    end
  end

  def test_bibliographic_case_704_uses_lexical_words_instead_of_guessed_abbreviations
    text = '_A terra Chá luguesa. Estudio da súa problemática agraria. Ed. O Castro, Coruña, 1982.'
    tokens = output(text)

    index = assert_word_and_period(tokens, text, 'luguesa', 'A0fs', 'lugués')
    assert_equal ['Estudio', 'Scms', 'estudio'], tokens[index + 2].values_at('token', 'tag', 'lemma')
    assert_word_and_period(tokens, text, 'agraria', 'A0fs', 'agrario')
    assert tokens.any? { |token| token['token'] == 'Ed.' && token['tag'] == 'Za00' }
  end

  def test_manual_case_20_keeps_the_second_non_as_an_adverb
    text = 'petróleo Non a guerra. Non podemos.'
    tokens = output(text)

    index = assert_word_and_period(tokens, text, 'guerra', 'Scfs', 'guerra')
    assert_equal ['Non', 'Wn', 'non'], tokens[index + 2].values_at('token', 'tag', 'lemma')
  end

  def test_manual_case_21_keeps_the_second_non_as_an_adverb
    text = 'petróleo Non a guerra. Non embargante, Bebel era unha excepción.'
    tokens = output(text)

    index = assert_word_and_period(tokens, text, 'guerra', 'Scfs', 'guerra')
    assert_equal ['Non', 'Wn', 'non'], tokens[index + 2].values_at('token', 'tag', 'lemma')
  end
end

Minitest.after_run { CorgaDocument.close }
