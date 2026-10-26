require 'set'
require_relative 'test_helper'
require_relative '../running/bin/sentence'

class SentenceTest < Minitest::Test
  def setup
    @sentence = Sentence.allocate
    @sentence.instance_variable_set(:@abbreviations, Set.new)
    @sentence.instance_variable_set(:@acronyms, Set.new)
  end

  DirectLexicon = Struct.new(:entries, :abbreviation_sources, :fallbacks, :peripheric_pattern) do
    def get_peripheric_regexp = peripheric_pattern
    def get_tags_lemmas_emissions_strict(word, _tags) = entries.fetch(word, [])
    def get_emissions_info(word, tags)
      fallbacks.fetch(word) { get_tags_lemmas_emissions_strict(word, tags) }
    end
  end

  def sentence_units(text, entries: {}, abbreviations: {}, acronyms: {}, sources: {}, fallbacks: {}, peripheric_pattern: '^Z')
    lexicon = DirectLexicon.new(entries, sources, fallbacks, peripheric_pattern)
    sentence = Sentence.new(
      tagger_config: Struct.new(:dw).new(lexicon), document_config: nil,
      acronyms: acronyms, abbreviations: abbreviations, enclitics: {},
      proper_nouns_processor: nil, text: text
    )
    token = sentence.first_token.next
    units = []
    until token == sentence.last_token
      units << [token.text, token.from, token.to]
      token = token.next
    end
    units
  end

  def test_separates_internal_periods_only_with_direct_lexical_evidence
    units = sentence_units('guerra. luguesa. despois', entries: {
      'guerra' => [['Scfs', 'guerra', 'guerra', 0.0], ['Zs00', 'guerra', '', 0.0]],
      'luguesa' => [['A0fs', 'lugués', 'lugués', 0.0]]
    })

    assert_equal [['guerra', 0, 5], ['.', 6, 6], ['luguesa', 8, 14],
                  ['.', 15, 15], ['despois', 17, 23]], units
  end

  def test_preserves_registered_units_exact_analyses_and_unknown_bases
    entries = {
      'Dr' => [['Scms', 'Dr', '', 0.0]],
      'ONU' => [['Zg00', 'ONU', '', 0.0]],
      'voz' => [['Scfs', 'voz', '', 0.0]],
      'voz.' => [['Za00', 'voz.', '', 0.0]],
      'g' => [['Zs00', 'g', '', 0.0]]
    }
    text = 'Dr. ONU. voz. g. xenopraxe. R.Ch. despois'

    assert_equal ['Dr.', 'ONU.', 'voz.', 'g.', 'xenopraxe.', 'R.Ch.', 'despois'],
      sentence_units(text, entries: entries, abbreviations: { 'Dr.' => true },
                     acronyms: { 'ONU.' => true }).map(&:first)
  end

  def test_preserves_a_whole_form_recovered_by_normal_lexical_lookup
    # The whole-form fallback wins even when an ordinary lexical base exists.
    entries = { 'Al' => [['Scms', 'al', 'al', 0.0]] }
    fallbacks = { 'Al.' => [['Za00', 'al.', '', 0.0]] }

    assert_equal [['Al.', 0, 2], ['despois', 4, 10]],
      sentence_units('Al. despois', entries: entries, fallbacks: fallbacks)
  end

  def test_does_not_split_bases_with_only_peripheral_analyses
    entries = {
      'No' => [['Zs00', 'No', '', 0.0]],
      'Co' => [['Zs00', 'Co', '', 0.0], ['Za00', 'co', '', 0.0]]
    }

    assert_equal [['No.', 0, 2], ['Co.', 4, 6], ['despois', 8, 14]],
      sentence_units('No. Co. despois', entries: entries)
  end

  def test_preserves_tokens_when_the_profile_has_no_peripheral_category
    entries = { 'guerra' => [['Scfs', 'guerra', 'guerra', 0.0]] }

    assert_equal [['guerra.', 0, 6], ['despois', 8, 14]],
      sentence_units('guerra. despois', entries: entries, peripheric_pattern: nil)
  end

  def test_preserves_multiword_abbreviations_before_splitting_component_dots
    text = 'ab init. despois'
    sources = { 'ab init.' => ['ab init.'] }
    entries = { 'init' => [['Scms', 'init', '', 0.0]] }

    assert_equal [['ab init.', 0, 7], ['despois', 9, 15]],
      sentence_units(text, entries: entries, abbreviations: { 'ab init.' => true }, sources: sources)
  end

  def test_keeps_existing_numeric_and_url_tokenization
    assert_equal ['2.1', '.', 'https://example.org.', 'despois'],
      sentence_units('2.1. https://example.org. despois').map(&:first)
  end

  def test_separates_a_standalone_percent_symbol_from_following_comma
    assert_equal ['%', ','], @sentence.tokenize('%,', false)
  end

  def test_keeps_numeric_percentages_attached_before_following_comma
    assert_equal ['25%', ','], @sentence.tokenize('25%,', false)
  end
end
