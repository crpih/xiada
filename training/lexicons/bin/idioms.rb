require_relative "../../../lib/db_utils"

class Idioms
  include DbUtils

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
    data = File.readlines(file_name).map(&:chomp).reject(&:empty?).map do |line|
      idiom, tag, lemma, hiperlemma = line.split("\t")
      [idiom, tag, lemma, hiperlemma || lemma, sure]
    end
    bulk_insert(db, "idioms", %w[idiom tag lemma hiperlemma sure], data)
  end
end
