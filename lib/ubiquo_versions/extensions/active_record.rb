module UbiquoVersions
  module Extensions
    module ActiveRecord

      def self.append_features(base)
        super
        base.extend(ClassMethods)
        base.send :include, InstanceMethods
      end

      module ClassMethods

        # Class method for ActiveRecord that states that a model is versionable
        #
        # EXAMPLE:
        #
        #   versionable :max_amount => 5

        def versionable(options = {})
          @versionable = true
          @versionable_options = options
        end
      end
      
      module InstanceMethods
        
        def self.included(klass)
          klass.alias_method_chain :create, :version_info
          klass.alias_method_chain :update, :version
        end
        
        # proxy to add a new content_id if empty on creation
        def create_with_version_info
          if self.class.instance_variable_get('@versionable')
            # we do this even if there is not currently any tr. attribute, 
            # as long as @translatable_attributes is defined
            unless self.content_id
              self.content_id = self.class.connection.next_val_sequence("#{self.class.to_s.tableize}_content_id")
            end
            unless self.version_number
              self.version_number = next_version_number
              self.is_current_version = true
            end
          end
          create_without_version_info
        end
        
        def update_with_version
          current_instance = self.class.find(self.id).clone
          self.version_number = next_version_number
          if update_without_version > 0
            current_instance.is_current_version = false
            current_instance.save
          end
        end
        
        # Note that every time that is called, a version number is assigned
        def next_version_number
          self.class.connection.next_val_sequence("#{self.class.to_s.tableize}_version_number")
        end

      end

    end
  end
end
