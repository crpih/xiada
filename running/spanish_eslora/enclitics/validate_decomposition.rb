module SpanishEslora
  module Enclitics
    class ValidateDecomposition
      def call(verb_part, verb_tags, enclitic_part, &syllable_count)
        # validate_decomposition verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        check_default = true
        if verb_tags == nil or verb_tags.empty?
          result = [ false, nil, nil, nil ]
          return result
        else
          result = [ true, verb_part, enclitic_part, verb_tags ]
          return result
        end
      end

    end
  end
end
