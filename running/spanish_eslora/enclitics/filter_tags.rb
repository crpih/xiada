module SpanishEslora
  module Enclitics
    class FilterTags
      # Function which filters the tags of an enclitic within a decomposition sequence
      # It return an array of three elements:
      # 1) The form of the enclitic, which could be changed.
      # 2) A string with space separated valid enclitic tags
      # 3) A string with space separated corresponding lemmas
      def call(verb_part, enclitics, enclitic, enclitic_tags, enclitic_lemmas, index)
        if enclitic_tags == nil or enclitic_tags.empty?
          result = [nil, nil]
        else
          result = [enclitic, enclitic_tags, enclitic_lemmas]
        end
        return result
      end
    end
  end
end
