require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoVersions::AdaptersTest < ActiveSupport::TestCase
  
  def test_create_versionable_table
    definition = nil
    ActiveRecord::Base.connection.create_table(:test, :versionable => true, :force => true){|table| definition=table}
    ActiveRecord::Base.connection.drop_table(:test)
    assert_not_nil definition[:version_number]
    assert_not_nil definition[:is_current_version]
    assert_not_nil definition[:parent_version]
  end
  
  def test_dont_create_versionable_table
    definition = nil
    ActiveRecord::Base.connection.create_table(:test, :force => true){|table| definition=table}
    ActiveRecord::Base.connection.drop_table(:test)
    assert_nil definition[:version_number]
    assert_nil definition[:is_current_version]
    assert_nil definition[:parent_version]
  end
  
  def test_create_content_id_on_versionable_table
    definition = nil
    ActiveRecord::Base.connection.create_table(:test, :versionable => true, :force => true){|table| definition=table}
    ActiveRecord::Base.connection.drop_table(:test)
    assert_not_nil definition[:content_id]
  end
  
end
