require File.dirname(__FILE__) + "/../test_helper.rb"

class Ubiquo::VersionableTest < ActiveSupport::TestCase

  def setup
    set_test_model_as_versionable
    create_ar_test_backend
  end
  
  def test_should_set_model_as_versionable
    ar = create_ar
    options = {:max_amount => 3}
    ar.class_eval do
      versionable options
    end
    assert ar.instance_variable_get('@versionable')
    assert_equal options, ar.instance_variable_get('@versionable_options')
  end
  
  def test_should_add_content_id_on_create_if_empty
    assert_difference 'TestVersionableModel.count' do
      versionable = create_versionable_model
      assert_not_nil versionable.content_id
    end  
  end
  
  def test_should_not_add_content_id_on_create_if_exists
    assert_difference 'TestVersionableModel.count' do
      versionable = create_versionable_model(:content_id => 12)
      assert_equal 12, versionable.content_id
    end      
  end
  
  def test_should_add_version_if_new
    assert_difference 'TestVersionableModel.count' do
      versionable = create_versionable_model
      assert_not_nil versionable.version_number
      assert versionable.is_current_version
    end    
  end
  
  def test_should_create_version_on_update
    versionable = create_versionable_model(:content_id => 2)
    first_version = versionable.version_number
    assert_difference 'TestVersionableModel.count(:version => :all)' do
      assert_no_difference 'TestVersionableModel.count()' do
        versionable.update_attribute :content_id, 10
      end
    end
    new_version = TestVersionableModel.last(:version => :all)
    assert !new_version.is_current_version
    assert_equal first_version, new_version.version_number
    assert_equal 2, new_version.content_id
  end
  
  def test_should_get_versions
    versionable = create_versionable_model(:content_id => 2)
    assert_equal 0, versionable.versions.size
    versionable.update_attribute :content_id, 2
    assert_equal 1, versionable.versions.size
    versionable.update_attribute :content_id, 2
    assert_equal 2, versionable.versions.size
  end
  
  def test_should_update_existing_on_update
    versionable = create_versionable_model(:content_id => 2)
    first_version = versionable.version_number
    versionable.update_attribute :content_id, 10
    assert versionable.reload.version_number > first_version
    assert versionable.is_current_version
    assert_equal 10, versionable.content_id
  end
  
  def test_should_find_just_current_version_by_default
    versionable = create_versionable_model(:content_id => 2)
    versionable.update_attribute :content_id, 10
    assert_equal 1, TestVersionableModel.count
    assert_equal [versionable], TestVersionableModel.all
  end

  def test_should_find_all_versions_if_set
    versionable = create_versionable_model(:content_id => 2)
    versionable.update_attribute :content_id, 10
    new_version = TestVersionableModel.last(:version => :all)
    assert_equal 1, TestVersionableModel.count
    assert_equal 2, TestVersionableModel.count(:version => :all)
    assert_equal [versionable, new_version], TestVersionableModel.all(:version => :all)
  end

  def test_should_find_specific_version_if_set
    versionable = create_versionable_model(:content_id => 2)
    assert_nil TestVersionableModel.last(:version => 2)
    versionable.update_attribute :content_id, 10
    assert_not_nil TestVersionableModel.all(:version => 2)
    assert_equal 10, TestVersionableModel.last(:version => 2).content_id
  end

  def test_should_merge_find_conditions
    versionable = create_versionable_model(:content_id => 2)
    versionable.update_attribute :content_id, 10
    assert_equal [versionable], TestVersionableModel.all(:conditions => ["content_id = ?", 10], :version => :all)
  end

  private
    
  def create_ar(options = {})
    Class.new(ActiveRecord::Base)
  end
  
  def create_versionable_model(options = {})
    TestVersionableModel.create(options)
  end

  def create_ar_test_backend
    silence_stderr do
      # Creates a test table for AR things work properly
      if ActiveRecord::Base.connection.tables.include?("test_versionable_models")
        ActiveRecord::Base.connection.drop_table :test_versionable_models
      end
      ActiveRecord::Base.connection.create_table :test_versionable_models, :versionable => true do
      end
    end
  end
  
  def set_test_model_as_versionable
    TestVersionableModel.class_eval do
      versionable
    end
  end
end

# Model used to test Versionable extensions
TestVersionableModel = Class.new(ActiveRecord::Base)
  
