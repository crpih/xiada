class TagsInfo

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
    id = 1
    File.open(@file_name,"r") do |file|
      while line = file.gets
        line.chomp!
        unless line.empty?
          category, category_class, name = line.split(/\t/)
          db.execute("INSERT INTO tags_info (id, category, name, class) VALUES (?, ?, ?, ?)", [id, category, name, category_class])
          id = id + 1
        end
      end
    end
  end
end
