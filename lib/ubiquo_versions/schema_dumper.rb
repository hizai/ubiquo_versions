module UbiquoVersions
  module SchemaDumper
    def self.included(klass)
      klass.send(:alias_method_chain, :table, :versions)
    end
    
    def table_with_versions(table, stream)
      tbl = StringIO.new
      table_without_versions(table, tbl)
      tbl.rewind
      result = tbl.read
      result.gsub!(/integer([\s]*) (\"version_number\")([^\n]*)/, ('sequence\1"'+table+'", \2'))
      result.gsub!(/integer([\s]*) (\"content_id\")([^\n]*)/, ('sequence\1"'+table+'", \2'))
      stream.print result
    end
  end
end


ActiveRecord::SchemaDumper.send(:include, UbiquoVersions::SchemaDumper)
