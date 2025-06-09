require_relative "../../../lib/db_utils"

class Abbreviations
  include DbUtils

  def initialize(file_name)
    @file_name = file_name
  end

  def save(db)
    db.execute("create table abbreviations (abbreviation text, tag text, lemma text, hiperlemma)")
    process_file(db)
  end

  private

  def process_file(db)
    data = File.readlines(@file_name).map do |line|
      abbreviation, tag, lemma, hiperlemma = line.chomp.split("\t")
      [abbreviation, tag, lemma, hiperlemma || lemma]
    end
    bulk_insert(db, "abbreviations", %w[abbreviation tag lemma hiperlemma], data)
  end
end
