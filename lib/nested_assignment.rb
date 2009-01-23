# NestedAssignment
module NestedAssignment
  include RecursionControl

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      
      [
        :valid_keys_for_has_many_association,
        :valid_keys_for_has_one_association,
        :valid_keys_for_belongs_to_association,
        :valid_keys_for_has_and_belongs_to_many_association 
      ].each do |method|
        send("#{method}=".to_sym, send(method) << :accessible)
      end

      class << self
        alias_method_chain :has_many, :accessible
        alias_method_chain :has_one, :accessible
        alias_method_chain :belongs_to, :accessible
        alias_method_chain :has_and_belongs_to_many, :accessible
      end

      alias_method_chain :create_or_update, :associated
      alias_method_chain :valid?, :associated
      alias_method_chain :changed?, :associated
    end
  end

  module ClassMethods
    def has_many_with_accessible(association_id, options = {}, &extension)
      has_many_without_accessible(association_id, options, &extension)
      multiple_associated_params_writer_method(association_id) if options[:accessible]
    end

    def has_one_with_accessible(association_id, options = {})
      has_one_without_accessible(association_id, options)
      single_associated_params_writer_method(association_id) if options[:accessible]
    end

    def belongs_to_with_accessible(association_id, options = {})
      belongs_to_without_accessible(association_id, options)
      single_associated_params_writer_method(association_id) if options[:accessible]
    end

    def has_and_belongs_to_many_with_accessible(association_id, options = {}, &extension)
      has_and_belongs_to_many_without_accessible(association_id, options, &extension)
      multiple_associated_params_writer_method(association_id) if options[:accessible]
    end

    def association_names
      @association_names ||= reflect_on_all_associations.map(&:name)
    end

    def reflect_on_accessible_associations(macro = nil)
      reflect_on_all_associations(macro).select { |reflection| reflection.options[:accessible] }
    end

    private
      def single_associated_params_writer_method(association_name)
        method_name = "#{association_name}_params=".to_sym
        define_method(method_name) do |attrs|
          assoc = self.send(association_name.to_sym)
          
          if attrs[:_delete].to_s == "1"
            [assoc].detect { |a| a.id == attrs[:id].to_i }._delete = true if attrs[:id]
          else
            record = attrs[:id].blank? ? assoc.build : [assoc].detect { |a| a.id == attrs[:id].to_i }
            record.attributes = attrs.except(:id, :_delete)
          end
        end
      end

      def multiple_associated_params_writer_method(association_name)
        method_name = "#{association_name}_params=".to_sym
        define_method(method_name) do |hash|
          assocs = self.send(association_name.to_sym)
          
          hash.values.each do |attrs|
            if attrs[:_delete].to_s == "1"
              assocs.detect { |a| a.id == attrs[:id].to_i }._delete = true if attrs[:id]
            else
              record = attrs[:id].blank? ? assocs.build : assocs.detect { |a| a.id == attrs[:id].to_i }
              record.attributes = attrs.except(:id, :_delete)
            end
          end
        end
      end
  end
  
  # marks the (associated) record to be deleted in the next deep save
  attr_accessor :_delete
  
  # deep validation of any changed (existing) records.
  # makes sure that any single invalid record will not halt the
  # validation process, so that all errors will be available
  # afterwards.
  def valid_with_associated?(*args)
    without_recursion(:valid?) do
      [ modified_associated.all?(&:valid?), valid_without_associated?(*args) ].all?
    end
  end
  
  # deep saving of any new, changed, or deleted records.
  def create_or_update_with_associated(*args)
    without_recursion(:create_or_update) do
      self.class.transaction do
        create_or_update_without_associated(*args) &&
        modified_associated.all? { |a| a.save(*args) } &&
        deletable_associated.all? { |a| a.destroy }
      end
    end
  end
  
  # Without this, we may not save deeply nested and changed records.
  # For example, suppose that User -> Task -> Tags, and that we change
  # an attribute on a tag but not on the task. Then when we are saving
  # the user, we would want to say that the task had changed so we
  # could then recurse and discover that the tag had changed.
  #
  # Unfortunately, this can also have a 2x performance penalty. 
  def changed_with_associated?
    without_recursion(:changed) do
      changed_without_associated? or changed_associated
    end
  end
  
  protected
    def deletable_associated
      instantiated_associated.select { |a| a._delete }
    end

    def modified_associated
      instantiated_associated.select { |a| a.changed? and !a.new_record? and not a.id_changed? }
    end

    def changed_associated
      instantiated_associated.select { |a| a.changed? }
    end

    def instantiated_associated
      instantiated = []
      self.class.association_names.each do |name|
        ivar = "@#{name}"
        if association = instance_variable_get(ivar)
          if association.target.is_a?(Array)
            instantiated.concat(association.target)
          elsif association.target
            instantiated << association.target
          end
        end
      end
      instantiated
    end
end
