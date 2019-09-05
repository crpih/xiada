# -*- coding: utf-8 -*-

module LemmatizerSpanishEslora
  def lemmatize(word, tag, lemma)
    # STDERR.puts "(lemmatize) word:#{word}, tag:#{tag}, lemma:#{lemma}"
    if !lemma or tag =~ /^NP/ 
      # Diminutives
      if word =~ /ito$/
        new_lemma = word.delete_suffix("ito") << ("o")
        infos = @dw.get_emissions_info(word, ["%MS"])
        return new_lemma if infos
      elsif word =~ /ita$/
        new_lemma = word.delete_suffix("ita") << ("a")
        infos = @dw.get_emissions_info(word, ["%FS"])
        return new_lemma if infos
      elsif word =~ /itos$/
        new_lemma = word.delete_suffix("itos") << ("os")
        infos = @dw.get_emissions_info(word, ["%MP"])
        return new_lemma if infos
      elsif word =~ /itas$/
        new_lemma = word.delete_suffix("itas") << ("as")
        infos = @dw.get_emissions_info(word, ["%FP"])
        return new_lemma if infos
      end
    end
    return lemma ? lemma : "*"
  end
end
