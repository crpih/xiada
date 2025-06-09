module DbUtils
  def bulk_insert(db, table, columns, data)
    query = "INSERT INTO #{table} (#{columns.join(',')}) VALUES (#{(['?'] * columns.size).join(',')}) ON CONFLICT DO NOTHING"
    db.transaction do
      statement = db.prepare(query)
      data.each { |r| statement.execute(*r) }
    end
  end
end
