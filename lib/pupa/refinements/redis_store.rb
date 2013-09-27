# Adds a method to list all keys in the database.
class ActiveSupport::Cache::RedisStore
  def entries
    @data.keys('*')
  end
end
