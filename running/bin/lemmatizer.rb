# -*- coding: utf-8 -*-

require_relative "../spanish_eslora/lemmatizer.rb"

class Lemmatizer
  def initialize(dw)
    @dw = dw
  end

  def lemmatize(word, tag, lemma)
    return lemma ? lemma : "*"
  end
end
