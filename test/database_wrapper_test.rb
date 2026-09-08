require_relative "test_helper"
require_relative "../running/bin/database_wrapper"

class DatabaseWrapperTest < Minitest::Test
  EmissionConfig = Struct.new(:profile, :only_lexicon, :lemmatizer)
  LemmatizerStub = Struct.new(:calls) do
    def lemmatize(*)
      calls << true
      raise "lemmatizer should not be called when the lowercase emission exists"
    end

    def lemmatize_verb_with_enclitics(_document_config, _root)
      ["Canto"]
    end
  end

  def test_exact_emission_has_priority_over_lowercase_fallback
    wrapper = build_wrapper(
      emissions: {
        "Infraestructuras" => [["Sp00", "exact", "", 1.0]],
        "infraestructuras" => [["Scfp", "infraestrutura", "", 2.0]],
      }
    )

    assert_equal [["Sp00", "exact", "", 1.0]], wrapper.get_emissions_info("Infraestructuras", nil)
  end

  def test_capitalized_emission_falls_back_without_mutating_the_input
    wrapper = build_wrapper(
      emissions: {
        "infraestructuras" => [["Scfp", "infraestrutura", "", 2.0]],
      }
    )
    word = "Infraestructuras"

    result = wrapper.get_emissions_info(word, nil)

    assert_equal [["Scfp", "infraestrutura", "", 2.0]], result
    assert_equal "Infraestructuras", word
  end

  def test_fallback_is_used_by_the_full_emission_lookup_before_lemmatization
    lemmatizer = LemmatizerStub.new([])
    wrapper = build_wrapper(
      emissions: {
        "somos" => [["Vpi10p", "ser", "", 2.0]],
      },
      lemmatizer:
    )

    result = wrapper.get_tags_lemmas_emissions(Object.new, "Somos", nil)

    assert_equal [["Vpi10p", "ser", "", 2.0]], result
    assert_empty lemmatizer.calls
  end

  def test_uppercase_words_are_not_treated_as_initial_capitals
    wrapper = build_wrapper(
      emissions: {
        "infraestructuras" => [["Scfp", "infraestrutura", "", 2.0]],
      }
    )

    assert_empty wrapper.get_emissions_info("INFRAESTRUCTURAS", nil)
  end

  def test_fallback_is_shared_by_all_profiles
    wrapper = build_wrapper(
      profile: "spanish_eslora",
      emissions: {
        "programa" => [["NCMS", "programa", "", 2.0]],
      }
    )

    assert_equal [["NCMS", "programa", "", 2.0]], wrapper.get_emissions_info("Programa", nil)
  end

  def test_enclitic_root_lookup_uses_the_same_fallback_and_preserves_exact_priority
    wrapper = build_wrapper(
      roots: {
        "canto" => [["canto", "Vpi10s", "cantar", "", "Vc1"]],
      }
    )

    assert_equal [["canto", "Vpi10s", "cantar", "", "Vc1"]],
                 wrapper.get_enclitic_verb_roots_info(Object.new, "Canto", ["Vpi10s"])

    wrapper = build_wrapper(
      roots: {
        "Canto" => [["Canto", "Vpi10s", "exact", "", "Vc1"]],
        "canto" => [["canto", "Vpi10s", "fallback", "", "Vc1"]],
      }
    )

    assert_equal [["Canto", "Vpi10s", "exact", "", "Vc1"]],
                 wrapper.get_enclitic_verb_roots_info(Object.new, "Canto", ["Vpi10s"])
  end

  private

  def build_wrapper(profile: "galician_xiada", emissions: {}, roots: {}, lemmatizer: LemmatizerStub.new([]))
    wrapper = DatabaseWrapper.allocate
    wrapper.instance_variable_set(:@tagger_config, EmissionConfig.new(profile, false, lemmatizer))
    wrapper.define_singleton_method(:get_possible_tags) { |_tags| [] }
    wrapper.define_singleton_method(:execute) do |query, bind_vars = []|
      table = query.include?("emission_frequencies") ? emissions : roots
      table.fetch(bind_vars.first, [])
    end
    wrapper
  end
end
