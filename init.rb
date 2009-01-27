ActiveRecord::Base.class_eval do
  include NestedAssignment
end

ActionView::Helpers::FormBuilder.class_eval do
  include NestedAssignment::FormBuilder::NestedParamsSupport
end
