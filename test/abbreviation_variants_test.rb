require_relative 'test_helper'
require_relative '../lib/abbreviation_variants'

class AbbreviationVariantsTest < Minitest::Test
  def test_iterates_every_combination_of_component_spaces_from_either_spelling
    expected = ['a.d.C.', 'a. d.C.', 'a.d. C.', 'a. d. C.']
    ['a.d.C.', 'a. d. C.'].each do |form|
      original = form.dup
      assert_equal expected, AbbreviationVariants.each(form).to_a
      assert_equal original, form
    end
  end

  def test_single_components_and_ordinal_suffixes_are_not_split
    ['Dr.', 'AA.', '1.º', '1.ª', 's/n'].each do |form|
      assert_equal [form], AbbreviationVariants.each(form).to_a
    end
  end

  def test_existing_component_boundaries_can_be_removed_without_splitting_letters
    assert_equal ['abinit.', 'ab init.'], AbbreviationVariants.each('ab init.').to_a
    assert_equal ['CC.AA.', 'CC. AA.'], AbbreviationVariants.each('CC. AA.').to_a
  end
end
