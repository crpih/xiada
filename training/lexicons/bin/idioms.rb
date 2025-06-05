class Idioms

  def initialize(sure_idioms_file_name, unsure_idioms_file_name)
    @sure_idioms_file_name = sure_idioms_file_name
    @unsure_idioms_file_name = unsure_idioms_file_name
  end

  def save(db)
    db.execute("create table idioms (idiom text, tag text, lemma text, hiperlemma text, sure integer)")
    process_file(db, @sure_idioms_file_name, 1)
    process_file(db, @unsure_idioms_file_name, 0)
  end

  private

  def process_file(db, file_name, sure)
    File.open(file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          idiom, tag, lemma, hiperlemma = line.split(/\t/)
          hiperlemma = lemma unless hiperlemma
          @db.execute("INSERT INTO idioms (idiom, tag, lemma, hiperlemma, sure) VALUES (?, ?, ?, ?, ?)", [idiom, tag, lemma, hiperlemma, sure])
        end
      end
    end
  end
end
