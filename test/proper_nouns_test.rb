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

      it 'should NOT detect proper noun when preceded only by date and separators' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)

        # Casos donde SOLO hay fecha + separadores (sin texto real)
        [
          '1977: Un',           # Año con dos puntos
          '(1345- Cando',       # Año en paréntesis con guion
          '(1977) Un',          # Año entre paréntesis
          '12345 Un',           # 5 dígitos (cantidad)
        ].each do |text|
          result = proper_nouns.call(text)
          proper_noun_literals = result.select { |r| r.is_a?(ProperNouns::Literal) }
          assert_empty proper_noun_literals,
            "Should NOT detect proper noun in: #{text.inspect}"
        end
      end

      it 'should detect proper noun when preceded by text before date' do
        proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)

        # Casos donde hay texto real antes del año
        {
          'No ano 1977: Un día' => 'Un',
          'En 2024: Ana naceu' => 'Ana',
        }.each do |text, expected_noun|
          result = proper_nouns.call(text)
          proper_noun_literals = result.select { |r| r.is_a?(ProperNouns::Literal) }

          refute_empty proper_noun_literals,
            "Should detect '#{expected_noun}' in: #{text.inspect}"
          assert_equal expected_noun, proper_noun_literals.first.text,
            "Expected '#{expected_noun}' but got '#{proper_noun_literals.first&.text}'"
        end
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

      # GROUP A: Detection in multiple positions, wrapper chars, multiple occurrences
      describe 'trained detection in multiple positions' do
        it 'should detect trained proper nouns in the middle of a sentence' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

          result = trained_proper_nouns.call('Falei con Ana onte.')
          expected = [
            'Falei con ',
            ProperNouns::Literal.new('Ana', tags.map { |tag| [tag, 'Ana'] }.sort, false),
            ' onte.'
          ]
          assert_equal expected, result
        end

        it 'should detect trained proper nouns at the end of a sentence' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

          result = trained_proper_nouns.call('Ola, Ana.')
          expected = [
            'Ola, ',
            ProperNouns::Literal.new('Ana', tags.map { |tag| [tag, 'Ana'] }.sort, false),
            '.'
          ]
          assert_equal expected, result
        end

        it 'should detect trained proper nouns after wrapper characters' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Xiana.'])

          %w[" ' (].each do |wrapper|
            text = "Dixo #{wrapper}Xiana é un nome."
            result = trained_proper_nouns.call(text)
            expected = [
              "Dixo #{wrapper}",
              ProperNouns::Literal.new('Xiana', tags.map { |tag| [tag, 'Xiana'] }.sort, false),
              ' é un nome.'
            ]
            assert_equal expected, result, "Failed to detect trained proper noun after wrapper: #{wrapper}"
          end
        end

        it 'should detect multiple occurrences of the same trained proper noun' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

          result = trained_proper_nouns.call('Ana chamou a Ana.')
          expected = [
            ProperNouns::Literal.new('Ana', tags.map { |tag| [tag, 'Ana'] }.sort, false),
            ' chamou a ',
            ProperNouns::Literal.new('Ana', tags.map { |tag| [tag, 'Ana'] }.sort, false),
            '.'
          ]
          assert_equal expected, result
        end
      end

      # GROUP B: Training filters (lexicon exclusions, ambiguous positions)
      describe 'training filters' do
        it 'should not train proper nouns that exist in main lexicon (case-insensitive)' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          # "non" exists in lexicon as lowercase, so "Non" should not be trained
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Non é un nome.'])

          # Should not detect "Non" as trained proper noun
          result = trained_proper_nouns.call('Non é un nome.')
          expected = ['Non é un nome.']
          assert_equal expected, result
        end

        it 'should not train proper nouns from ambiguous positions (sentence start)' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          # "Pedro" at sentence start is ambiguous, should not be trained
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Pedro é un nome.'])

          # Should not detect "Pedro" as trained from ambiguous position
          # Disable standard detection to avoid regex matching "Pedro"
          result = trained_proper_nouns.call('Falei con Pedro.', standard: false)
          expected = ['Falei con Pedro.']
          assert_equal expected, result
        end

        it 'should not train proper nouns after wrapper characters at text start' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          # "Luis" after wrapper at text start is ambiguous
          trained_proper_nouns = no_train_proper_nouns.with_trained(['"Luis é un nome.'])

          # Should not detect "Luis" as trained from ambiguous position
          # Disable standard detection to avoid regex matching "Luis"
          result = trained_proper_nouns.call('Falei con Luis.', standard: false)
          expected = ['Falei con Luis.']
          assert_equal expected, result
        end
      end

      # GROUP C: New marker rules (chapter/list markers, punctuation-only, road names)
      # The purpose of training is to detect proper nouns in ambiguous positions
      describe 'trained proper nouns in ambiguous positions' do
        it 'should detect trained proper nouns after chapter markers' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

          # Chapter markers like "1. ", "a) ", etc. are ambiguous positions
          # But trained proper nouns SHOULD be detected there
          result = trained_proper_nouns.call('1. Ana é un capítulo.')
          expected = [
            '1. ',
            ProperNouns::Literal.new('Ana', tags.map { |tag| [tag, 'Ana'] }.sort, false),
            ' é un capítulo.'
          ]
          assert_equal expected, result
        end

        it 'should detect trained proper nouns after list markers' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Xiana.'])

          # List markers like "- ", "* ", "• " are ambiguous positions
          # But trained proper nouns SHOULD be detected there
          result = trained_proper_nouns.call('- Xiana é unha lista.')
          expected = [
            '- ',
            ProperNouns::Literal.new('Xiana', tags.map { |tag| [tag, 'Xiana'] }.sort, false),
            ' é unha lista.'
          ]
          assert_equal expected, result
        end

        it 'should detect trained proper nouns after punctuation-only text' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

          # Punctuation-only preceding text is an ambiguous position
          # But trained proper nouns SHOULD be detected there
          result = trained_proper_nouns.call('...Ana é un nome.')
          expected = [
            '...',
            ProperNouns::Literal.new('Ana', tags.map { |tag| [tag, 'Ana'] }.sort, false),
            ' é un nome.'
          ]
          assert_equal expected, result
        end

        it 'should detect trained road names with uppercase and hyphen' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Vou pola AP-9.'])

          result = trained_proper_nouns.call('A AP-9 está cortada.')
          # Road names are detected as standard proper nouns (by regex)
          expected = [
            'A ',
            ProperNouns::Literal.new('AP-9', tags.map { |tag| [tag, 'AP-9'] }.sort, false),
            ' está cortada.'
          ]
          assert_equal expected, result
        end
      end

      # GROUP D: Boundary validation (substring/hyphen adjacency)
      # Use lowercase words to avoid standard proper noun detection by regex
      describe 'trained proper noun boundary validation' do
        it 'should NOT detect trained proper nouns as substring in larger words (suffix)' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

          # "Ana" should not match inside "anabel" (lowercase to avoid regex detection)
          result = trained_proper_nouns.call('Falei con anabel.')
          expected = ['Falei con anabel.']
          assert_equal expected, result, "Incorrectly detected 'Ana' inside 'anabel'"
        end

        it 'should NOT detect trained proper nouns as substring in larger words (prefix)' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Sol.'])

          # "Sol" should not match inside "soledad" (lowercase to avoid regex detection)
          result = trained_proper_nouns.call('Falei con soledad.')
          expected = ['Falei con soledad.']
          assert_equal expected, result, "Incorrectly detected 'Sol' inside 'soledad'"
        end

        it 'should NOT detect trained proper nouns adjacent to hyphen (composite words)' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

          # "Ana" should not match in "casa-Ana" (hyphen-separated)
          result = trained_proper_nouns.call('Falei da casa-Ana.')
          expected = ['Falei da casa-Ana.']
          assert_equal expected, result, "Incorrectly detected 'Ana' adjacent to hyphen in 'casa-Ana'"
        end

        it 'should NOT detect trained proper nouns with letter immediately before' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Hermenegildo.'])

          # "Hermenegildo" should not match in "xhermenegildo" (lowercase)
          result = trained_proper_nouns.call('Falei con xhermenegildo.')
          expected = ['Falei con xhermenegildo.']
          assert_equal expected, result, "Incorrectly detected 'Hermenegildo' with letter immediately before"
        end

        it 'should NOT detect trained proper nouns with letter immediately after' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

          # "Ana" should not match in "anax" (lowercase)
          result = trained_proper_nouns.call('Falei con anax.')
          expected = ['Falei con anax.']
          assert_equal expected, result, "Incorrectly detected 'Ana' with letter immediately after"
        end

        it 'should NOT detect trained proper nouns with digit immediately before' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

          # "Ana" should not match in "3ana" (lowercase)
          result = trained_proper_nouns.call('Falei con 3ana.')
          expected = ['Falei con 3ana.']
          assert_equal expected, result, "Incorrectly detected 'Ana' with digit immediately before"
        end

        it 'should NOT detect trained proper nouns with digit immediately after' do
          no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
          trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

          # "Ana" should not match in "ana3" (lowercase)
          result = trained_proper_nouns.call('Falei con ana3.')
          expected = ['Falei con ana3.']
          assert_equal expected, result, "Incorrectly detected 'Ana' with digit immediately after"
        end
      end
    end

    describe 'proper noun joining rules' do
      it 'should NOT join first word with proper noun if first word contains punctuation' do
        no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

        # "Ola," (with comma) should NOT be joined with "Ana"
        result = trained_proper_nouns.call('Ola, Ana.')
        expected = [
          'Ola, ',
          ProperNouns::Literal.new('Ana', tags.map { |tag| [tag, 'Ana'] }.sort, false),
          '.'
        ]
        assert_equal expected, result, "Incorrectly joined 'Ola,' with 'Ana' despite punctuation"
      end

      it 'should NOT join first word with proper noun if first word contains symbols' do
        no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

        # Test with various symbols
        ['#Hashtag', '@Usuario', '$Dolar', '%Porcentaxe'].each do |prefix|
          text = "#{prefix} Ana."
          result = trained_proper_nouns.call(text)
          expected = [
            "#{prefix} ",
            ProperNouns::Literal.new('Ana', tags.map { |tag| [tag, 'Ana'] }.sort, false),
            '.'
          ]
          assert_equal expected, result, "Incorrectly joined '#{prefix}' with 'Ana' despite symbol"
        end
      end

      it 'should join first word with proper noun if first word is unknown without punctuation' do
        no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son García.'])

        # "Zulmira" (unknown word without punctuation) SHOULD be joined with "García"
        result = trained_proper_nouns.call('Zulmira García.')
        expected = [
          ProperNouns::Literal.new('Zulmira García', tags.map { |tag| [tag, 'Zulmira García'] }.sort, false),
          '.'
        ]
        assert_equal expected, result, "Failed to join unknown first word 'Zulmira' with detected 'García'"
      end

      it 'should NOT join first word with proper noun if first word is known in lexicon' do
        no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son García.'])

        # "Casa" (known word in lexicon) should NOT be joined with "García"
        result = trained_proper_nouns.call('Casa García.')
        expected = [
          'Casa ',
          ProperNouns::Literal.new('García', tags.map { |tag| [tag, 'García'] }.sort, false),
          '.'
        ]
        assert_equal expected, result, "Incorrectly joined known word 'Casa' with 'García'"
      end

      it 'should NOT join first word with proper noun if first word contains colon' do
        no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

        # "Nota:" (with colon) should NOT be joined with "Ana"
        result = trained_proper_nouns.call('Nota: Ana.')
        expected = [
          'Nota: ',
          ProperNouns::Literal.new('Ana', tags.map { |tag| [tag, 'Ana'] }.sort, false),
          '.'
        ]
        assert_equal expected, result, "Incorrectly joined 'Nota:' with 'Ana' despite colon"
      end

      it 'should NOT join first word with proper noun if first word contains semicolon' do
        no_train_proper_nouns = ProperNouns.new(main_lexicon, [], [], joiners, tags)
        trained_proper_nouns = no_train_proper_nouns.with_trained(['Eu son Ana.'])

        # "Ola;" (with semicolon) should NOT be joined with "Ana"
        result = trained_proper_nouns.call('Ola; Ana.')
        expected = [
          'Ola; ',
          ProperNouns::Literal.new('Ana', tags.map { |tag| [tag, 'Ana'] }.sort, false),
          '.'
        ]
        assert_equal expected, result, "Incorrectly joined 'Ola;' with 'Ana' despite semicolon"
      end
    end
  end
end
