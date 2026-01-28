module GalicianXiada
  module Enclitics
    class ValidateDecomposition
      def call(verb_part, verb_tags, enclitic_part, &syllable_count)
        # validate_decomposition verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        check_default = true
        # before rule 1 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 1
        # RULE: 1 DEPTH:1 CONDITION:1
        if verb_part !~ /á/ and verb_part !~ /é/ and verb_part !~ /í/ and verb_part !~ /ó/ and verb_part !~ /ú/
          # RULE: 1 DEPTH:2 CONDITION:1
          if syllable_count.(enclitic_part) > 1
            result = [ false, nil, nil, nil ]
            return result
          end
        end
        # before rule 2 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 2
        # RULE: 2 DEPTH:1 CONDITION:1
        if verb_part =~ /ói$/
          # RULE: 2 DEPTH:2 CONDITION:1
          if verb_tags =~ /Vei30s/
            # RULE: 2 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 3 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 3
        # RULE: 3 DEPTH:1 CONDITION:1
        if verb_part =~ /rás$/
          # RULE: 3 DEPTH:2 CONDITION:1
          if verb_tags =~ /Vfi20s/
            # RULE: 3 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 4 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 4
        # RULE: 4 DEPTH:1 CONDITION:1
        if verb_part =~ /rá$/
          # RULE: 4 DEPTH:2 CONDITION:1
          if verb_tags =~ /^Vfi30s$/
            # RULE: 4 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 5 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 5
        # RULE: 5 DEPTH:1 CONDITION:1
        if verb_part =~ /rán$/
          # RULE: 5 DEPTH:2 CONDITION:1
          if verb_tags =~ /Vfi30p/
            # RULE: 5 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 6 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 6
        # RULE: 6 DEPTH:1 CONDITION:1
        if verb_part =~ /ár$/
          # RULE: 6 DEPTH:2 CONDITION:1
          if verb_tags =~ /Vfs10s|Vfs30s|Vfsa0s|V0f10s|V0f30s|V0f000/
            # RULE: 6 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 7 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 7
        # RULE: 7 DEPTH:1 CONDITION:1
        if verb_part =~ /ín$/
          # RULE: 7 DEPTH:2 CONDITION:1
          if verb_part !~ /^abstraín$/ and verb_part !~ /^acaín$/ and verb_part !~ /^atraín$/ and verb_part !~ /^caín$/ and verb_part !~ /^choín$/ and verb_part !~ /^condoín$/ and verb_part !~ /^contraín$/ and verb_part !~ /^corroín$/ and verb_part !~ /^debaín$/ and verb_part !~ /^decaín$/ and verb_part !~ /^degraín$/ and verb_part !~ /^deschoín$/ and verb_part !~ /^descontraín$/ and verb_part !~ /^detraín$/ and verb_part !~ /^distraín$/ and verb_part !~ /^doín$/ and verb_part !~ /^esvaín$/ and verb_part !~ /^extraín$/ and verb_part !~ /^maltraín$/ and verb_part !~ /^moín$/ and verb_part !~ /^proín$/ and verb_part !~ /^raín$/ and verb_part !~ /^recaín$/ and verb_part !~ /^remoín$/ and verb_part !~ /^retraín$/ and verb_part !~ /^retrotraín$/ and verb_part !~ /^roín$/ and verb_part !~ /^substraín$/ and verb_part !~ /^subtraín$/ and verb_part !~ /^sustraín$/
            # RULE: 7 DEPTH:3 CONDITION:1
            if verb_part !~ /^desoín$/ and verb_part !~ /^entreoín$/ and verb_part !~ /^esvaín$/ and verb_part !~ /^oín$/ and verb_part !~ /^saín$/ and verb_part !~ /^sobresaín$/
              # RULE: 7 DEPTH:4 CONDITION:1
              if verb_part !~ /^abluín$/ and verb_part !~ /^afluín$/ and verb_part !~ /^argüín$/ and verb_part !~ /^atribuín$/ and verb_part !~ /^atuín$/ and verb_part !~ /^concluín$/ and verb_part !~ /^confluín$/ and verb_part !~ /^constituín$/ and verb_part !~ /^construín$/ and verb_part !~ /^contribuín$/ and verb_part !~ /^derruín$/ and verb_part !~ /^desatuín$/ and verb_part !~ /^desobstruín$/ and verb_part !~ /^desposuín$/ and verb_part !~ /^destituín$/ and verb_part !~ /^destruín$/ and verb_part !~ /^difluín$/ and verb_part !~ /^diluín$/ and verb_part !~ /^diminuín$/ and verb_part !~ /^disminuín$/ and verb_part !~ /^distribuín$/ and verb_part !~ /^efluín$/ and verb_part !~ /^esluín$/ and verb_part !~ /^estatuín$/ and verb_part !~ /^excluín$/ and verb_part !~ /^extruín$/ and verb_part !~ /^fluín$/ and verb_part !~ /^imbuín$/ and verb_part !~ /^incluín$/ and verb_part !~ /^influín$/ and verb_part !~ /^inmiscuín$/ and verb_part !~ /^instituín$/ and verb_part !~ /^instruín$/ and verb_part !~ /^intuín$/ and verb_part !~ /^luín$/ and verb_part !~ /^obstruín$/ and verb_part !~ /^ocluín$/ and verb_part !~ /^posuín$/ and verb_part !~ /^protuín$/ and verb_part !~ /^prostituín$/ and verb_part !~ /^puín$/ and verb_part !~ /^recluín$/ and verb_part !~ /^reconstituín$/ and verb_part !~ /^reconstruín$/ and verb_part !~ /^redistribuín$/ and verb_part !~ /^refluín$/ and verb_part !~ /^restituín$/ and verb_part !~ /^redargüín$/ and verb_part !~ /^retribuín$/ and verb_part !~ /^substituín$/ and verb_part !~ /^sustituín$/
                # RULE: 7 DEPTH:5 CONDITION:1
                if verb_tags =~ /Vei10s/
                  # RULE: 7 DEPTH:6 CONDITION:1
                  if syllable_count.(enclitic_part) == 1
                    result = [ false, nil, nil, nil ]
                    return result
                  end
                end
              end
            end
          end
        end
        # before rule 8 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 8
        # RULE: 8 DEPTH:1 CONDITION:1
        if verb_part =~ /ér$/
          # RULE: 8 DEPTH:2 CONDITION:1
          if verb_tags =~ /Vfs10s|Vfs30s|Vfsa0s|V0f10s|V0f30s|V0f000/
            # RULE: 8 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 9 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 9
        # RULE: 9 DEPTH:1 CONDITION:1
        if verb_part =~ /ír$/
          # RULE: 9 DEPTH:2 CONDITION:1
          if verb_part !~ /^desoír$/ and verb_part !~ /^entreoír$/ and verb_part !~ /^esvaír$/ and verb_part !~ /^oír$/ and verb_part !~ /^saír$/ and verb_part !~ /^sobresaír$/
            # RULE: 9 DEPTH:3 CONDITION:1
            if verb_part !~ /^abluír$/ and verb_part !~ /^afluír$/ and verb_part !~ /^argüír$/ and verb_part !~ /^atribuír$/ and verb_part !~ /^atuír$/ and verb_part !~ /^concluír$/ and verb_part !~ /^confluír$/ and verb_part !~ /^constituír$/ and verb_part !~ /^construír$/ and verb_part !~ /^contribuír$/ and verb_part !~ /^derruír$/ and verb_part !~ /^desatuír$/ and verb_part !~ /^desobstruír$/ and verb_part !~ /^desposuír$/ and verb_part !~ /^destituír$/ and verb_part !~ /^destruír$/ and verb_part !~ /^difluír$/ and verb_part !~ /^diluír$/ and verb_part !~ /^diminuír$/ and verb_part !~ /^disminuír$/ and verb_part !~ /^distribuír$/ and verb_part !~ /^efluír$/ and verb_part !~ /^esluír$/ and verb_part !~ /^estatuír$/ and verb_part !~ /^excluír$/ and verb_part !~ /^extruír$/ and verb_part !~ /^fluír$/ and verb_part !~ /^imbuír$/ and verb_part !~ /^incluír$/ and verb_part !~ /^influír$/ and verb_part !~ /^inmiscuír$/ and verb_part !~ /^instituír$/ and verb_part !~ /^instruír$/ and verb_part !~ /^intuír$/ and verb_part !~ /^luír$/ and verb_part !~ /^obstruír$/ and verb_part !~ /^ocluír$/ and verb_part !~ /^posuír$/ and verb_part !~ /^protuír$/ and verb_part !~ /^prostituír$/ and verb_part !~ /^puír$/ and verb_part !~ /^recluír$/ and verb_part !~ /^reconstituír$/ and verb_part !~ /^reconstruír$/ and verb_part !~ /^redargüír$/ and verb_part !~ /^redistribuír$/ and verb_part !~ /^refluír$/ and verb_part !~ /^restituír$/ and verb_part !~ /^retribuír$/ and verb_part !~ /^substituír$/ and verb_part !~ /^sustituír$/
              # RULE: 9 DEPTH:4 CONDITION:1
              if verb_tags =~ /Vfs10s|Vfs30s|Vfsa0s|V0f10s|V0f30s|V0f000/
                # RULE: 9 DEPTH:5 CONDITION:1
                if syllable_count.(enclitic_part) == 1
                  result = [ false, nil, nil, nil ]
                  return result
                end
              end
            end
          end
        end
        # before rule 10 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 10
        # RULE: 10 DEPTH:1 CONDITION:1
        if verb_part =~ /én$/
          # RULE: 10 DEPTH:2 CONDITION:1
          if verb_part !~ /^vén$/
            # RULE: 10 DEPTH:3 CONDITION:1
            if verb_tags =~ /V0m20s|Vpi30s/
              # RULE: 10 DEPTH:4 CONDITION:1
              if syllable_count.(enclitic_part) == 1
                result = [ false, nil, nil, nil ]
                return result
              end
            end
          end
        end
        # before rule 11 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 11
        # RULE: 11 DEPTH:1 CONDITION:1
        if verb_part =~ /és$/
          # RULE: 11 DEPTH:2 CONDITION:1
          if verb_part !~ /^vés$/
            # RULE: 11 DEPTH:3 CONDITION:1
            if verb_tags =~ /Vpi20s/
              # RULE: 11 DEPTH:4 CONDITION:1
              if syllable_count.(enclitic_part) == 1
                result = [ false, nil, nil, nil ]
                return result
              end
            end
          end
        end
        # before rule 12 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 12
        # RULE: 12 DEPTH:1 CONDITION:1
        if verb_part =~ /ón$/
          # RULE: 12 DEPTH:2 CONDITION:1
          if verb_tags =~ /V0m20s|Vpi30s|Vpi30p/
            # RULE: 12 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 13 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 13
        # RULE: 13 DEPTH:1 CONDITION:1
        if verb_part =~ /ór$/
          # RULE: 13 DEPTH:2 CONDITION:1
          if verb_part !~ /^pór$/
            # RULE: 13 DEPTH:3 CONDITION:1
            if verb_tags =~ /V0f000|V0f10s|V0f30s/
              # RULE: 13 DEPTH:4 CONDITION:1
              if syllable_count.(enclitic_part) == 1
                result = [ false, nil, nil, nil ]
                return result
              end
            end
          end
        end
        # before rule 14 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 14
        # RULE: 14 DEPTH:1 CONDITION:1
        if verb_part =~ /ós$/
          # RULE: 14 DEPTH:2 CONDITION:1
          if verb_tags =~ /Vpi20s/
            # RULE: 14 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 15 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 15
        # RULE: 15 DEPTH:1 CONDITION:1
        if verb_part =~ /ís$/
          # RULE: 15 DEPTH:2 CONDITION:1
          if verb_tags =~ /Vpi20s/
            # RULE: 15 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 16 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 16
        # RULE: 16 DEPTH:1 CONDITION:1
        if verb_part =~ /i$/
          # RULE: 16 DEPTH:2 CONDITION:1
          if enclitic_part =~ /^o|^a|^os|^as/
            result = [ false, nil, nil, nil ]
            return result
          end
        end
        # before rule 17 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 17
        # RULE: 17 DEPTH:1 CONDITION:1
        if verb_part =~ /ín$/
          # RULE: 17 DEPTH:2 CONDITION:1
          if verb_tags =~ /Vpi30p/
            # RULE: 17 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 18 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 18
        # RULE: 18 DEPTH:1 CONDITION:1
        if verb_part =~ /án$/
          # RULE: 18 DEPTH:2 CONDITION:1
          if verb_tags =~ /Vpi30p/
            # RULE: 18 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 19 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 19
        # RULE: 19 DEPTH:1 CONDITION:1
        if verb_part =~ /ás$/
          # RULE: 19 DEPTH:2 CONDITION:1
          if verb_part !~ /^dás$/
            # RULE: 19 DEPTH:3 CONDITION:1
            if verb_tags =~ /Vpi20s/
              # RULE: 19 DEPTH:4 CONDITION:1
              if syllable_count.(enclitic_part) == 1
                result = [ false, nil, nil, nil ]
                return result
              end
            end
          end
        end
        # before rule 20 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 20
        # RULE: 20 DEPTH:1 CONDITION:1
        if verb_part =~ /fái$/
          # RULE: 20 DEPTH:2 CONDITION:1
          if verb_tags =~ /V0m20s|Vpi30p/
            # RULE: 20 DEPTH:3 CONDITION:1
            if syllable_count.(enclitic_part) == 1
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 21 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 21
        # RULE: 21 DEPTH:1 CONDITION:1
        if verb_part =~ /ei$|éi$|eu$|éu$|ou$|óu$|iu$|íu$|ai$|ái$|oi$|ói$/
          check_default = false
          # RULE: 21 DEPTH:2 CONDITION:1
          if enclitic_part =~ /^o|^os|^a|^as|^la|^las|^lo|^los|^-lo|^-la|^-los|^-las/
            result = [ false, nil, nil, nil ]
            return result
          end
        end
        # before rule 22 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 22
        # RULE: 22 DEPTH:1 CONDITION:1
        if verb_tags =~ /V0f10s|V0f30s|Vfs10s|Vfs30s|Vfsa0s|V0f000|..[^m]2.s|..[^m]2.p|...1.p/
          # RULE: 22 DEPTH:2 CONDITION:1
          if verb_part =~ /s$|r$/
            check_default = false
            # RULE: 22 DEPTH:3 CONDITION:1
            if enclitic_part =~ /^o|^os|^a|^as|^lo|^la|^los|^las|^-lo|^-la|^-los|^-las/
              result = [ false, nil, nil, nil ]
              return result
            end
          end
          # RULE: 22 DEPTH:2 CONDITION:2
          if verb_part =~ /s$|r$/
            check_default = false
            # RULE: 22 DEPTH:3 CONDITION:1
            if enclitic_part =~ /^no$|^na$|^nas$/
              result = [ false, nil, nil, nil ]
              return result
            end
          end
          # RULE: 22 DEPTH:2 CONDITION:3
          if verb_part =~ /s$/
            check_default = false
            # RULE: 22 DEPTH:3 CONDITION:1
            if verb_tags =~ /...1.p/
              # RULE: 22 DEPTH:4 CONDITION:1
              if enclitic_part =~ /^me|^mo|^mos|^ma|^mas|^no|^na|^nos|^nas/
                if verb_tags != nil
                  verb_tags_array = verb_tags.split(/ /)
                  new_verb_tags_array = Array.new
                  verb_tags_array.each do |verb_tag|
                    if verb_tag =~ /...1.p/
                      # tag removing
                    else
                      new_verb_tags_array << verb_tag
                    end
                  end
                  if new_verb_tags_array.empty?
                    verb_tags = nil
                  else
                    verb_tags = new_verb_tags_array.join(" ")
                  end
                end
              end
            end
          end
          # RULE: 22 DEPTH:2 CONDITION:4
          if verb_part =~ /s$|r$/
            check_default = false
            # RULE: 22 DEPTH:3 CONDITION:1
            if verb_tags =~ /...2.p/
              # RULE: 22 DEPTH:4 CONDITION:1
              if enclitic_part =~ /^te|^che|^cho|^cha|^chos|^chas/
                if verb_tags != nil
                  verb_tags_array = verb_tags.split(/ /)
                  new_verb_tags_array = Array.new
                  verb_tags_array.each do |verb_tag|
                    if verb_tag =~ /...2.p/
                      # tag removing
                    else
                      new_verb_tags_array << verb_tag
                    end
                  end
                  if new_verb_tags_array.empty?
                    verb_tags = nil
                  else
                    verb_tags = new_verb_tags_array.join(" ")
                  end
                end
              end
            end
          end
          # RULE: 22 DEPTH:2 CONDITION:5
          if verb_part !~ /s$/ and verb_part !~ /r$/
            # RULE: 22 DEPTH:3 CONDITION:1
            if enclitic_part =~ /^nos/
              check_default = false
              if verb_tags != nil
                verb_tags_array = verb_tags.split(/ /)
                new_verb_tags_array = Array.new
                verb_tags_array.each do |verb_tag|
                  if verb_tag =~ /V0f10s|V0f30s|Vfs10s|Vfs30s|Vfsa0s|V0f000|...2.s|...2.p/ and verb_tag !~ /V0m20s/ and verb_tag !~ /V0m20p/
                    # tag removing
                  else
                    new_verb_tags_array << verb_tag
                  end
                end
                if new_verb_tags_array.empty?
                  verb_tags = nil
                else
                  verb_tags = new_verb_tags_array.join(" ")
                end
              end
            end
          end
          # RULE: 22 DEPTH:2 CONDITION:6
          if verb_part !~ /s$/ and verb_part !~ /r$/
            # RULE: 22 DEPTH:3 CONDITION:1
            if enclitic_part =~ /^no$/
              check_default = false
              result = [ false, nil, nil, nil ]
              return result
            end
          end
          # RULE: 22 DEPTH:2 CONDITION:7
          if verb_part !~ /s$/ and verb_part !~ /r$/
            # RULE: 22 DEPTH:3 CONDITION:1
            if enclitic_part =~ /^no.$/
              if verb_tags != nil
                verb_tags_array = verb_tags.split(/ /)
                new_verb_tags_array = Array.new
                verb_tags_array.each do |verb_tag|
                  if verb_tag =~ /V0f10s|V0f30s|Vfs10s|Vfs30s|Vfsa0s|V0f000|...2.s|...2.p/ and verb_tag !~ /V0m20s/ and verb_tag !~ /V0m20p/
                    # tag removing
                  else
                    new_verb_tags_array << verb_tag
                  end
                end
                if new_verb_tags_array.empty?
                  verb_tags = nil
                else
                  verb_tags = new_verb_tags_array.join(" ")
                end
              end
            end
          end
          # RULE: 22 DEPTH:2 CONDITION:8
          if verb_part !~ /s$/ and verb_part !~ /r$/
            # RULE: 22 DEPTH:3 CONDITION:1
            if enclitic_part =~ /^-lo|^-la|^-los|^-las|^lo|^la|^los|^las|^-l@|^-l@s|^l@|^l@s|^-lx|^-lxs|^lx|^lxs/
              check_default = false
              if verb_tags != nil
                verb_tags_array = verb_tags.split(/ /)
                new_verb_tags_array = Array.new
                verb_tags_array.each do |verb_tag|
                  if verb_tag !~ /V0f10s/ and verb_tag !~ /V0f30s/ and verb_tag !~ /Vfs10s/ and verb_tag !~ /Vfs30s/ and verb_tag !~ /Vfsa0s/ and verb_tag !~ /V0f000/ and verb_tag !~ /..[^m]2.s/ and verb_tag !~ /..[^m]2.p/ and verb_tag !~ /...1.p/
                    # tag removing
                  else
                    new_verb_tags_array << verb_tag
                  end
                end
                if new_verb_tags_array.empty?
                  verb_tags = nil
                else
                  verb_tags = new_verb_tags_array.join(" ")
                end
              end
            end
          end
          # RULE: 22 DEPTH:2 CONDITION:9
          if verb_part !~ /s$/ and verb_part !~ /r$/
            # RULE: 22 DEPTH:3 CONDITION:1
            if enclitic_part !~ /^-lo/ and enclitic_part !~ /^-la/ and enclitic_part !~ /^lo/ and enclitic_part !~ /^la/ and enclitic_part !~ /^-los/ and enclitic_part !~ /^-las/ and enclitic_part !~ /^los/ and enclitic_part !~ /^las/ and enclitic_part !~ /^nos/ and enclitic_part !~ /^no/ and enclitic_part !~ /^-l@/ and enclitic_part !~ /^l@/ and enclitic_part !~ /^-l@s/ and enclitic_part !~ /^l@s/ and enclitic_part !~ /^n@s/ and enclitic_part !~ /^n@/ and enclitic_part !~ /^-lx/ and enclitic_part !~ /^lx/ and enclitic_part !~ /^-lxs/ and enclitic_part !~ /^lxs/ and enclitic_part !~ /^nxs/ and enclitic_part !~ /^nx/
              if verb_tags != nil
                verb_tags_array = verb_tags.split(/ /)
                new_verb_tags_array = Array.new
                verb_tags_array.each do |verb_tag|
                  if verb_tag =~ /V0f10s|V0f30s|Vfs10s|Vfs30s|Vfsa0s|V0f000|...2.s|...2.p|...1.p/ and verb_tag !~ /V0m20s/ and verb_tag !~ /V0m20p/ and verb_tag !~ /Vei20s/
                    # tag removing
                  else
                    new_verb_tags_array << verb_tag
                  end
                end
                if new_verb_tags_array.empty?
                  verb_tags = nil
                else
                  verb_tags = new_verb_tags_array.join(" ")
                end
              end
            end
          end
        end
        # before rule 23 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 23
        # RULE: 23 DEPTH:1 CONDITION:1
        if enclitic_part =~ /^se/
          if verb_tags != nil
            verb_tags_array = verb_tags.split(/ /)
            new_verb_tags_array = Array.new
            verb_tags_array.each do |verb_tag|
              if verb_tag !~ /V0f000/ and verb_tag !~ /V0x000/ and verb_tag !~ /V..3/
                # tag removing
              else
                new_verb_tags_array << verb_tag
              end
            end
            if new_verb_tags_array.empty?
              verb_tags = nil
            else
              verb_tags = new_verb_tags_array.join(" ")
            end
          end
        end
        # before rule 24 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 24
        # RULE: 24 DEPTH:1 CONDITION:1
        if verb_part =~ /se$/
          # RULE: 24 DEPTH:2 CONDITION:1
          if verb_tags =~ /Ves30s/
            # RULE: 24 DEPTH:3 CONDITION:1
            if enclitic_part =~ /^se/
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        # before rule 25 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 25
        # RULE: 25 DEPTH:1 CONDITION:1
        if verb_part =~ /^es$/
          # RULE: 25 DEPTH:2 CONDITION:1
          if enclitic_part =~ /^te$/
            result = [ false, nil, nil, nil ]
            return result
          end
        end
        # before rule 26 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 26
        # RULE: 26 DEPTH:1 CONDITION:1
        if verb_tags =~ /...2.s/
          # RULE: 26 DEPTH:2 CONDITION:1
          if enclitic_part =~ /^vo|^vos/
            if verb_tags != nil
              verb_tags_array = verb_tags.split(/ /)
              new_verb_tags_array = Array.new
              verb_tags_array.each do |verb_tag|
                if verb_tag =~ /...2.s/
                  # tag removing
                else
                  new_verb_tags_array << verb_tag
                end
              end
              if new_verb_tags_array.empty?
                verb_tags = nil
              else
                verb_tags = new_verb_tags_array.join(" ")
              end
            end
          end
        end
        # before rule 27 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        # RULE: 27
        # RULE: 27 DEPTH:1 CONDITION:1
        if verb_tags =~ /Vei20s/
          # RULE: 27 DEPTH:2 CONDITION:1
          if enclitic_part =~ /^che|^ches|^cha|^chas|^cho|^chos/
            result = [ false, nil, nil, nil ]
            return result
          end
        end
        # before default rule 28 verb_part:#{verb_part}, verb_tags:#{verb_tags}, enclitic_part:#{enclitic_part}
        #    DEFAULT RULE: 28
        if check_default
          # RULE: 28 DEPTH:1 CONDITION:1
          if verb_part =~ /á$|a$|e$|é$|i$|í$|o$|ó$|u$|ú$|n$/
            # RULE: 28 DEPTH:2 CONDITION:1
            if enclitic_part =~ /^lo|^la|^las|^los|^-lo|^-la|^-los|^-las|^na|^nas/
              result = [ false, nil, nil, nil ]
              return result
            end
            # RULE: 28 DEPTH:2 CONDITION:2
            if enclitic_part =~ /no$/
              result = [ false, nil, nil, nil ]
              return result
            end
          end
        end
        if verb_tags == nil or verb_tags.empty?
          result = [ false, nil, nil, nil ]
          return result
        else
          result = [ true, verb_part, enclitic_part, verb_tags ]
          return result
        end
      end

    end
  end
end
