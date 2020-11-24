# -*- coding: utf-8 -*-

module LemmatizerGalicianXiada

  def lemmatize(word, tags)
    # mente suffix treatment
    return @dw.get_guesser_result("'mente'", word, ['W*']) if word =~ /mente$/

    []
  end
end
