require_relative "../../../lib/db_utils"

class Numerals
  include DbUtils

  MAX_NUM_COMPONENTS = 4

  def initialize(file_name, values_file_name)
    @file_name = file_name
    @values_file_name = values_file_name
  end

  def save(db)

    query = "create table cardinals (id integer, cardinal text, tag text, lemma text, hiperlemma text"
    (1..MAX_NUM_COMPONENTS).each do |cindex|
      column_name = "c"
      query = query + ", c#{cindex} text"
    end
    query = query + ", primary key(cardinal, tag)"
    query = query + ")"
    db.execute(query)
    process_file(db)
    db.execute("create index cardinals_cardinal on cardinals(cardinal)")
    (1..MAX_NUM_COMPONENTS).each do |cindex|
      db.execute("create index cardinals_c#{cindex} on cardinals(c#{cindex})")
    end
    db.execute("create table numerals_values (variable_name text, value text)")
    process_values_file(db)
  end

  private

  def process_file(db)
    data = File.readlines(@file_name).each_with_index.map do |line, i|
      cardinal, tag, lemma, hiperlemma = line.chomp.split("\t")
      components = cardinal.split(" ")
      if components.length > MAX_NUM_COMPONENTS
        puts "Cardinal \"#{cardinal}\" is greater than current database capacity"
        puts "exiting..."
        exit
      end
      # Fill missing components with nil
      components.push(*Array.new(MAX_NUM_COMPONENTS - components.length, nil))

      [i + 1, cardinal, tag, lemma, hiperlemma || lemma, *components]
    end

    cardinal_columns = (1..MAX_NUM_COMPONENTS).map { |i| "c#{i}" }
    bulk_insert(db, "cardinals", ["id", "cardinal", "tag", "lemma", "hiperlemma", *cardinal_columns], data)
  end

  def process_values_file(db)
    data = File.readlines(@values_file_name).map do |line|
      variable_name, *values = line.chomp.split("\t")
      [variable_name, values.join(" ")]
    end
    bulk_insert(db, "numerals_values", %w[variable_name value], data)
  end
end
