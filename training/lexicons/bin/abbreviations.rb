class Abbreviations

  def initialize(file_name)
    @file_name = file_name
  end

  def save(db)
    db.execute("create table abbreviations (abbreviation text, tag text, lemma text, hiperlemma)")
    process_file(db)
  end

  private

  def process_file(db)
    File.open(@file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          abbreviation, tag, lemma, hiperlemma = line.split(/\t/)
          hiperlemma = lemma unless hiperlemma
          db.execute("INSERT INTO abbreviations (abbreviation, tag, lemma, hiperlemma) VALUES (?, ?, ?, ?)", [abbreviation, tag, lemma, hiperlemma])
        end
      end
    end
  end
end
