class Acronyms

  def initialize(file_name)
    @file_name = file_name
  end

  def save(db)
    db.execute("create table acronyms (acronym text, tag text, lemma text, hiperlemma text)")
    process_file(db)
  end

  private

  def process_file(db)
    File.open(@file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          acronym, tag, lemma, hiperlemma = line.split(/\t/)
          hiperlemma = lemma unless hiperlemma
          db.execute("INSERT INTO acronyms (acronym, tag, lemma, hiperlemma) VALUES (?, ?, ?, ?)", [acronym, tag, lemma, hiperlemma])
          db.execute(query)
        end
      end
    end
  end
end
