module PluginTestModels
  def self.included(base)
    base.set_fixture_class({
      :avatars => PluginTestModels::Avatar,
      :groups => PluginTestModels::Group,
      :managers => PluginTestModels::Manager,
      :tags => PluginTestModels::Tag,
      :tasks => PluginTestModels::Task,
      :users => PluginTestModels::User
    })
  end
  
  class User < ActiveRecord::Base
    has_one                 :avatar, :accessible => true
    belongs_to              :manager, :accessible => true
    has_many                :tasks, :accessible => true
    has_many                :tags, :through => :tasks, :accessible => true
    has_and_belongs_to_many :groups, :accessible => true
    
    validates_presence_of :name
  end
  
  class Avatar < ActiveRecord::Base
    belongs_to :user
    
    validates_presence_of :name
  end
  
  class Manager < ActiveRecord::Base
    has_many :users
  
    validates_presence_of :name
  end
  
  class Task < ActiveRecord::Base
    belongs_to :user
    has_many :tags
  
    validates_presence_of :name
  end
  
  class Tag < ActiveRecord::Base
    belongs_to :task
    
    validates_presence_of :name
  end
  
  class Group < ActiveRecord::Base
    has_and_belongs_to_many :users
    
    validates_presence_of :name
  end
  
  class Event < ActiveRecord::Base
    belongs_to :entity, :polymorphic => true
  end
end
