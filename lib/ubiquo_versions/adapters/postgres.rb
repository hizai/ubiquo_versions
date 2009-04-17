module UbiquoVersions
  module Adapters
    module Postgres
      def self.included(klass)
        klass.send :include, InstanceMethods
      end
      module InstanceMethods
        def create_sequence(name)
          self.execute("CREATE SEQUENCE %s;" % name)
        end
        
        def drop_sequence(name)
          self.execute("DROP SEQUENCE %s;" % name)
          
        end
        
        def next_val_sequence(name)
          self.execute("SELECT nextval('%s');" % name).rows.first.first.to_i
        end
      end
    end
  end
end
