require_relative 'test_helper'
require_relative 'support/corga_document'
require_relative 'support/corga_client_assertions'

class CorgaDocumentContractTest < Minitest::Test
  include CorgaDocument::ClientAssertions
  def examples
    CorgaDocument.cases.to_h { |example| [example.fetch('id'), example] }
  end

  def test_every_case_has_a_client_contract_and_document_headings
    assert_equal 44, examples.size
    assert_equal 4, CorgaDocument.cases.count { |example| example.dig('expectation', 'type') == 'incomplete' }
    refute examples.key?('C3-01')
    refute examples.key?('C3-04')
    refute examples.key?('C5-01')
    CorgaDocument.cases.each do |example|
      refute_nil example['expectation'], example.fetch('id')
      assert_match(/\A#{example.fetch('id')[1]}. /, example.fetch('section'))
      assert_match(/\A#{example.fetch('id')[1]}\.\d+\. /, example.fetch('subsection'))
      refute_empty example.fetch('expected_description')
    end
  end

  def test_article_title_cases_are_preserved_but_deferred_from_acceptance
    expected_ids = [*(23..31).map { |number| "C4-#{number}" }, *(33..36).map { |number| "C4-#{number}" }]
    deferred = CorgaDocument.cases.select { |example| example.dig('acceptance', 'status') == 'deferred' }
    assert_equal expected_ids, deferred.map { |example| example.fetch('id') }
    deferred.each do |example|
      assert_match(/lexicon_titulos/, example.dig('acceptance', 'reason').to_s)
    end
    assert_equal 31, CorgaDocument.active_cases.size
    refute CorgaDocument.active_cases.any? { |example| expected_ids.include?(example.fetch('id')) }
  end

  def test_registered_contracts_are_runnable
    allowed = %w[unit sequence proper_prefix incomplete]
    CorgaDocument.cases.each do |example|
      assert_includes allowed, example.fetch('expectation').fetch('type'), example.fetch('id')
    end
  end

  def test_article_expectations_are_not_current_noun_observations
    (23..30).each do |number|
      contract = examples.fetch("C4-#{number}").fetch('expectation', {})
      assert_equal 'unit', contract['type']
      assert_equal 'O', contract['surface']
      assert_equal 'Ddms', contract['tag']
    end
  end

  def test_unavailable_source_is_an_explicit_failure_contract
    contract = examples.fetch('C4-32').fetch('expectation', {})
    assert_equal 'incomplete', contract['type']
    assert_match(/input/i, contract.fetch('reason', ''))
  end

  def test_known_lexical_expectations_include_tags_and_lemmas
    { 'C1-10' => ['Zs00', '€'], 'C1-11' => ['Y', 'ahum'],
      'C1-12' => ['Wn', 'de través'] }.each do |id, values|
      contract = examples.fetch(id).fetch('expectation', {})
      assert_equal values, [contract['tag'], contract['lemma']], id
    end
  end

  def test_c1_13_requires_percent_and_comma_boundaries_without_inventing_analysis
    example = examples.fetch('C1-13')
    expectation = example.fetch('expectation')
    assert_equal 'sequence', expectation.fetch('type')
    items = expectation.fetch('items')
    assert_equal ['%', ','], items.map { |item| item.fetch('surface') }
    items.each do |item|
      refute item.key?('tag')
      refute item.key?('lemma')
    end
    tokens = [output_token(example, '%', 'Zs00', '%'), output_token(example, ',', 'Q,', ',')]
    assert_client_expectation(example, tokens)
  end

  def test_undefined_expectations_are_not_fabricated_or_skipped
    %w[C1-09 C2-01 C2-02].each do |id|
      contract = examples.fetch(id).fetch('expectation', {})
      assert_equal 'incomplete', contract['type'], id
      refute_empty contract.fetch('reason', ''), id
    end
  end

  def test_medial_cases_keep_recovered_preceding_context
    %w[C4-31 C4-33 C4-34 C4-35 C4-36].each do |id|
      example = examples.fetch(id)
      assert_operator example.fetch('input').index(example.fetch('focus')), :>, 10, id
    end
  end

  def test_enumeration_rules_preserve_the_remaining_context
    (1..7).each do |n|
      assert_equal true, examples.fetch(format('C1-%02d', n)).dig('expectation', 'preserve_context')
    end
  end

  def test_article_assertion_rejects_the_current_noun_and_accepts_the_article
    example = examples.fetch('C4-23')
    error = assert_raises(Minitest::Assertion) do
      assert_client_expectation(example, [output_token(example, 'O', 'Scms', 'O')])
    end
    assert_match(/CLIENT MISMATCH \[C4-23\]/, error.message)
    assert_client_expectation(example, [output_token(example, 'O', 'Ddms', 'o')])
  end

  def test_peripheral_assertion_rejects_an_unknown_lemma
    example = examples.fetch('C1-01')
    assert_raises(Minitest::Assertion) do
      assert_client_expectation(example, [output_token(example, 'd)', 'Zo00', '*')])
    end
    assert_client_expectation(example, [output_token(example, 'd)', 'Zo00', 'd)')] + remaining_context_tokens(example))
  end

  def test_context_preservation_rejects_dropped_words
    example = examples.fetch('C1-01')
    error = assert_raises(Minitest::Assertion) do
      assert_client_expectation(example, [output_token(example, 'd)', 'Zo00', 'd)')])
    end
    assert_match(/preserved source context character/, error.message)
  end

  def test_lexical_word_cannot_keep_a_peripheral_tag
    example = examples.fetch('C7-01')
    good = [output_token(example, 'alemá', 'A0fs', 'alemán'), output_token(example, '.', 'Q.', '.'), output_token(example, ']', 'Q]', ']')]
    assert_client_expectation(example, good)
    wrong = good.map(&:dup)
    wrong.first['tag'] = 'Zg00'
    assert_raises(Minitest::Assertion) { assert_client_expectation(example, wrong) }
  end

  def test_unlisted_titles_require_only_the_detected_proper_fragment
    { 'C4-14' => 'Aspeitos', 'C4-19' => 'Las', 'C4-21' => 'Pteridológicas de Galicia' }.each do |id, surface|
      example = examples.fetch(id)
      expectation = example.fetch('expectation')
      assert_equal 'unit', expectation.fetch('type'), id
      assert_equal surface, expectation.fetch('surface'), id
      assert_client_expectation(example, [output_token(example, surface, 'Sp00', surface)])

      title = example.fetch('focus')
      assert_raises(Minitest::Assertion) do
        assert_client_expectation(example, [output_token(example, title, 'Sp00', title)])
      end
    end
  end

  def test_gerund_sequence_requires_both_closing_punctuation_marks
    example = examples.fetch('C7-04')
    tokens = [output_token(example, 'Cantarolando', 'V0x000', 'cantarolar'),
              output_token(example, '.', 'Q.', '.'), output_token(example, ')', 'Q)', ')')]
    assert_client_expectation(example, tokens)
    assert_raises(Minitest::Assertion) { assert_client_expectation(example, tokens[0...-1]) }
  end

  def test_punctuation_sequence_preserves_the_footnote_without_inventing_its_tag
    example = examples.fetch('C7-02')
    tokens = [output_token(example, 'amor', 'Scms', 'amor'), output_token(example, '.', 'Q.', '.'),
              output_token(example, '"', 'Q"', '"'), output_token(example, '6.', 'Ncnms', '6')]
    assert_client_expectation(example, tokens)
    error = assert_raises(Minitest::Assertion) { assert_client_expectation(example, tokens[0...-1]) }
    assert_match(/preserved footnote/, error.message)
  end

  def test_incomplete_contracts_fail_instead_of_skipping_or_passing
    CorgaDocument.cases.select { |example| example.fetch('expectation').fetch('type') == 'incomplete' }.each do |example|
      error = assert_raises(Minitest::Assertion) { assert_client_expectation(example, []) }
      assert_instance_of Minitest::Assertion, error
      assert_match(/CLIENT (EXPECTATION UNDEFINED|INPUT UNAVAILABLE)/, error.message)
    end
  end

  def test_recorded_observations_are_not_acceptance_contracts
    CorgaDocument.cases.each do |example|
      refute example.key?('observed_focus'), example.fetch('id')
    end
  end

  private

  def remaining_context_tokens(example)
    example.fetch('input').to_enum(:scan, /\S+/).filter_map do
      match = Regexp.last_match
      next if match.begin(0) < example.fetch('focus').length

      { 'token' => match[0], 'tag' => 'Scms', 'lemma' => match[0], 'hiperlemma' => '',
        'start' => match.begin(0), 'finish' => match.end(0) - 1 }
    end
  end

  def output_token(example, surface, tag, lemma)
    start = example.fetch('input').index(surface, example.fetch('input').index(example.fetch('focus')))
    { 'token' => surface, 'tag' => tag, 'lemma' => lemma, 'hiperlemma' => '',
      'start' => start, 'finish' => start + surface.length - 1 }
  end
end
