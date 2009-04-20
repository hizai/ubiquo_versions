module UbiquoVersions
  module Extensions
    autoload :ActiveRecord, 'ubiquo_versions/extensions/active_record'
  end
end

ActiveRecord::Base.send(:include, UbiquoVersions::Extensions::ActiveRecord)
