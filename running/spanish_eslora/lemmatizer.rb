# -*- coding: utf-8 -*-

module LemmatizerSpanishEslora
  def lemmatize(word, tag, lemma)
    # ito/ita/itos/itas suffix treatment
    if !lemma and tag !~ /^NP/ and word!=/áéíóú/
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
        infos = @dw.get_emissions_info(new_lemma, ["NCMS","AMS","VPMS","PQMS"])
        # STDERR.puts "new_lemma: #{new_lemma}, infos:#{infos}"
        return new_lemma unless infos.empty?
      end
    end
    # super prefix treatment
    if !lemma
      if word =~ /^super/
        new_lemma = word.delete_prefix("super")
        infos = @dw.get_emissions_info(new_lemma, nil)
        return new_lemma unless infos.empty?
      end
    end
    #ísimo/ísima/ísimos/ísimas treatment
    rule_exceptions = ["tardísimo", "topísimo"]
    if !lemma
      if word =~ /ísimo$/
        if rule_exceptions.include?(word)
          new_lemma = word.delete_suffix("ísimo") << ("e")
        else
          new_lemma = word.delete_suffix("ísimo") << ("o")
        end
      elsif word =~ /ísima$/
        if rule_exceptions.include?(word)
          new_lemma = word.delete_suffix("ísima") << ("e")
        else
          new_lemma = word.delete_suffix("ísima") << ("o")
        end
      elsif word =~ /ísimos$/
        if rule_exceptions.include?(word)
          new_lemma = word.delete_suffix("ísimos") << ("e")
        else
          new_lemma = word.delete_suffix("ísimos") << ("o")
        end
      elsif word =~ /ísimas$/
        if rule_exceptions.include?(word)
          new_lemma = word.delete_suffix("ísimos") << ("e")
        else
          new_lemma = word.delete_suffix("ísimos") << ("o")
        end
      end
      if new_lemma
        infos = @dw.get_emissions_info(new_lemma, ["NCMS","AMS","W"])
        STDERR.puts "new_lemma: #{new_lemma}, infos:#{infos}"
        return new_lemma unless infos.empty?
      end
    end
    return lemma ? lemma : "*"
  end
end
