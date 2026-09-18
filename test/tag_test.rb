require_relative "test_helper"
require_relative "../running/bin/tag"

class TagTest < Minitest::Test
  def test_blank_hyperlemma_does_not_replace_a_value_from_fallback
    token = Object.new
    tag = Tag.new("Scfp", "infraestrutura", "infraestrutura", token)

    tag.add_lemma("infraestrutura", "")

    assert_equal "infraestrutura", tag.hiperlemmas["infraestrutura"]
  end

  def test_later_hyperlemma_does_not_replace_the_first_non_blank_value
    token = Object.new
    tag = Tag.new("Scfp", "infraestrutura", "infraestrutura", token)

    tag.add_lemma("infraestrutura", "other")

    assert_equal "infraestrutura", tag.hiperlemmas["infraestrutura"]
  end
end
