require File.dirname(__FILE__) + '/../test_helper'

class NestedAssignmentReflectionsTest < ActiveSupport::TestCase
  def test_reflect_on_accessible_associations_returns_accessible_associations
    assert_equal(User.reflect_on_all_associations.size, User.reflect_on_accessible_associations.size)
  end

  def test_reflect_on_accessible_associations_limits_to_specified_macro
    assert_equal(2, User.reflect_on_accessible_associations(:has_many).size)
  end

  def test_reflect_on_accessible_associations_is_empty_when_no_accessible_associations
    assert(Avatar.reflect_on_accessible_associations.empty?)
  end
end
