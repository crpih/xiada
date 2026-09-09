require_relative "test_helper"
require_relative "../running/bin/config"
require_relative "../running/bin/xiada_tagger"
require_relative "../running/galician_xiada/enclitics/rule_matching"

class EncliticsReconstructionTest < Minitest::Test
  C16 = "Non sei que me pasa, váiseme a cabeza."
  C17 = "Por iso o camiño fáiseme curto."

  def setup
    params = YAML.load_file("profiles.example.yml", symbolize_names: true).find { |profile| profile[:profile] == "galician_xiada" }
    @tagger = XiadaTagger.new(Config::Tagger.new(**params))
    @document_config = Config::Document.new(seseo: true, gheada: true)
    @rule_matching = GalicianXiada::Enclitics::RuleMatching.new
  end

  def test_accented_vai_recovery_is_unaccented_only_for_a_multisyllabic_clitic_part
    assert_equal "vai", @rule_matching.call("vái", "Vpi30s", "seme", 2, "Vic27d", "vái")
    assert_equal "vái", @rule_matching.call("vái", "Vpi30s", "se", 1, "Vic27d", "vái")
  end

  def test_accented_fai_control_uses_the_same_recovery_without_changing_its_analysis
    assert_equal "fai", @rule_matching.call("fái", "Vpi30s", "seme", 2, "Vic22dt", "fái")
    assert_equal "fai", @rule_matching.call("fái", "Vpi30s", "seme", 2, "Vic22dt", "fai")
  end

  def test_complete_c16_and_c17_outputs
    expected = [
      [
        ["non", "Wn", "non", "non"],
        ["sei", "Vpi10s", "saber", "saber"],
        ["que", "Cs", "que", "que"],
        ["me", "Rad1as", "me", "me"],
        ["pasa", "Vpi30s", "pasar", "pasar"],
        [",", "Q,", ",", ","],
        ["vai", "Vpi30s", "ir", "ir"],
        ["se", "Rao3aa", "se", "se"],
        ["me", "Rad1as", "me", "me"],
        ["a", "Ddfs", "o", "o"],
        ["cabeza", "Scfs", "cabeza", "cabeza"],
        [".", "Q.", ".", "."],
      ],
      [
        ["por", "P", "por", "por"],
        ["iso", "Enns", "ese", "ese"],
        ["o", "Ddms", "o", "o"],
        ["camiño", "Scms", "camiño", "camiño"],
        ["fai", "Vpi30s", "facer", "facer"],
        ["se", "Rao3aa", "se", "se"],
        ["me", "Rad1as", "me", "me"],
        ["curto", "A0ms", "curto", "curto"],
        [".", "Q.", ".", "."],
      ],
    ]

    [C16, C17].each_with_index do |text, index|
      actual = @tagger.tag_texts(@document_config, [text]).first.map do |token|
        token.values_at(:token, :tag, :lemma, :hiperlemma)
      end

      assert_equal expected[index], actual, "complete C-#{index + 16} output"
    end
  end
end
