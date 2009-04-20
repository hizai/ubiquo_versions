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
            table_definition.integer :version, :null => false
            table_definition.boolean :is_current_version, :null => false, :default => false
            table_definition.content_id table_name
          end
        end
      end
    end
  end
end
