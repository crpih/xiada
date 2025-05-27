module SpanishEslora
  module Enclitics
    class ValidateDecomposition
      # Function which determines if a verb_part/enclitic_part decomposition is valid
      # It returns an array of four elements:
      # 1) Boolean which indicates if it is a valid verb_part/enclitic_part decomposition
      # 2) verb_part
      # 3) enclitic_part
      # 4) A string with space separated valid verb tags
      def call(verb_part, verb_tags, enclitic_part, &syllable_count)
        # validate_decomposition verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        check_default = true
        if verb_tags == nil or verb_tags.empty?
          result = [false, nil, nil, nil]
          return result
        else
          result = [true, verb_part, enclitic_part, verb_tags]
          return result
        end
      end
    end
  end
end
