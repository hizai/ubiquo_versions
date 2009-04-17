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
    definition = nil
    ActiveRecord::Base.connection.create_table(:test, :versionable => true){|table| definition=table}
    assert_not_nil definition[:version]
    assert_not_nil definition[:is_current_version]
  end
  
  def test_dont_create_versionable_table
    definition = nil
    ActiveRecord::Base.connection.create_table(:test){|table| definition=table}
    assert_nil definition[:version]
    assert_nil definition[:is_current_version]
  end
  
  def test_create_content_id_on_versionable_table
    definition = nil
    ActiveRecord::Base.connection.create_table(:test, :versionable => true){|table| definition=table}
    assert_not_nil definition[:content_id]
  end
  
end
