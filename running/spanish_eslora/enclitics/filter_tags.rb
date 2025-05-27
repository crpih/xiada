module SpanishEslora
  module Enclitics
    class FilterTags
      def call(verb_part, enclitics, enclitic, enclitic_tags, enclitic_lemmas, index)
        if enclitic_tags == nil or enclitic_tags.empty?
          result = [ nil, nil ]
        else
          result = [ enclitic, enclitic_tags, enclitic_lemmas ]
        end
        return result
      end

    end
  end
end
