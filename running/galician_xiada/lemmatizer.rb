# -*- coding: utf-8 -*-

module LemmatizerGalicianXiada

  def lemmatize(word, tag, lemma)
    # mente suffix treatment
    if !lemma and word =~ /mente$/
      return word
    end
  end
end
