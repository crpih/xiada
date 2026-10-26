require_relative 'test_helper'
require_relative 'support/corga_document'

class AbbreviationSpacingTest < Minitest::Test
  def teardown
    CorgaDocument.close
  end

  def output(text, profile = 'galician_xiada')
    CorgaDocument.output('profile' => profile, 'input' => text)
  end

  def test_registered_and_compact_abbreviations_keep_lexical_analysis_and_source_positions
    { 'a. C.' => ['a. C.', 'a.C.'], 'a. m.' => ['a. m.', 'a.m.'],
      'ab init.' => ['ab init.', 'abinit.'] }.each do |lemma, variants|
      variants.each do |variant|
        text = "Foi #{variant}, despois."
        tokens = output(text)
        token = tokens.find { |entry| entry['token'] == variant }
        refute_nil token, "Missing abbreviation #{variant}: #{tokens.inspect}"
        assert_equal({ 'token' => variant, 'tag' => 'Za00', 'lemma' => lemma,
                       'hiperlemma' => '', 'start' => 4, 'finish' => 3 + variant.length }, token)
        assert_equal ',', tokens[tokens.index(token) + 1]['token']
      end
    end
  end

  def test_each_intermediate_spacing_variant_is_recognized
    ['A.M.D.G.', 'A. M.D.G.', 'A.M. D.G.', 'A. M. D.G.',
     'A.M.D. G.', 'A. M.D. G.', 'A.M. D. G.', 'A. M. D. G.'].each do |variant|
      token = output("Foi #{variant} despois").find { |entry| entry['token'] == variant }
      refute_nil token, variant
      assert_equal({ 'token' => variant, 'tag' => 'Za00', 'lemma' => 'A. M. D. G.',
                     'hiperlemma' => '', 'start' => 4, 'finish' => 3 + variant.length }, token)
    end
  end

  def test_registered_forms_have_priority_over_generated_variants
    { 'p.e.' => ['p.e.', 'p. ex.'], 'p. e.' => ['p. e.', ''],
      'o.c.' => ['o.c.', 'o. c.'], 'o. c.' => ['o. c.', ''] }.each do |variant, analysis|
      token = output("Foi #{variant} despois").find { |entry| entry['token'] == variant }
      refute_nil token, variant
      assert_equal ['Za00', *analysis], token.values_at('tag', 'lemma', 'hiperlemma')
    end
  end

  def test_initial_and_final_abbreviations_preserve_spelling_and_punctuation
    ['a.m.', 'a. m.'].each do |variant|
      tokens = output("(#{variant})")
      assert_equal ['(', variant, ')'], tokens.map { |token| token['token'] }
      assert_equal ['Za00', 'a. m.', ''], tokens[1].values_at('tag', 'lemma', 'hiperlemma')
      assert_equal [1, variant.length], tokens[1].values_at('start', 'finish')
      assert_equal variant, output(variant).first['token']
    end
  end

  def test_single_component_punctuation_is_not_reinterpreted_as_an_abbreviation
    assert_equal [
      { 'token' => '(', 'tag' => 'Q(', 'lemma' => '(', 'hiperlemma' => '(', 'start' => 0, 'finish' => 0 },
      { 'token' => 'dr', 'tag' => 'Wn', 'lemma' => '*', 'hiperlemma' => '*', 'start' => 1, 'finish' => 2 },
      { 'token' => '.', 'tag' => 'Q.', 'lemma' => '.', 'hiperlemma' => '.', 'start' => 3, 'finish' => 3 },
      { 'token' => ')', 'tag' => 'Q)', 'lemma' => ')', 'hiperlemma' => ')', 'start' => 4, 'finish' => 4 }
    ], output('(Dr.)')
    assert_equal [
      { 'token' => 'foi', 'tag' => 'Vei30sser', 'lemma' => 'ser', 'hiperlemma' => 'ser', 'start' => 0, 'finish' => 2 },
      { 'token' => 'a', 'tag' => 'Ddfs', 'lemma' => 'o', 'hiperlemma' => 'o', 'start' => 4, 'finish' => 4 },
      { 'token' => '.', 'tag' => 'Q.', 'lemma' => '.', 'hiperlemma' => '.', 'start' => 6, 'finish' => 6 }
    ], output('Foi a .')
  end

  def test_resources_without_compatible_model_analyses_do_not_change_other_profiles
    tokens = output('Foi a. m., despois.', 'spanish_eslora')
    assert_equal [
      ['Foi', 'NPEL', 'Foi', '', 0, 2],
      ['a.', 'NCMS', '*', '*', 4, 5],
      ['m.', 'NCMS', '*', '*', 7, 8],
      [',', 'Q', ',', '', 9, 9],
      ['despois', 'NCMS', '*', '*', 11, 17],
      ['.', 'Q', '.', '', 18, 18]
    ], tokens.map { |token| token.values_at('token', 'tag', 'lemma', 'hiperlemma', 'start', 'finish') }
  end

  def test_single_component_acronym_and_idiom_controls_are_unchanged
    assert_equal ['foi', 'Dr.', 'despois'], output('Foi Dr. despois').map { |t| t['token'] }
    assert_equal ['desde', 'de', 'través', 'de', 'casa'], output('Desde de través de casa').map { |t| t['token'] }
    assert_equal 'Zgfs', output('Foi ONU despois').find { |t| t['token'] == 'ONU' }['tag']
    refute output('Foi xa.m. despois').any? { |t| t['lemma'] == 'a. m.' }
    refute output('Foi a.m.algo despois').any? { |t| t['lemma'] == 'a. m.' }
  end
end
