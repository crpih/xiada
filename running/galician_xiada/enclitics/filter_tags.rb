module GalicianXiada
  module Enclitics
    class FilterTags
      # Function which filters the tags of an enclitic within a decomposition sequence
      # It return an array of three elements:
      # 1) The form of the enclitic, which could be changed.
      # 2) A string with space separated valid enclitic tags
      # 3) A string with space separated corresponding lemmas
      def call(verb_part, enclitics, enclitic, enclitic_tags, enclitic_lemmas, index)
        # RULE: 1
        # RULE: 1 DEPTH:1 CONDITION:1
        # Not OR nor AND expressions
        if index < enclitics.length - 1 and enclitic =~ /^lle$/
          # RULE: 1 DEPTH:2 CONDITION:1
          if index < enclitics.length - 1 and enclitics[index + 1] =~ /^lo$|^la$|^los$|^las$|^-lo$|^-la$|^-los$|^-las$/
            enclitic_tags_array = enclitic_tags.split(/ /)
            enclitic_lemmas_array = enclitic_lemmas.split(/ /)
            new_enclitic_tags_array = Array.new
            new_enclitic_lemmas_array = Array.new
            enclitic_tags_array.each_index do |index_aux|
              enclitic_tag = enclitic_tags_array[index_aux]
              enclitic_lemma = enclitic_lemmas_array[index_aux]
              if enclitic_tag =~ /Rad3as|Rad3ms|Rad3fs/
                # tag removing
              else
                new_enclitic_tags_array << enclitic_tag
                new_enclitic_lemmas_array << enclitic_lemma
              end
            end
            if new_enclitic_tags_array.empty?
              enclitic_lemmas = nil
              enclitic_tags = nil
            else
              enclitic_tags = new_enclitic_tags_array.join(" ")
              enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
            end
            enclitic = "lles"
          end
        end
        # RULE: 2
        # RULE: 2 DEPTH:1 CONDITION:1
        # Not OR nor AND expressions
        if index < enclitics.length - 1 and enclitic =~ /^lle$/
          # RULE: 2 DEPTH:2 CONDITION:1
          if index < enclitics.length - 1 and enclitics[index + 1] !~ /^lo$/ and enclitics[index + 1] !~ /^la$/ and enclitics[index + 1] !~ /^los$/ and enclitics[index + 1] !~ /^las$/ and enclitics[index + 1] !~ /^-lo$/ and enclitics[index + 1] !~ /^-la$/ and enclitics[index + 1] !~ /^-los$/ and enclitics[index + 1] !~ /^-las$/
            enclitic_tags_array = enclitic_tags.split(/ /)
            enclitic_lemmas_array = enclitic_lemmas.split(/ /)
            new_enclitic_tags_array = Array.new
            new_enclitic_lemmas_array = Array.new
            enclitic_tags_array.each_index do |index_aux|
              enclitic_tag = enclitic_tags_array[index_aux]
              enclitic_lemma = enclitic_lemmas_array[index_aux]
              if enclitic_tag =~ /Rad3ap|Rad3mp|Rad3fp/
                # tag removing
              else
                new_enclitic_tags_array << enclitic_tag
                new_enclitic_lemmas_array << enclitic_lemma
              end
            end
            if new_enclitic_tags_array.empty?
              enclitic_lemmas = nil
              enclitic_tags = nil
            else
              enclitic_tags = new_enclitic_tags_array.join(" ")
              enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
            end
          end
        end
        # RULE: 3
        # RULE: 3 DEPTH:1 CONDITION:1
        # Not OR nor AND expressions
        if index == enclitics.length - 1 and (enclitic =~ /^lle$/) and (index == enclitics.length - 1)
          enclitic_tags_array = enclitic_tags.split(/ /)
          enclitic_lemmas_array = enclitic_lemmas.split(/ /)
          new_enclitic_tags_array = Array.new
          new_enclitic_lemmas_array = Array.new
          enclitic_tags_array.each_index do |index_aux|
            enclitic_tag = enclitic_tags_array[index_aux]
            enclitic_lemma = enclitic_lemmas_array[index_aux]
            if enclitic_tag =~ /Rad3ap|Rad3mp|Rad3fp/
              # tag removing
            else
              new_enclitic_tags_array << enclitic_tag
              new_enclitic_lemmas_array << enclitic_lemma
            end
          end
          if new_enclitic_tags_array.empty?
            enclitic_lemmas = nil
            enclitic_tags = nil
          else
            enclitic_tags = new_enclitic_tags_array.join(" ")
            enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
          end
        end
        # RULE: 4
        # RULE: 4 DEPTH:1 CONDITION:1
        # Not OR nor AND expressions
        if index < enclitics.length - 1 and enclitic =~ /^nos$/
          enclitic_tags_array = enclitic_tags.split(/ /)
          enclitic_lemmas_array = enclitic_lemmas.split(/ /)
          new_enclitic_tags_array = Array.new
          new_enclitic_lemmas_array = Array.new
          enclitic_tags_array.each_index do |index_aux|
            enclitic_tag = enclitic_tags_array[index_aux]
            enclitic_lemma = enclitic_lemmas_array[index_aux]
            if enclitic_tag =~ /Raa3mp/
              # tag removing
            else
              new_enclitic_tags_array << enclitic_tag
              new_enclitic_lemmas_array << enclitic_lemma
            end
          end
          if new_enclitic_tags_array.empty?
            enclitic_lemmas = nil
            enclitic_tags = nil
          else
            enclitic_tags = new_enclitic_tags_array.join(" ")
            enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
          end
        end
        # RULE: 5
        # RULE: 5 DEPTH:1 CONDITION:1
        # Not OR nor AND expressions
        if index < enclitics.length - 1 and enclitic =~ /^no$/
          enclitic_tags_array = enclitic_tags.split(/ /)
          enclitic_lemmas_array = enclitic_lemmas.split(/ /)
          new_enclitic_tags_array = Array.new
          new_enclitic_lemmas_array = Array.new
          enclitic_tags_array.each_index do |index_aux|
            enclitic_tag = enclitic_tags_array[index_aux]
            enclitic_lemma = enclitic_lemmas_array[index_aux]
            if enclitic_tag =~ /Raa3ms/
              # tag removing
            else
              new_enclitic_tags_array << enclitic_tag
              new_enclitic_lemmas_array << enclitic_lemma
            end
          end
          if new_enclitic_tags_array.empty?
            enclitic_lemmas = nil
            enclitic_tags = nil
          else
            enclitic_tags = new_enclitic_tags_array.join(" ")
            enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
          end
        end
        # RULE: 6
        # RULE: 6 DEPTH:1 CONDITION:1
        # Not OR nor AND expressions
        if index < enclitics.length - 1 and enclitic =~ /^no$/
          # RULE: 6 DEPTH:2 CONDITION:1
          if index < enclitics.length - 1 and enclitics[index + 1] =~ /^lo$|^la$|^los$|^las$|^-lo$|^-la$|^-los$|^-las$/
            enclitic_tags_array = enclitic_tags.split(/ /)
            enclitic_lemmas_array = enclitic_lemmas.split(/ /)
            new_enclitic_tags_array = Array.new
            new_enclitic_lemmas_array = Array.new
            enclitic_tags_array.each_index do |index_aux|
              enclitic_tag = enclitic_tags_array[index_aux]
              enclitic_lemma = enclitic_lemmas_array[index_aux]
              if enclitic_tag =~ /Raa1ap|Raa1fp|Raa1mp/
                # tag removing
              else
                new_enclitic_tags_array << enclitic_tag
                new_enclitic_lemmas_array << enclitic_lemma
              end
            end
            if new_enclitic_tags_array.empty?
              enclitic_lemmas = nil
              enclitic_tags = nil
            else
              enclitic_tags = new_enclitic_tags_array.join(" ")
              enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
            end
            enclitic = "nos"
          end
        end
        # RULE: 7
        # RULE: 7 DEPTH:1 CONDITION:1
        # Not OR nor AND expressions
        if index < enclitics.length - 1 and enclitic =~ /^vo$/
          # RULE: 7 DEPTH:2 CONDITION:1
          if index < enclitics.length - 1 and enclitics[index + 1] =~ /^lo$|^la$|^los$|^las$|^-lo$|^-la$|^-los$|^-las$/
            enclitic = "vos"
          end
        end
        # RULE: 8
        # RULE: 8 DEPTH:1 CONDITION:1
        # Not OR nor AND expressions
        if index == enclitics.length - 1 and (enclitic =~ /^no$/) and (index == enclitics.length - 1)
          enclitic_tags_array = enclitic_tags.split(/ /)
          enclitic_lemmas_array = enclitic_lemmas.split(/ /)
          new_enclitic_tags_array = Array.new
          new_enclitic_lemmas_array = Array.new
          enclitic_tags_array.each_index do |index_aux|
            enclitic_tag = enclitic_tags_array[index_aux]
            enclitic_lemma = enclitic_lemmas_array[index_aux]
            if enclitic_tag =~ /Raa1ap|Rad1ap|Raa1mp|Raa1fp|Rad1mp|Rad1fp/
              # tag removing
            else
              new_enclitic_tags_array << enclitic_tag
              new_enclitic_lemmas_array << enclitic_lemma
            end
          end
          if new_enclitic_tags_array.empty?
            enclitic_lemmas = nil
            enclitic_tags = nil
          else
            enclitic_tags = new_enclitic_tags_array.join(" ")
            enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
          end
        end
        # RULE: 9
        # RULE: 9 DEPTH:1 CONDITION:1
        # Not OR nor AND expressions
        if index == enclitics.length - 1 and (enclitic =~ /^nos$/) and (index == enclitics.length - 1)
          # RULE: 9 DEPTH:2 CONDITION:1
          if verb_part !~ /ei$/ and verb_part !~ /éi$/ and verb_part !~ /eu$/ and verb_part !~ /éu$/ and verb_part !~ /ou$/ and verb_part !~ /óu$/ and verb_part !~ /iu$/ and verb_part !~ /íu$/ and verb_part !~ /ai$/ and verb_part !~ /ái$/
            enclitic_tags_array = enclitic_tags.split(/ /)
            enclitic_lemmas_array = enclitic_lemmas.split(/ /)
            new_enclitic_tags_array = Array.new
            new_enclitic_lemmas_array = Array.new
            enclitic_tags_array.each_index do |index_aux|
              enclitic_tag = enclitic_tags_array[index_aux]
              enclitic_lemma = enclitic_lemmas_array[index_aux]
              if enclitic_tag =~ /Raa3mp/
                # tag removing
              else
                new_enclitic_tags_array << enclitic_tag
                new_enclitic_lemmas_array << enclitic_lemma
              end
            end
            if new_enclitic_tags_array.empty?
              enclitic_lemmas = nil
              enclitic_tags = nil
            else
              enclitic_tags = new_enclitic_tags_array.join(" ")
              enclitic_lemmas = new_enclitic_lemmas_array.join(" ")
            end
          end
        end
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
