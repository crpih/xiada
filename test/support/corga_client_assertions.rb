# Client acceptance rules. Recorded model output is never an expected value.
module CorgaDocument
  module ClientAssertions
    def assert_client_expectation(example, tokens)
      expected = example.fetch('expectation')
      case expected.fetch('type')
      when 'incomplete'
        category = example['input'] ? 'CLIENT EXPECTATION UNDEFINED' : 'CLIENT INPUT UNAVAILABLE'
        flunk "#{category} [#{example.fetch('id')}]: #{expected.fetch('reason')}\nActual: #{client_focus_output(example, tokens)}"
      when 'unit'
        start = client_target_start(example, expected.fetch('surface'))
        assert_client_unit(example, tokens, expected, start)
      when 'proper_prefix'
        start = client_target_start(example, expected.fetch('surface'))
        minimum_finish = start + expected.fetch('surface').length - 1
        focus_finish = example.fetch('input').index(example.fetch('focus')) + example.fetch('focus').length - 1
        unit = tokens.find do |token|
          token.fetch('start') == start && token.fetch('finish') >= minimum_finish &&
            token.fetch('finish') <= focus_finish && token.fetch('tag').start_with?('Sp') &&
            token.fetch('token').start_with?(expected.fetch('surface'))
        end
        assert unit, client_mismatch(example, "one proper-name unit covering at least #{expected.fetch('surface').inspect}", tokens)
        overlaps = tokens.select { |token| token.fetch('start') <= unit.fetch('finish') && token.fetch('finish') >= start }
        assert_equal [unit], overlaps, client_mismatch(example, 'no independent fragments inside the proper unit', tokens)
        if expected.key?('forbidden_lemma')
          refute_equal expected.fetch('forbidden_lemma'), unit.fetch('lemma'), client_mismatch(example, 'no common-noun lemma', tokens)
        end
      when 'sequence'
        items = expected.fetch('items')
        cursor = client_target_start(example, items.first.fetch('surface'))
        items.each do |item|
          cursor += example.fetch('input')[cursor..].match(/\A\s*/)[0].length
          assert_equal item.fetch('surface'), example.fetch('input')[cursor, item.fetch('surface').length], "Invalid source sequence for #{example.fetch('id')}"
          assert_client_unit(example, tokens, item, cursor)
          cursor += item.fetch('surface').length
        end
        if expected.key?('preserve_after')
          suffix = expected.fetch('preserve_after')
          assert_equal suffix, example.fetch('input')[cursor, suffix.length], "Invalid source suffix for #{example.fetch('id')}"
          tail = tokens.select { |token| token.fetch('start') >= cursor && token.fetch('finish') < cursor + suffix.length }
          assert_equal suffix, tail.map { |token| token.fetch('token') }.join, client_mismatch(example, 'preserved footnote text and punctuation', tokens)
        end
      else
        flunk "Invalid runnable client contract for #{example.fetch('id')}: #{expected.fetch('type')}"
      end
      if expected['preserve_context']
        example.fetch('input').each_char.with_index do |character, position|
          next if character.match?(/\s/) || character == '_' # Formatting wrapper, not lexical content.

          assert tokens.any? { |token| token.fetch('start') <= position && token.fetch('finish') >= position },
                 client_mismatch(example, "preserved source context character at #{position}", tokens)
        end
      end
    end

    private

    def client_target_start(example, surface)
      input = example.fetch('input')
      focus_start = input.index(example.fetch('focus'))
      refute_nil focus_start, "Focus is absent from input for #{example.fetch('id')}"
      start = input.index(surface, focus_start)
      assert start && start + surface.length <= focus_start + example.fetch('focus').length,
             "Expected target is absent from focus for #{example.fetch('id')}: #{surface.inspect}"
      start
    end

    def assert_client_unit(example, tokens, expected, start)
      finish = start + expected.fetch('surface').length - 1
      unit = tokens.find { |token| token.fetch('start') == start && token.fetch('finish') == finish }
      assert unit, client_mismatch(example, "one complete unit #{expected.fetch('surface').inspect}", tokens)
      overlaps = tokens.select { |token| token.fetch('start') <= finish && token.fetch('finish') >= start }
      assert_equal [unit], overlaps, client_mismatch(example, 'no overlapping fragments of the expected unit', tokens)
      form = unit.fetch('token')
      surface = expected.fetch('surface')
      form, surface = form.downcase, surface.downcase if expected['ignore_case']
      assert_equal surface, form, client_mismatch(example, 'the expected surface form', tokens)
      if expected.key?('tag')
        assert_equal expected.fetch('tag'), unit.fetch('tag'), client_mismatch(example, "tag #{expected.fetch('tag')}", tokens)
      end
      if expected.key?('tag_prefix')
        assert unit.fetch('tag').start_with?(expected.fetch('tag_prefix')), client_mismatch(example, "tag prefix #{expected.fetch('tag_prefix')}", tokens)
      end
      if expected.key?('forbidden_tag_prefix')
        refute unit.fetch('tag').start_with?(expected.fetch('forbidden_tag_prefix')), client_mismatch(example, "not a #{expected.fetch('forbidden_tag_prefix')} peripheral analysis", tokens)
      end
      if expected.key?('lemma')
        assert_equal expected.fetch('lemma'), unit.fetch('lemma'), client_mismatch(example, "lemma #{expected.fetch('lemma').inspect}", tokens)
      end
    end

    def client_focus_output(example, tokens)
      return '(no exact source input)' unless example['input']

      start = example.fetch('input').index(example.fetch('focus'))
      return '(focus is absent)' unless start

      finish = start + example.fetch('focus').length - 1
      tokens.select { |token| token.fetch('start') <= finish && token.fetch('finish') >= start }
            .map { |token| "#{token.fetch('token')}/#{token.fetch('tag')} → #{token.fetch('lemma')}" }.join('; ')
    end

    def client_mismatch(example, requirement, tokens)
      "CLIENT MISMATCH [#{example.fetch('id')}]: expected #{requirement}.\n" \
        "Client: #{example.fetch('expected_description')}\nActual: #{client_focus_output(example, tokens)}"
    end
  end
end
