# -*- coding: utf-8 -*-
  def combinacion_etqs_decenas_unidades(decena, decena_etqs, unidade, unidade_etqs)
    # As etiquetas das unidades filtran o xénero das decenas
    resultado = Array.new
    filtro_xenero = true
    letra_xenero = nil
    letra_xenero_old = nil
    unidade_etqs.each do |etq|
      letra_xenero = get_xenero_etiqueta(etq)
      filtro_xenero = false if (letra_xenero_old != nil) and (letra_xenero != letra_xenero_old)
      letra_xenero_old = letra_xenero
    end
    #puts "decena:#{decena} unidade:#{unidade} filtro_xenero:#{filtro_xenero}"
    decena_etqs.each do |etq|
      if filtro_xenero
        etq = modifica_xenero_etiqueta(etq,letra_xenero)
      end
      resultado << etq
    end
    return resultado.uniq
  end

  def get_xenero_etiqueta(etq)
    if etq[0,1] == 'N'
      return etq[3]
    elsif etq[0,1] == 'S'
      return etq[2]
    else
      return nil
    end
  end

  def modifica_xenero_etiqueta(etq,letra_xenero)
    etq_aux = String.new(etq)
    if etq_aux[0,1] == 'N'
      etq_aux[3] = letra_xenero
    elsif etq[0,1] == 'S'
      etq_aux[2] = letra_xenero
    else
      puts "ERRO: Non pode ser a etiqueta #{etq_aux} para os numerais"
      exit
    end
    return etq_aux
  end
  
  def xenero(etqs)
    letra_xenero = nil
    letra_xenero_old = nil
    etqs.each do |etq|
      if etq[0,1] == 'N'
        letra_xenero = etq[3]
      elsif etq[0,1] == 'S'
        letra_xenero = etq[2]
      end
      return nil if (letra_xenero_old != nil) and (letra_xenero != letra_xenero_old)
      letra_xenero_old = letra_xenero
    end
    return letra_xenero
  end
  
  def combinacion_etqs_centenas_unidades(centena, centena_etqs, unidade, unidade_etqs)
    resultado = Array.new
    xenero_definido_centena = xenero(centena_etqs)
    xenero_definido_unidade = xenero(unidade_etqs)
    centena_etqs.each do |etq|
      unless (xenero_definido_centena != nil) and (xenero_definido_unidade != nil) and
             (xenero_definido_centena != xenero_definido_unidade)
        # Número coherente. Non se mesturan masculinos con femininos.
        if (xenero_definido_unidade != nil) and (xenero_definido_centena == nil)
          etq = modifica_xenero_etiqueta(etq, xenero_definido_unidade)
        end
        resultado << etq
      end
    end
    return resultado
  end

  def combinacions_centenas(unidades, unidades_etqs, unidades_lemas,
                            decenas_monotoken, decenas_monotoken_etqs, decenas_monotoken_lemas,
                            decenas, decenas_etqs, decenas_lemas,
                            centenas, centenas_etqs, centenas_lemas,
                            conector_unidades_decenas)
                            
    etiquetas = Hash.new
    lemas = Hash.new    
    # unidades
    unidades.each do |unidade|
      etqs = unidades_etqs[unidade]
      lema = unidades_lemas[unidade]
      etiquetas[unidade] = etqs
      lemas[unidade] = lema
    end

    # decenas
    decenas_monotoken.each do |decena|
      etqs = decenas_monotoken_etqs[decena]
      lema = decenas_monotoken_lemas[decena]
      etiquetas[decena] = etqs
      lemas[decena] = lema
    end
    
    decenas.each do |decena|
      etqs_decena = decenas_etqs[decena]
      lema_decena = decenas_lemas[decena]
      etiquetas[decena] = etqs_decena
      lemas[decena] = lema_decena
      unidades.each do |unidade|
        etqs = combinacion_etqs_decenas_unidades(decena, decenas_etqs[decena], unidade, unidades_etqs[unidade])
        lema_unidade = unidades_lemas[unidade]
        etiquetas["#{decena} #{conector_unidades_decenas} #{unidade}"] = etqs
        lemas["#{decena} #{conector_unidades_decenas} #{unidade}"] = "#{lema_decena} #{conector_unidades_decenas} #{lema_unidade}"
      end
    end
    
    # centenas
    centenas.each do |centena|
      etqs_centena = centenas_etqs[centena]
      lema_centena = centenas_lemas[centena]
      etiquetas[centena] = etqs_centena
      lemas[centena] = lema_centena
      
      unless centena == "cen"
        unidades.each do |unidade|
          etqs_unidade = unidades_etqs[unidade]
          lema_unidade = unidades_lemas[unidade]
          etqs = combinacion_etqs_centenas_unidades(centena, etqs_centena, unidade, etqs_unidade)
          etiquetas["#{centena} #{unidade}"] = etqs
          lemas["#{centena} #{unidade}"] = "#{lema_centena} #{lema_unidade}"
        end
        decenas_monotoken.each do |decena|
          etqs_decena = decenas_monotoken_etqs[decena]
          lema_decena = decenas_monotoken_lemas[decena]
          etqs = combinacion_etqs_centenas_unidades(centena, etqs_centena, decena, etqs_decena)
          etiquetas["#{centena} #{decena}"] = etqs
          lemas["#{centena} #{decena}"] = "#{lema_centena} #{lema_decena}"
        end
        decenas.each do |decena|
          etqs_decena = decenas_etqs[decena]
          lema_decena = decenas_lemas[decena]
          etqs = combinacion_etqs_centenas_unidades(centena, etqs_centena, decena, etqs_decena)
          etiquetas["#{centena} #{decena}"] = etqs
          lemas["#{centena} #{decena}"] = "#{lema_centena} #{lema_decena}"          
          unidades.each do |unidade|
            etqs_unidade = unidades_etqs[unidade]
            lema_unidade = unidades_lemas[unidade]            
            etqs = combinacion_etqs_centenas_unidades(centena, etqs_centena, unidade, etqs_unidade)
            etiquetas["#{centena} #{decena} #{conector_unidades_decenas} #{unidade}"] = etqs
            lemas["#{centena} #{decena} #{conector_unidades_decenas} #{unidade}"] = "#{lema_centena} #{lema_decena} #{conector_unidades_decenas} #{lema_unidade}"
          end
        end
      end # de unless centena == "cen"
    end
    resultado = Array.new
    resultado << etiquetas
    resultado << lemas
    return resultado
  end
  
  def imprime_resultado(resultado)
    etiquetas = resultado[0]
    lemas = resultado[1]
    etiquetas.each do |key, etqs|
      etqs.each do |etq|
        puts "#{key}\t#{etq}\t#{lemas[key]}"
      end
    end
  end
  
  def combina_etiquetas_mil(etqs1, etqs2)
    xenero1 = xenero(etqs1)
    xenero2 = xenero(etqs2)
    return nil if xenero1 != nil and xenero2 != nil and xenero1 != xenero2
    return etqs2 if xenero1 == nil
    #return etqs1 if xenero2 == nil
    return etqs1
    
  end
  
  def imprime_resultado_mil(resultado)
    etiquetas = resultado[0]
    lemas = resultado[1]
    etiquetas.each do |key1, etqs1|
      etqs1.each do |etq|
        puts "mil #{key1}\t#{etq}\tmil #{lemas[key1]}"
        puts "#{key1} mil\t#{etq}\t#{lemas[key1]} mil" unless key1 == "un"
      end
      etiquetas.each do |key2, etqs2|
        unless key1 == "un"
          etqs = combina_etiquetas_mil(etqs1, etqs2)
          unless etqs == nil
            etqs.each do |etq|
              puts "#{key1} mil #{key2}\t#{etq}\t#{lemas[key1]} mil #{lemas[key2]}"
            end
          end
        end
      end
    end
  end

if ARGV.size == 0

  unidades = ["un","unha","dous","dúas","tres","catro","cinco","seis","sete","oito","nove"]
  unidades_etqs = Hash.new
  unidades_lemas = Hash.new
  unidades.each do |unidade|
    unidades_etqs[unidade] = ["Ncdmp","Ncdfp","Ncnmp","Ncnfp","Ncnms","Scms"]
    unidades_lemas[unidade] = unidade
  end 
  unidades_etqs["un"] = ["Ncdms","Ncnms","Scms"]
  unidades_etqs["unha"] = ["Ncdfs","Ncnfs"]
  unidades_etqs["dous"] = ["Ncdmp","Ncnmp","Ncnms","Scms"]
  unidades_etqs["dúas"] = ["Ncdfp","Ncnfp"]
  unidades_lemas["unha"] = "un"
  unidades_lemas["dúas"] = "dous"
  
  decenas_monotoken = ["dez","once","doce","trece","catorce","quince","dezaseis","dezasete","dezaoito","dezanove","vinteún","vinteunha","vintedous","vintedúas", "vintetrés","vintecatro","vintecinco","vinteseis","vintesete","vinteoito","vintenove"]
  decenas_monotoken_etqs = Hash.new
  decenas_monotoken_lemas = Hash.new
  decenas_monotoken.each do |decena|
    decenas_monotoken_etqs[decena] = ["Ncdmp","Ncdfp","Ncnmp","Ncnfp","Ncnms","Scms"]
    decenas_monotoken_lemas[decena] = decena
  end
  decenas_monotoken_etqs["vinteún"] = ["Ncdmp","Ncnmp","Ncnms","Scms"]
  decenas_monotoken_etqs["vinteunha"] = ["Ncdfp","Ncnfp"]
  decenas_monotoken_etqs["vintedous"] = ["Ncdmp","Ncnmp","Ncnms","Scms"]
  decenas_monotoken_etqs["vintedúas"] = ["Ncdfp","Ncnfp"]
  decenas_monotoken_lemas["vinteunha"] = "vinteún"
  decenas_monotoken_lemas["vintedúas"] = "vintedous"
  
  decenas = ["vinte","trinta","corenta","cincuenta","sesenta","setenta","oitenta","noventa"]
  decenas_etqs = Hash.new
  decenas_lemas = Hash.new
  decenas.each do |decena|
    decenas_etqs[decena] = ["Ncdmp","Ncdfp","Ncnmp","Ncnfp","Ncnms","Scms"]
    decenas_lemas[decena] = decena
  end
  
  centenas = ["cen", "cento","douscentos","duascentas","trescentos","trescentas","catrocentos","catrocentas","quinientos","cincocentos","quinientas","cincocentas","seiscentos","seiscentas","setecentos","setecentas","oitocentos","oitocentas","novecentos","novecentas"]
  centenas_etqs = Hash.new
  centenas_lemas = Hash.new
  centenas.each do |centena|
    centenas_etqs[centena] = ["Ncdmp","Ncnmp","Ncnms","Scms","Scmp","Scma"]
    centenas_lemas[centena] = centena
  end
  centenas_etqs["duascentas"] = ["Ncdfp","Ncnfp"]
  centenas_etqs["trescentas"] = ["Ncdfp","Ncnfp"]
  centenas_etqs["catrocentas"] = ["Ncdfp","Ncnfp"]
  centenas_etqs["cincocentas"] = ["Ncdfp","Ncnfp"]
  centenas_etqs["quinientas"] = ["Ncdfp","Ncnfp"]
  centenas_etqs["seiscentas"] = ["Ncdfp","Ncnfp"]
  centenas_etqs["setecentas"] = ["Ncdfp","Ncnfp"]
  centenas_etqs["oitocentas"] = ["Ncdfp","Ncnfp"]
  centenas_etqs["novecentas"] = ["Ncdfp","Ncnfp"]
  centenas_etqs["cen"] = ["Ncdmp","Ncnmp","Ncdfp","Ncnfp","Ncnms","Scms"]
  centenas_etqs["cento"] = ["Ncdmp","Ncdfp","Ncnmp","Ncnfp","Ncnms","Scms"]

  centenas_lemas["duascentas"] = "douscentos"
  centenas_lemas["trescentas"] = "trescentos"
  centenas_lemas["catrocentas"] = "catrocentos"
  centenas_lemas["cincocentas"] = "cincocentos"
  centenas_lemas["quinientas"] = "quinientos"
  centenas_lemas["seiscentas"] = "seiscentos"
  centenas_lemas["setecentas"] = "setecentos"
  centenas_lemas["oitocentas"] = "oitocentos"
  centenas_lemas["novecentas"] = "novecentos"
  
  conector_unidades_decenas = "e"

  resultado = combinacions_centenas(unidades, unidades_etqs, unidades_lemas,
                                    decenas_monotoken, decenas_monotoken_etqs, decenas_monotoken_lemas,
                                    decenas, decenas_etqs, decenas_lemas,
                                    centenas, centenas_etqs, centenas_lemas,
                                    conector_unidades_decenas)
  imprime_resultado(resultado)
  #imprime_resultado_mil(resultado)
    
else
  puts "Usage:"
  puts "\truby #{$PROGRAM_NAME}"
end

