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
            add_translatable_attributes(:version_number, :is_current_version)
          end
          
          # version_number constitute a translatable scope (should not update old versions)
          if respond_to?(:add_translatable_scope) 
            add_translatable_scope(
              lambda do |element|
                condition = "#{self.table_name}.is_current_version = true"
                # a new version record with old information doesn't have related translations
                condition += " AND 1=0 " unless element.is_current_version
                condition
              end
            )
          end
          
          define_method("versions") do
            self.class.all({:conditions => [
                  "#{self.class.table_name}.content_id = ? AND #{self.class.table_name}.id != ? AND #{self.class.table_name}.parent_version = ?", 
                  self.content_id, 
                  self.id,
                  self.parent_version
                ],
                :version => :all
              })
          end
        end

        # Adds :current_version => true to versionable models unless explicitly said :version option
        def find_with_current_version(*args)
          if self.instance_variable_get('@versionable')
            options = args.extract_options!
            prepare_options_for_version!(options)
            
            find_without_current_version(args.first, options)
          else
            find_without_current_version(*args)
          end
        end
        
        # Adds :current_version => true to versionable models unless explicitly said :version option
        def count_with_current_version(*args)
          if self.instance_variable_get('@versionable')
            options = args.extract_options!
            prepare_options_for_version!(options)
            
            count_without_current_version(args.first, options)
          else
            count_without_current_version(*args)
          end

        end

        # Alias for AR functions when is extended with this module
        def self.extended(klass)
          klass.class_eval do
            class << self
              alias_method_chain :find, :current_version
              alias_method_chain :count, :current_version
            end
          end
        end
        
        def prepare_options_for_version!(options)
          v = options.delete(:version)
          
          case v
          when Fixnum
            options[:conditions] = merge_conditions(options[:conditions], {:version_number => v})
          when :all
            #do nothing...
          else # no t an expected version setted. Acts as :last
            options[:conditions] = merge_conditions(options[:conditions], {:is_current_version => true})
          end
          options
        end
        
        # Used to execute a block that would create a version without this effect
        def without_versionable
          @versionable_disabled = true
          yield
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
            if disable_versionable_once
              create_without_version_info
              return
            end
            unless self.content_id
              self.content_id = self.class.connection.next_val_sequence("#{self.class.table_name}_content_id")
            end
            unless self.version_number
              self.version_number = next_version_number
              self.is_current_version = true
            end
            create_without_version_info

            unless self.parent_version
              self.class.without_versionable {update_attribute :parent_version, self.id}
            end
            create_version_for_other_current_versions if self.is_current_version
          else
            create_without_version_info

          end
        end
        
        def update_with_version
          if self.class.instance_variable_get('@versionable')
            if disable_versionable_once
              update_without_version
              return
            end
            self.version_number = next_version_number
            create_new_version
            update_without_version
            create_version_for_other_current_versions if self.is_current_version
          else
            update_without_version
          end
        end
        
          # This function looks for other instances sharing the same content_id and is_current_version = true,
          # and creates a new version for them too.
          # This is useful if for any reason (e.g i18n) you have more than one current version per content_id
          def create_version_for_other_current_versions
            self.class.all(
              :conditions => ["content_id = ? AND is_current_version = ? AND id != ?", self.content_id, true, self.id]
            ).each do |current_version|
              current_version.create_new_version
            end
          end
        
          def create_new_version
            current_instance = self.class.find(self.id).clone
            current_instance.is_current_version = false
            current_instance.parent_version = self.id
            current_instance.save
            # delete the older versions if there are too many versions (as defined by max_amount)
            if max_amount = self.class.instance_variable_get('@versionable_options')[:max_amount]
              versions_by_number = self.versions.sort {|a,b| a.version_number <=> b.version_number}
              (versions_by_number.size - max_amount).times do |i|
                versions_by_number[i].delete
              end
            end
          end
        
          def disable_versionable_once          
            if self.class.instance_variable_get('@versionable_disabled')
              self.class.instance_variable_set('@versionable_disabled', false)
              true
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
