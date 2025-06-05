require_relative "../../../lib/db_utils"

class Enclitics
  include DbUtils

  def initialize(enclitic_verbs_file_name, enclitics_file_name, enclitic_combinations_file_name)
    @enclitic_verbs_file_name = enclitic_verbs_file_name
    @enclitics_file_name = enclitics_file_name
    @enclitic_combinations_file_name = enclitic_combinations_file_name
  end

  def save(db)
    db.execute("create table enclitic_verbs_roots(root text, tag text, lemma text, hiperlemma text, extra text, primary key(root, tag, lemma, hiperlemma, extra))")
    process_enclitic_verbs_file(db)
    db.execute("create index enclitic_verbs_roots_root on enclitic_verbs_roots(root)")
    db.execute("create index enclitic_verbs_roots_root_tag on enclitic_verbs_roots(root, tag)")

    db.execute("create table enclitics (enclitic text, tag text, lemma text, hiperlemma text, primary key(enclitic, tag))")

    process_enclitics_file(db)
    db.execute("create index enclitics_enclitic on enclitics(enclitic)")

    db.execute("create table enclitic_combinations (combination text primary key, length integer)")
    process_enclitic_combinations_file(db)
  end

  private

  def process_enclitic_verbs_file(db)
    data = File.readlines(@enclitic_verbs_file_name).map(&:chomp).reject(&:empty?).map do |line|
      root, tag, lemma, hiperlemma, extra = line.split("\t")
      [root, tag, lemma, hiperlemma || lemma, extra]
    end
    bulk_insert(db, "enclitic_verbs_roots", %w[root tag lemma hiperlemma extra], data)
  end

  def process_enclitics_file(db)
    data = File.readlines(@enclitics_file_name).map(&:chomp).reject(&:empty?).map do |line|
      enclitic, tag, lemma, hiperlemma = line.split(/\t/)
      [enclitic, tag, lemma, hiperlemma || lemma]
    end
    bulk_insert(db, "enclitics", %w[enclitic tag lemma hiperlemma], data)
  end

  def process_enclitic_combinations_file(db)
    data = File.readlines(@enclitic_combinations_file_name).map(&:chomp).reject(&:empty?).map do |line|
      combination, length = line.split("\t")
      [combination, length.to_i]
    end
    bulk_insert(db, "enclitic_combinations", %w[combination length], data)
  end
end
