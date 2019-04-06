# -*- coding: utf-8 -*-
require_relative "../../../lib/sql_utils.rb"

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
    File.open(@enclitic_verbs_file_name, "r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          content = line.split(/\t/)
          if content.size > 3
            root, tag, lemma, hiperlemma, extra = line.split(/\t/)
            hiperlemma = lemma unless hiperlemma
          else
            root, tag, lemma = line.split(/\t/)
          end
          if extra
            db.execute("insert into enclitic_verbs_roots (root, tag, lemma, hiperlemma, extra) values ('#{root}','#{tag}','#{lemma}','#{hiperlemma}','#{extra}')")
          else
            db.execute("insert into enclitic_verbs_roots (root, tag, lemma, hiperlemma) values ('#{root}','#{tag}','#{lemma}','#{hiperlemma}')")
          end
        end
      end
    end
  end

  def process_enclitics_file(db)
    File.open(@enclitics_file_name, "r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          enclitic, tag, lemma, hiperlemma = line.split(/\t/)
          hiperlemma = lemma unless hiperlemma
          db.execute("insert into enclitics (enclitic, tag, lemma, hiperlemma) values ('#{enclitic}','#{tag}','#{lemma}','#{hiperlemma}')")
        end
      end
    end
  end

  def process_enclitic_combinations_file(db)
    File.open(@enclitic_combinations_file_name, "r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          combination, length = line.split(/\t/)
          db.execute("insert into enclitic_combinations (combination, length) values ('#{combination}',#{length})")
        end
      end
    end
  end
end
