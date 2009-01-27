# Taken from pkondzior's fork, http://github.com/pkondzior/nested_assignment/tree/master
module NestedAssignment
  module FormBuilder
    module NestedParamsSupport
      def self.included(base)
        base.class_eval do
          alias_method_chain :fields_for, :nested_params_support
        end
      end

      def fields_for_with_nested_params_support(association_name_or_record_or_name_or_array, *args, &block)
        if association_reflection = accessible_association_reflection(association_name_or_record_or_name_or_array)
          return fields_for_nested_params(association_reflection, args, block)
        else
          return fields_for_without_nested_params_support(association_name_or_record_or_name_or_array, *args, &block)
        end
      end
      
      protected
        def accessible_association_reflection(association_name)
          if association_name
            klass = @object.class
            if klass.respond_to?(:reflect_on_accessible_associations)
              klass.reflect_on_accessible_associations.find { |ref| ref.name == association_name.to_sym }
            end
          end
        end

        def fields_for_nested_params(reflection, args, block)
          name = "#{object_name}[#{reflection.name}_params]"
          case reflection.macro
          when :has_one, :belongs_to
            @template.fields_for(name, @object.send(reflection.name), *args, &block)
          when :has_many, :has_and_belongs_to_many
            records = args.first.respond_to?(:new_record?) ? [args.first] : @object.send(reflection.name)
            records.map do |record|
              record_name = "#{name}[#{ record.new_record? ? (record.object_id * -1) : record.id }]"
              @template.fields_for(record_name, record, *args) do |form_builder|
                block.arity == 2 ? block.call(form_builder, record) : block.call(form_builder)
              end
            end.join
          end
        end
    end
  end
end
