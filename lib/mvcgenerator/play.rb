module Mvcgenerator
  module PlayGenerator
    class Play < Thor
    end
    
    class Pojo < Thor::Group
      include Thor::Actions
      
      argument :name
      argument :fields, type: :array, :required => true, banner: "fieldName:fieldType"
    
      class_option :super, default: nil
      class_option :package, default: nil
      
      def create(name, *properties)
              
      end
    end
    
    class Controller < Thor::Group
      include Thor::Actions
      
      argument :name
      argument :actions, type: :array, :required => true, banner: "actionName,method,[parameterName:parameterType]*,[viewParameterName:viewParameterType]*"
      
      class_option :skipview, type: :boolean, default: false
      class_option :super, default: nil
      class_option :package, default: nil
      
      def create(name, *actions)
          
      end
      
    end
    
    class View < Thor::Group
      include Thor::Actions
      
      argument :name
      argument :actions, type: :array, default:nil, banner: "parameterName:parameterType"
      
      def create(name, *parameters)
          
      end
    end
    
    
    class Scoffold < Thor::Group
      include Thor::Actions
      
      def create_viewmodel
        
      end
      
      def create_helper
        
      end
      
      def create_controller
        
      end
      
      def create_view
        
      end
      
      def create_route
        
      end
    end
  end
  
end