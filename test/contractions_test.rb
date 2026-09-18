require_relative "test_helper"
require_relative "../running/bin/config"
require_relative "../running/bin/xiada_tagger"

class ContractionsTest < Minitest::Test
  FULL_SENTENCE = "Pacto de Varsovia posicións máis críticas ca respecto das potencias occidentais"

  def setup
    profile = YAML.load_file("profiles.example.yml", symbolize_names: true).find { it[:profile] == "galician_xiada" }
    @tagger = XiadaTagger.new(Config::Tagger.new(**profile))
    @document = Config::Document.new(seseo: true, gheada: true)
  end

  def test_original_sentence_keeps_the_compact_conjunction_analysis
    result = @tagger.tag_texts(@document, [FULL_SENTENCE]).first

    assert_equal [
      { token: "pacto", tag: "Scms", lemma: "pacto", hiperlemma: "pacto", start: 0, finish: 4 },
      { token: "de", tag: "P", lemma: "de", hiperlemma: "de", start: 6, finish: 7 },
      { token: "Varsovia", tag: "Sp00", lemma: "Varsovia", hiperlemma: "", start: 9, finish: 16 },
      { token: "posicións", tag: "Scfp", lemma: "posición", hiperlemma: "posición", start: 18, finish: 26 },
      { token: "máis", tag: "Wm", lemma: "máis", hiperlemma: "máis", start: 28, finish: 31 },
      { token: "críticas", tag: "A0fp", lemma: "crítico", hiperlemma: "crítico", start: 33, finish: 40 },
      { token: "ca", tag: "Cs", lemma: "ca", hiperlemma: "ca", start: 42, finish: 43 },
      { token: "respecto", tag: "Scms", lemma: "respecto", hiperlemma: "respecto", start: 45, finish: 52 },
      { token: "de", tag: "P", lemma: "de", hiperlemma: "de", start: 54, finish: 56 },
      { token: "as", tag: "Ddfp", lemma: "o", hiperlemma: "o", start: 54, finish: 56 },
      { token: "potencias", tag: "Scfp", lemma: "potencia", hiperlemma: "potencia", start: 58, finish: 66 },
      { token: "occidentais", tag: "A0fp", lemma: "occidental", hiperlemma: "occidental", start: 68, finish: 78 },
    ], result

    contraction = result.slice(6, 2)
    refute contraction.any? { |token| token.values_at(:lemma, :hiperlemma).include?("*") }
  end

  def test_minimal_ca_is_segmented_with_valid_lemmas_and_offsets
    assert_equal [
      { token: "con", tag: "P", lemma: "con", hiperlemma: "con", start: 0, finish: 1 },
      { token: "a", tag: "Ddfs", lemma: "o", hiperlemma: "o", start: 0, finish: 1 },
    ], @tagger.tag_texts(@document, ["ca"]).first
  end

  def test_literal_con_a_and_related_contractions_keep_their_determiner_analysis
    ["con a casa", "coa casa", "da casa", "na casa"].each do |text|
      result = @tagger.tag_texts(@document, [text]).first

      assert_equal ["con", "a", "casa"], result.map { |token| token[:token] } if text == "con a casa"
      assert_equal ["con", "a", "casa"], result.map { |token| token[:token] } if text == "coa casa"
      assert_equal ["de", "a", "casa"], result.map { |token| token[:token] } if text == "da casa"
      assert_equal ["en", "a", "casa"], result.map { |token| token[:token] } if text == "na casa"
      assert_equal ["P", "Ddfs", "Scfs"], result.map { |token| token[:tag] }
      assert_equal ["con", "o", "casa"], result.map { |token| token[:lemma] } if text == "con a casa"
      assert_equal ["con", "o", "casa"], result.map { |token| token[:lemma] } if text == "coa casa"
      assert_equal ["de", "o", "casa"], result.map { |token| token[:lemma] } if text == "da casa"
      assert_equal ["en", "o", "casa"], result.map { |token| token[:lemma] } if text == "na casa"
    end
  end

  def test_unaccented_comparative_ca_keeps_its_conjunction_analysis_before_a_pronoun
    result = @tagger.tag_texts(@document, ["máis feliz ca ti"]).first

    assert_equal ["máis", "feliz", "ca", "ti"], result.map { |token| token[:token] }
    assert_equal ["Wm", "A0ms", "Cs", "Rtp2ms"], result.map { |token| token[:tag] }
    assert_equal ["máis", "feliz", "ca", "ti"], result.map { |token| token[:lemma] }
  end

  def test_literal_con_a_before_a_masculine_noun_still_uses_the_pruning_rule
    result = @tagger.tag_texts(@document, ["con a respecto"]).first

    assert_equal ["con", "a", "respecto"], result.map { |token| token[:token] }
    assert_equal ["P", "P", "Scms"], result.map { |token| token[:tag] }
    assert_equal ["con", "a", "respecto"], result.map { |token| token[:lemma] }
  end
end
