require_relative 'test_helper'
require_relative 'support/corga_document'
require_relative 'support/corga_client_assertions'

describe 'CORGA — client expectations' do
  include CorgaDocument::ClientAssertions

  CorgaDocument.active_cases.group_by { |example| example.fetch('section') }.each do |section, cases|
    describe section do
      cases.group_by { |example| example.fetch('subsection') }.each do |subsection, examples|
        describe subsection do
          examples.each do |example|
            it "#{example.fetch('id')} — #{example.fetch('focus', 'unavailable source input')}" do
              tokens = example['input'] ? CorgaDocument.output(example) : []
              assert_client_expectation(example, tokens)
            end
          end
        end
      end
    end
  end
end

describe 'Galician conditional initial articles' do
  it 'joins O to an already detected proper noun in the supplied sentence' do
    input = 'adscrito a Asociación Cultural "O Galo" de Santiago de Compostela.'
    tokens = CorgaDocument.output({ 'profile' => 'galician_xiada', 'input' => input })

    assert_equal [
      'adscrito', 'a', 'Asociación Cultural', '"', 'O Galo', '"',
      'de', 'Santiago de Compostela', '.'
    ], tokens.map { |token| token['token'] }

    entity = tokens.find { |token| token['token'] == 'O Galo' }
    refute_nil entity
    assert_match(/\ASp/, entity['tag'])
    assert_equal 'O Galo', entity['lemma']
  end
end

Minitest.after_run { CorgaDocument.close }
