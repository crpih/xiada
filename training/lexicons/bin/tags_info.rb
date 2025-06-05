require_relative "../../../lib/db_utils"

class TagsInfo
  include DbUtils

  def initialize(file_name)
    @file_name = file_name
  end

  def save(db)
    query = "create table tags_info (id integer, category text, name text, class text)"
    db.execute(query)
    process_file(db)
  end

  private

  def process_file(db)
    data = File.readlines(@file_name).map(&:chomp).reject(&:empty?).map.with_index do |line, i|
      category, category_class, name = line.split("\t")
      [i + 1, category, name, category_class]
    end
    bulk_insert(db, "tags_info", %w[id category name class], data)
  end
end
