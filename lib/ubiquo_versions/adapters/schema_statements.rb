module UbiquoVersions
  module Adapters
    # Extends the create_table method to support the :versionable option
    module SchemaStatements

      # Perform the actual linking with create_table
      def self.included(klass)
        klass.send(:alias_method_chain, :create_table, :versions)
      end

      # Parse the :versionable option as a create_table extension
      # 
      # This will actually add four fields:
      #   table.version_number : sequence
      #   table.content_id : sequence
      #   table.is_current_version : boolean
      #   table.parent_version : integer
      # with their respective indexes (except for version_number)
      def create_table_with_versions(table_name, options={})
        versionable = options.delete(:versionable)
        create_table_without_versions(table_name, options) do |table_definition|
          yield table_definition
          if versionable
            table_definition.sequence table_name, :version_number
            table_definition.boolean :is_current_version, :null => false, :default => false
            table_definition.sequence table_name, :content_id
            table_definition.integer :parent_version
          end
        end
        if versionable
          add_index table_name, :is_current_version
          add_index table_name, :content_id unless indexes(table_name).map(&:columns).flatten.include? "content_id"
          add_index table_name, :parent_version
        end
      end
    end
  end
end
