require_relative "test_helper"
require_relative "../running/bin/config"
require_relative "../running/bin/xiada_tagger"

class DeTravesTest < Minitest::Test
  # Source: test/regression/tagger/galician_xiada_escrita_manual_cases.csv:61;
  # historical output: test/regression/tagger/proper-nouns-exact-case-diff.md:75–78 (snapshot 23).
  CONTEXT = "entraba en o porto con a monteira de través e tocando a gaita en a proa."

  def setup
    profile = YAML.load_file("profiles.example.yml", symbolize_names: true).find { it[:profile] == "galician_xiada" }
    @tagger = XiadaTagger.new(Config::Tagger.new(**profile))
    @document = Config::Document.new(seseo: true, gheada: true)
  end

  def test_contextual_manual_case_preserves_sentence_and_recognizes_de_traves
    assert_equal [
      { token: "entraba", tag: "Vii30s", lemma: "entrar", hiperlemma: "entrar", start: 0, finish: 6 },
      { token: "en", tag: "P", lemma: "en", hiperlemma: "en", start: 8, finish: 9 },
      { token: "o", tag: "Ddms", lemma: "o", hiperlemma: "o", start: 11, finish: 11 },
      { token: "porto", tag: "Scms", lemma: "porto", hiperlemma: "porto", start: 13, finish: 17 },
      { token: "con", tag: "P", lemma: "con", hiperlemma: "con", start: 19, finish: 21 },
      { token: "a", tag: "Ddfs", lemma: "o", hiperlemma: "o", start: 23, finish: 23 },
      { token: "monteira", tag: "Scfs", lemma: "monteira", hiperlemma: "monteira", start: 25, finish: 32 },
      { token: "de través", tag: "Wn", lemma: "de través", hiperlemma: "de través", start: 34, finish: 42 },
      { token: "e", tag: "Cc", lemma: "e", hiperlemma: "e", start: 44, finish: 44 },
      { token: "tocando", tag: "V0x000", lemma: "tocar", hiperlemma: "tocar", start: 46, finish: 52 },
      { token: "a", tag: "Ddfs", lemma: "o", hiperlemma: "o", start: 54, finish: 54 },
      { token: "gaita", tag: "Scfs", lemma: "gaita", hiperlemma: "gaita", start: 56, finish: 60 },
      { token: "en", tag: "P", lemma: "en", hiperlemma: "en", start: 62, finish: 63 },
      { token: "a", tag: "Ddfs", lemma: "o", hiperlemma: "o", start: 65, finish: 65 },
      { token: "proa", tag: "Scfs", lemma: "proa", hiperlemma: "proa", start: 67, finish: 70 },
      { token: ".", tag: "Q.", lemma: ".", hiperlemma: ".", start: 71, finish: 71 },
    ], @tagger.tag_texts(@document, [CONTEXT]).first
  end
end
