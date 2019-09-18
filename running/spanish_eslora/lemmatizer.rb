# -*- coding: utf-8 -*-

module LemmatizerSpanishEslora
  def lemmatize(word, tag, lemma)
    if !lemma and tag !~ /^NP/ and word!=/áéíóú/
      STDERR.puts "(lemmatize) word:#{word}, tag:#{tag}, lemma:#{lemma}"
      # Diminutives
      if word =~ /ito$/
        new_lemma = word.delete_suffix("ito") << ("o")
      elsif word =~ /ita$/
        new_lemma = word.delete_suffix("ita") << ("o")
      elsif word =~ /itos$/
        new_lemma = word.delete_suffix("itos") << ("o")
      elsif word =~ /itas$/
        new_lemma = word.delete_suffix("itas") << ("o")
      end
      if new_lemma
        infos = @dw.get_emissions_info(new_lemma, ["NCMS","AMS"])
        # STDERR.puts "new_lemma: #{new_lemma}, infos:#{infos}"
        return new_lemma unless infos.empty?
      end
    end
    return lemma ? lemma : "*"
  end
end
