module UbiquoVersions
  module Adapters
    autoload :Postgres, "ubiquo_versions/adapters/postgres"
  end
end

included_module = case ActiveRecord::Base.connection.class.to_s
when "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
  UbiquoVersions::Adapters::Postgres
else
  nil
end

raise "Only PostgreSQL supported" if  included_module == nil

ActiveRecord::Base.connection.class.send(:include, included_module)
ActiveRecord::ConnectionAdapters::SchemaStatements.send(:include, UbiquoVersions::Adapters::SchemaStatements)
