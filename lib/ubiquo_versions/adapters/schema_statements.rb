module UbiquoVersions
  module Adapters
    module SchemaStatements
      def self.included(klass)
        klass.send(:alias_method_chain, :create_table, :versions)
      end
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
      end
    end
  end
end
