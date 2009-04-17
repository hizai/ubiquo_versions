require File.dirname(__FILE__) + "/../test_helper.rb"

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
end
