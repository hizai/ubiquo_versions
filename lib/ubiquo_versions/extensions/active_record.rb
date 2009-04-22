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
          # version_number should not be copied between instances if a model is translatable
          if respond_to?(:add_translatable_attributes) 
            add_translatable_attributes(:version_number)
          end
        end

        # Adds :current_version => true to versionable models unless explicitly said :version => :all
        def find_with_current_version(*args)
          if self.instance_variable_get('@versionable')
            options = args.extract_options!
            v = options.delete(:version)
            
            case v
            when nil
              options[:conditions] = merge_conditions(options[:conditions], {:is_current_version => true})
            when Fixnum
              options[:conditions] = merge_conditions(options[:conditions], {:version_number => v})
            end
            find_without_current_version(args.first, options)
          else
            find_without_current_version(*args)
          end

        end

        # Alias for AR functions when is extended with this module
        def self.extended(klass)
          klass.class_eval do
            class << self
              alias_method_chain :find, :current_version
            end
          end
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
              self.content_id = self.class.connection.next_val_sequence("#{self.class.table_name}_content_id")
            end
            unless self.version_number
              self.version_number = next_version_number
              self.is_current_version = true
            end
          end
          create_without_version_info
        end
        
        def update_with_version
          if self.class.instance_variable_get('@versionable')
            current_instance = self.class.find(self.id).clone
            self.version_number = next_version_number
            if update_without_version > 0
              current_instance.is_current_version = false
              current_instance.save              
            end
          else
            update_without_version
          end
        end
        
        # Note that every time that is called, a version number is assigned
        def next_version_number
          self.class.connection.next_val_sequence("#{self.class.table_name}_version_number")
        end
        
      end

    end
  end
end
