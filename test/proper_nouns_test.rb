require 'csv'
require_relative './test_helper'
require_relative '../running/bin/proper_nouns'

describe 'ProperNounsTest' do
  describe 'galician_xiada' do

    joiners = CSV.read("training/lexicons/galician_xiada/proper_nouns_links.txt", col_sep: "\t").map(&:first)
    main_lexicon = ProperNouns.parse_main_lexicon("training/lexicons/galician_xiada/lexicon_principal.txt")
    literals = ProperNouns.parse_literals_file("training/lexicons/galician_xiada/lexicon_propios.txt").first(500)

    ambiguous_literals = ProperNouns.parse_literals_file("training/lexicons/galician_xiada/lexicon_titulos.txt").first(500)
    # Reject literals that have uppercase in the middle, since it will be detected as standard proper noun, interfering with tests
    ambiguous_literals.filter! { |l| l.text.match?(/\A.[a-z1-9 ]+\z/) }
    # Reject literals that are contained in other literals, since it will be detected as part of the larger literal, interfering with tests
    ambiguous_literals.reject! { |l| ambiguous_literals.any? { |ol| ol != l && ol.text.include?(l.text) } }

    tags = CSV.read("training/lexicons/galician_xiada/proper_nouns_candidate_tags.txt", col_sep: "\t").map(&:first)

    describe 'literal proper nouns' do
      it 'should detect literals anywhere in the sentence' do
        proper_nouns = ProperNouns.new(main_lexicon, literals, ambiguous_literals, joiners, tags)
        literals.each do |literal|
          result = proper_nouns.call(literal.text)
          # Proper nouns detected at the beginning will have also tags from main lexicon
          text = literal.text
          text_first_lower = "#{text[0].downcase}#{text[1..-1]}"
          tag_lemmas = [literal, main_lexicon[text], main_lexicon[text_first_lower]].compact.flat_map(&:tag_lemmas).uniq
          expected = [ProperNouns::Literal.new(literal.text, tag_lemmas, true)]
          assert_equal expected, result, "Failed to detect literal proper noun: #{literal.text}"
        end
      end

      it 'should expand the range of the literal if next range is a standard proper noun' do
        proper_nouns = ProperNouns.new(main_lexicon, literals, ambiguous_literals, joiners, tags)
        literals.each do |literal|
          # Skip literals ending with punctuation, proper nouns after that won't be detected
          next if literal.text.match?(/[!?).]\z/)

          text = "#{literal.text} Hermenegildo"
          result = proper_nouns.call(text)
          expected = [ProperNouns::Literal.new(text, literal.tag_lemmas.map { |t, _| [t, text] }, true)]
          assert_equal expected, result, "Failed to expand literal proper noun: #{literal.text}"
        end
      end

      it 'should expand the range of the literal if next range is separated by a joiner' do
        proper_nouns = ProperNouns.new(main_lexicon, literals, ambiguous_literals, joiners, tags)
        joiners.each do |joiner|
          # Test with all literals is too slow, so we test with a sample
          literals.sample(10).each do |literal|
            text = "#{literal.text} #{joiner} Hermenegildo"
            result = proper_nouns.call(text)
            expected = [ProperNouns::Literal.new(text, literal.tag_lemmas.map { |t, _| [t, text] }, true)]
            assert_equal expected, result, "Failed to expand literal proper noun separated by joiner: #{joiner}"
          end
        end
      end

      it 'should not detect literals that are part of a larger word' do
        literal = ProperNouns::Literal.new("Xosé", [], true)
        proper_nouns = ProperNouns.new(main_lexicon, [literal], [], joiners, tags)

        # Case: literal is a suffix
        begin
          text = "Awe#{literal.text}"
          assert_equal [text], proper_nouns.call(text), "Incorrectly detected literal proper noun as suffix of a larger word: #{literal.text}"
        end

        # Case: literal is a prefix
        begin
          text = "#{literal.text}wef"
          assert_equal [text], proper_nouns.call(text), "Incorrectly detected literal proper noun as prefix of a larger word: #{literal.text}"
        end

        # Case: literal is in the middle
        begin
          text = "Awe#{literal.text}wef"
          assert_equal [text], proper_nouns.call(text), "Incorrectly detected literal proper noun in the middle of a larger word: #{literal.text}"
        end
      end

      it 'should expand the range of the literal second word to the text begin if the text starts with uppercase' do
        proper_nouns = ProperNouns.new(main_lexicon, literals, ambiguous_literals, joiners, tags)
        literals.each do |literal|
          text = "Awdrgyji #{literal.text}"
          result = proper_nouns.call(text).first
          assert_equal text, result.text, "Failed to expand literal proper noun at the beginning of the text: #{literal.text}"
          result.tag_lemmas.each do |_tag, lemma|
            assert_equal text, lemma, "Failed to expand literal proper noun at the beginning of the text: #{literal.text}"
          end
        end
      end
    end

    describe 'ambiguous literal proper nouns' do
      it 'should detect ambiguous literals in the middle of the sentence' do
        proper_nouns = ProperNouns.new(main_lexicon, [], ambiguous_literals, joiners, tags)
        ambiguous_literals.each do |literal|
          text = "Eu son #{literal.text}."
          result = proper_nouns.call(text)
          expected = [
            "Eu son ",
            ProperNouns::Literal.new(literal.text, literal.tag_lemmas, true),
            "."
          ]
          assert_equal expected, result, "Failed to detect literal proper noun: #{literal.text}"
        end
      end

      it 'should not detect ambiguous literals at the beginning of the sentence' do
        proper_nouns = ProperNouns.new(main_lexicon, [], ambiguous_literals, joiners, tags)
        ambiguous_literals.each do |literal|
          text = "#{literal.text} é un nome."
          result = proper_nouns.call(text)
          expected = [text]
          assert_equal expected, result, "Incorrectly detected ambiguous literal proper noun at the beginning of the sentence: #{literal.text}"
        end
      end

      it 'should not detect ambiguous literals at the beginning of the text preceded by " \' or (' do
        proper_nouns = ProperNouns.new(main_lexicon, [], ambiguous_literals, joiners, tags)
        ambiguous_literals.each do |literal|
          %w[" ' (].each do |char|
            text = "#{char}#{literal.text} é un nome."
            result = proper_nouns.call(text)
            expected = [text]
            assert_equal expected, result, "Incorrectly detected ambiguous literal proper noun at the beginning of the text preceded by #{char}: #{literal.text}"
          end
        end
      end

      it 'should not detect ambiguous literals that are part of a larger word' do
        literal = ProperNouns::Literal.new("Título", [], true)
        proper_nouns = ProperNouns.new(main_lexicon, [], [literal], joiners, tags)

        # Case: literal is a suffix
        begin
          text = "Awe#{literal.text}"
          assert_equal [text], proper_nouns.call(text), "Incorrectly detected ambiguous literal proper noun as suffix of a larger word: #{literal.text}"
        end

        # Case: literal is a prefix
        begin
          text = "#{literal.text}wef"
          assert_equal [text], proper_nouns.call(text), "Incorrectly detected ambiguous literal proper noun as prefix of a larger word: #{literal.text}"
        end

        # Case: literal is in the middle
        begin
          text = "Awe#{literal.text}wef"
          assert_equal [text], proper_nouns.call(text), "Incorrectly detected ambiguous literal proper noun in the middle of a larger word: #{literal.text}"
        end
      end
    end

    describe 'standard proper nouns' do
      it 'should detect uppercases not after punctuation' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        %w[? ! . )].each do |punctuation|
          text = "Ola, que tal#{punctuation} Eu son o Xoán."
          result = proper_nouns.call(text)
          expected = [
            "Ola, que tal#{punctuation} Eu son o ",
            ProperNouns::Literal.new("Xoán", tags.map { |tag| [tag, "Xoán"] }.sort, false),
            "."
          ]
          assert_equal expected, result, "Failed to detect proper noun not after punctuation: #{punctuation}"
        end
      end

      it 'should not detect uppercases at the beginning of a sentence' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        text = "Xoán é un nome."
        assert_equal [text], proper_nouns.call(text)
      end

      it 'should detect proper nouns separated by joiners' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        joiners.each do |joiner|
          text = "Son Xoán #{joiner} García."
          noun_start = 4
          noun_end = noun_start + 5 + joiner.size + 7
          result = proper_nouns.call(text)
          expected = [
            text[0...noun_start],
            ProperNouns::Literal.new("Xoán #{joiner} García", tags.map { |tag| [tag, "Xoán #{joiner} García"] }.sort, false),
            text[noun_end...text.size]
          ]
          assert_equal expected, result, "Failed to detect proper noun separated by joiner: #{joiner}"
        end
      end

      it 'should detect proper nouns between parens' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        text = "Dixo (Xoán)."
        result = proper_nouns.call(text)
        expected = [
          "Dixo (",
          ProperNouns::Literal.new("Xoán", tags.map { |tag| [tag, "Xoán"] }.sort, false),
          ")."
        ]
        assert_equal expected, result, "Failed to detect proper noun between parens: #{text}"
      end

      it 'should detect road names' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        text = "Vou pola AP-9."
        result = proper_nouns.call(text)
        expected = [
          "Vou pola ",
          ProperNouns::Literal.new("AP-9", tags.map { |tag| [tag, "AP-9"] }.sort, false),
          "."
        ]
        assert_equal expected, result, "Failed to detect road name: #{text}"
      end

      it 'should detect proper nouns with a single quote in the middle' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        text = "Dixo L'Oréal."
        result = proper_nouns.call(text)
        expected = [
          "Dixo ",
          ProperNouns::Literal.new("L'Oréal", tags.map { |tag| [tag, "L'Oréal"] }.sort, false),
          "."
        ]
        assert_equal expected, result, "Failed to detect proper noun with single quote in the middle: #{text}"
      end

      it 'should detect proper nouns with a single hyphen in the middle' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        text = "a Barcelona-Tarragona."
        result = proper_nouns.call(text)
        expected = [
          "a ",
          ProperNouns::Literal.new("Barcelona-Tarragona", tags.map { |tag| [tag, "Barcelona-Tarragona"] }.sort, false),
          "."
        ]
        assert_equal expected, result, "Failed to detect proper noun with single hyphen in the middle: #{text}"
      end

      it 'should detect proper nouns with an ampersand in the middle' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        text = "Dixo H&M."
        result = proper_nouns.call(text)
        expected = [
          "Dixo ",
          ProperNouns::Literal.new("H&M", tags.map { |tag| [tag, "H&M"] }.sort, false),
          "."
        ]
        assert_equal expected, result, "Failed to detect proper noun with ampersand in the middle: #{text}"
      end

      it 'should detect proper nouns with CamelCase' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        text = "Estamos navegando YouTube."
        result = proper_nouns.call(text)
        expected = [
          "Estamos navegando ",
          ProperNouns::Literal.new("YouTube", tags.map { |tag| [tag, "YouTube"] }.sort, false),
          "."
        ]
        assert_equal expected, result, "Failed to detect proper noun with CamelCase: #{text}"
      end

      it 'should detect abbreviated proper nouns before a proper noun' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        text = "O D. Xoán é un nome."
        result = proper_nouns.call(text)
        expected = [
          "O ",
          ProperNouns::Literal.new("D. Xoán", tags.map { |tag| [tag, "D. Xoán"] }.sort, false),
          " é un nome."
        ]
        assert_equal expected, result, "Failed to detect abbreviated proper noun before a proper noun: #{text}"
      end

      it 'should detect abbreviated proper after a proper noun' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        text = "O Xoán D. é un nome."
        result = proper_nouns.call(text)
        expected = [
          "O ",
          ProperNouns::Literal.new("Xoán D.", tags.map { |tag| [tag, "Xoán D."] }.sort, false),
          " é un nome."
        ]
        assert_equal expected, result, "Failed to detect abbreviated proper noun after a proper noun: #{text}"
      end
    end

    describe 'trained proper nouns' do
      it 'should detect trained proper nouns at the beginning of the sentence' do
        no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)

        no_train_result = no_train_proper_nouns.call('Hermenegildo é un nome.')
        assert_equal ['Hermenegildo é un nome.'], no_train_result

        trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Hermenegildo.'])
        result = trained_proper_nouns.call('Hermenegildo é un nome.')
        expected = [
          ProperNouns::Literal.new('Hermenegildo', tags.map { |tag| [tag, 'Hermenegildo'] }.sort, false),
          ' é un nome.'
        ]
        assert_equal expected, result
      end

      it 'should not detect previously trained proper nouns if they appear in a composite word' do
        no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)

        trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Rei'])
        result = trained_proper_nouns.call('pero el-Rei cumprira.')
        expected = ['pero el-Rei cumprira.']
        assert_equal expected, result
      end
    end
  end
end
