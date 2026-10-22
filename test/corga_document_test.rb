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

Minitest.after_run { CorgaDocument.close }
