require_relative 'lemmas/lemmatizer_corga'

module LemmatizerGalicianXiadaRefactor
  include LemmatizerGalicianXiada

  # Alias included method to be able to call it after overwriting it
  alias_method :fallback_lemmatize, :lemmatize

  def lemmatize(word, _tags)
    result = new_lemmatizer.call(word)
    return result.map { |r| [r.tag, r.lemma, r.hyperlemma, r.log_b] } if result&.any?

    []
    # fallback_lemmatize(word, nil)
  end

  private

  def new_lemmatizer
    @lemmatizer ||= Lemmas::LemmatizerCorga.new(@dw)
  end
end
