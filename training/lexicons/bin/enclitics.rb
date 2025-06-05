class Enclitics
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
    File.readlines(@enclitic_verbs_file_name).map(&:chomp).reject(&:empty?).each do |line|
      root, tag, lemma, hiperlemma, extra = line.split(/\t/)
      hiperlemma = lemma unless hiperlemma
      extra = extra ? "'#{extra}'" : "NULL"
      db.execute("INSERT INTO enclitic_verbs_roots (root, tag, lemma, hiperlemma, extra) VALUES ('#{root}','#{tag}','#{lemma}','#{hiperlemma}', #{extra}) ON CONFLICT DO NOTHING")
    end
  end

  def process_enclitics_file(db)
    File.readlines(@enclitics_file_name).map(&:chomp).reject(&:empty?).each do |line|
      enclitic, tag, lemma, hiperlemma = line.split(/\t/)
      hiperlemma = lemma unless hiperlemma
      db.execute("INSERT INTO enclitics (enclitic, tag, lemma, hiperlemma) VALUES ('#{enclitic}','#{tag}','#{lemma}','#{hiperlemma}') ON CONFLICT DO NOTHING")
    end
  end

  def process_enclitic_combinations_file(db)
    File.readlines(@enclitic_combinations_file_name).map(&:chomp).reject(&:empty?).each do |line|
      combination, length = line.split(/\t/)
      db.execute("INSERT INTO enclitic_combinations (combination, length) VALUES ('#{combination}',#{length})")
    end
  end
end
