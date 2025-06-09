require_relative "../../../lib/db_utils"

class Acronyms
  include DbUtils

  def initialize(file_name)
    @file_name = file_name
  end

  def save(db)
    db.execute("create table acronyms (acronym text, tag text, lemma text, hiperlemma text)")
    process_file(db)
  end

  private

  def process_file(db)
    data = File.readlines(@file_name).map do |line|
      acronym, tag, lemma, hiperlemma = line.chomp.split("\t")
      [acronym, tag, lemma, hiperlemma || lemma]
    end
    bulk_insert(db, "acronyms", %w[acronym tag lemma hiperlemma], data)
  end
end
