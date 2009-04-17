require File.dirname(__FILE__) + "/../test_helper.rb"
require 'mocha'

class UbiquoVersions::AdaptersTest < ActiveSupport::TestCase
  def test_sequences
    ActiveRecord::Base.connection.create_sequence(:test)
    
    (1..10).each do |i|
      assert_equal i, ActiveRecord::Base.connection.next_val_sequence(:test)
    end
    
    ActiveRecord::Base.connection.drop_sequence(:test)
    assert_raises ActiveRecord::StatementInvalid do
      ActiveRecord::Base.connection.next_val_sequence(:test)
    end
  end
  
  def test_create_versionable_table
    ActiveRecord::ConnectionAdapters::TableDefinition.any_instance.expects(:integer).with(:version, :null => false).once
    ActiveRecord::ConnectionAdapters::TableDefinition.any_instance.expects(:boolean).with(:is_current_version, :null => false, :default => false).once
    
    ActiveRecord::Base.connection.create_table(:test, :versionable => true){}
  end
  
  def test_dont_create_versionable_table
    ActiveRecord::ConnectionAdapters::TableDefinition.any_instance.expects(:integer).with(:version, :null => false).times(0)
    ActiveRecord::ConnectionAdapters::TableDefinition.any_instance.expects(:boolean).with(:is_current_version, :null => false, :default => false).times(0)
    
    ActiveRecord::Base.connection.create_table(:test){}
  end
  
end
