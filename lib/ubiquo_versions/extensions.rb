module UbiquoVersions
  module Extensions
    autoload :ActiveRecord, 'ubiquo_versions/extensions/active_record'
    autoload :Helpers, 'ubiquo_versions/extensions/helpers'
  end
end

ActiveRecord::Base.send(:include, UbiquoVersions::Extensions::ActiveRecord)
Ubiquo::Extensions::UbiquoAreaController.append_helper(UbiquoVersions::Extensions::Helpers)
