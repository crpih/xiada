# -*- coding: utf-8 -*-

class StringUtils
  def self.first_to_lower(str)
    if self.first_only_upper?(str) or self.alone_letter_upper?(str)
      return to_lower(str)
    else
      return str
    end
  end

  def self.first_to_upper(str)
    if all_lower?(str)
      first = str[0, 1]
      other = str[1, str.length - 1]
      upcase = to_upper(first)
      result = upcase + other
      return result
    else
      return str
    end
  end

  def self.to_lower(str)
    str = str.downcase
    str = str.gsub(/Á/, "á")
    str = str.gsub(/É/, "é")
    str = str.gsub(/Í/, "í")
    str = str.gsub(/Ó/, "ó")
    str = str.gsub(/Ú/, "ú")
    str = str.gsub(/Ñ/, "ñ")
    str = str.gsub(/Ü/, "ü")
    str = str.gsub(/Ö/, "ö")
    str = str.gsub(/Ä/, "ä")
    str = str.gsub(/Ë/, "ë")
    str = str.gsub(/Â/, "â")
    return str
  end

  def self.to_upper(str)
    str = str.upcase
    str = str.gsub(/á/, "Á")
    str = str.gsub(/é/, "É")
    str = str.gsub(/í/, "Í")
    str = str.gsub(/ó/, "Ó")
    str = str.gsub(/ú/, "Ú")
    str = str.gsub(/ñ/, "Ñ")
    str = str.gsub(/ü/, "Ü")
    str = str.gsub(/ö/, "Ö")
    str = str.gsub(/ä/, "Ä")
    str = str.gsub(/ë/, "Ë")
    str = str.gsub(/â/, "Â")
    return str
  end

  def self.first_only_upper?(str)
    if str =~ /^[A-ZÁÉÍÓÚÑÀÈÌÒÙÄËÏÖÜÃÕ][a-záéíóúñàèìòùçäëïöüâêîôûãõ@\-\)\(\/ ]+$/ 
      return true
    else
      return false
    end
  end

  def self.alone_letter_upper?(str)
    if str =~ /^[A-ZÁÉÍÓÚÑÀÈÌÒÙÄËÏÖÜÃÕ]$/
      return true
    else
      return false
    end
  end

  def self.propers_joined?(str)
    if str =~ /^[A-ZÁÉÍÓÚÑÀÈÌÒÙÄËÏÖÜÃÕ][a-záéíóúñäëïöüàèìòùçâêîôûãõ@\-\)\(\/ ]+[A-ZÁÉÍÓÚÑÀÈÌÒÙÄËÏÖÜÃÕ][a-záéíóúñäëïöüàèìòùçâêîôûãõ@\-\)\(\/) ]*$/ ||
       # Barcelona-Tarragona
       str =~ /^[A-ZÁÉÍÓÚÑÀÈÌÒÙÄËÏÖÜÃÕ][a-záéíóúñàèìòùçäëïöüâêîôûãõ@\-\)\(\/]+[A-ZÁÉÍÓÚÑÀÈÌÒÙÄËÏÖÜÃÕ][a-záéíóúñàèìòùçäëïöüâêîôûãõ@\-\)\(\/)]+$/ ||
       # YouTube
       str =~ /^([A-ZÁÉÍÓÚÑÀÈÌÒÙÄËÏÖÜÃÕ][a-záéíóúñàèìòùçäëïöüâêîôûãõ@\-\)\(\/]*)*'[A-ZÁÉÍÓÚÑÀÈÌÒÙÄËÏÖÜÃÕ][a-záéíóúñàèìòùçäëïöüâêîôûãõ@\-\)\(\/)]+$/
       # L'Oréal
       # Gerry O'Connor
      return true
    else
      return false
    end
  end

  def self.numbers_beginner?(str)
    if str =~ /^[\d\.]+[ªº]?$/ or str =~ /[a-zA-Z0-9][\)\.]$/
      return true
    else
      return false
    end
  end

  def self.punctuation_beginner?(str)
    if str =~ /^[¿¡_\(\["'_]$/ or str == "\.\.\."
      return true
    else
      return false
    end
  end

  def self.all_lower?(str)
    if str =~ /^[a-záéíóúñàèìòùäëïöüçâêîôûãõ]+$/
      return true
    else
      return false
    end
  end

  def self.without_tilde(str)
    str = str.gsub(/Á/, "A")
    str = str.gsub(/É/, "E")
    str = str.gsub(/Í/, "I")
    str = str.gsub(/Ó/, "O")
    str = str.gsub(/Ú/, "U")
    str = str.gsub(/Ü/, "U")
    str = str.gsub(/Ö/, "O")
    str = str.gsub(/Ä/, "A")
    str = str.gsub(/á/, "a")
    str = str.gsub(/é/, "e")
    str = str.gsub(/í/, "i")
    str = str.gsub(/ó/, "o")
    str = str.gsub(/ú/, "u")
    str = str.gsub(/ü/, "u")
    str = str.gsub(/ö/, "o")
    str = str.gsub(/ä/, "a")
    str = str.gsub(/ë/, "e")
    return str
  end

  def self.replace_xml_conflicting_characters(string)
    new_string = String.new(string)
    new_string.gsub!(/&/, "&amp;")
    new_string.gsub!(/</, "&lt;")
    new_string.gsub!(/>/, "&gt;")
    return new_string
  end

  def self.replace_xml_entities(string)
    new_string = String.new(string)
    new_string.gsub!(/&amp;/, "&")
    new_string.gsub!(/&lt;/, "<")
    new_string.gsub!(/&gt;/, ">")
    return new_string
  end
end
