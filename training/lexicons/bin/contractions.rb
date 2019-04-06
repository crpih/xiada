# -*- coding: utf-8 -*-

class Contractions

  def initialize(file_name)
    @file_name = file_name
  end

  def save(db)
    db.execute("create table contractions (contraction text,
                first_component_word text, first_component_tag text, first_component_lemma, first_component_hiperlemma,
                second_component_word text, second_component_tag text, second_component_lemma, second_component_hiperlemma,
                third_component_word text, third_component_tag text, third_component_lemma, third_component_hiperlemma)")
    process_file(db)
  end

  private

  def process_file(db)
    elements = Array.new
    File.open(@file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          elements = line.split(/\t/)
          contraction = elements[0]
          first_component_word = elements[1]
          first_component_lemma = elements[2]
          first_component_hiperlemma = elements[3]
          first_component_tag = elements[4]
          second_component_word = elements[6]
          second_component_lemma = elements[7]
          second_component_hiperlemma = elements[8]
          second_component_tag = elements[9]
          if elements.size > 10
            third_component_word = elements[11]
            third_component_lemma = elements[12]
            third_component_hiperlemma = elements[13]
            third_component_tag = elements[14]
            query = "insert into contractions (contraction,
            first_component_word, first_component_tag, first_component_lemma, first_component_hiperlemma,
            second_component_word, second_component_tag, second_component_lemma, second_component_hiperlemma,
            third_component_word, third_component_tag, third_component_lemma, third_component_hiperlemma)
            values ('#{contraction}',
            '#{first_component_word}','#{first_component_tag}','#{first_component_lemma}','#{first_component_hiperlemma}',
            '#{second_component_word}','#{second_component_tag}','#{second_component_lemma}','#{second_component_hiperlemma}',
            '#{third_component_word}','#{third_component_tag}','#{third_component_lemma}', '#{third_component_hiperlemma}')"
          else
            query = "insert into contractions (contraction,
            first_component_word, first_component_tag, first_component_lemma, first_component_hiperlemma,
            second_component_word, second_component_tag, second_component_lemma, second_component_hiperlemma)
            values ('#{contraction}',
            '#{first_component_word}','#{first_component_tag}','#{first_component_lemma}','#{first_component_hiperlemma}',
            '#{second_component_word}','#{second_component_tag}','#{second_component_lemma}','#{second_component_hiperlemma}')"
          end
          db.execute(query)
        end
      end
    end
  end
end
