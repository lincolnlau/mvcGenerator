require "thor"

module Mvcgenerator
  module PlayGenerator
    
    class Generator < Thor::Group
      include Thor::Actions
      
      def self.source_root
          File.dirname(__FILE__)
      end 
      
=begin
      def exist_play_project

        if(!File.exist?(File.expand_path("conf/application.conf")))
          puts "Can't auto generate code without in  the directory of play project's root directory, please change to a play project 's root directory first.\n"
          raise Error, "This command must be run in a play project's root direcotry!!"
        end
      end
=end
      
    end
    
    class Pojo < Generator
      
        argument :name
        argument :fields, type: :array, :required => true, banner: "fieldName:fieldType"
    
        class_option :super, default: nil
        class_option :package, default: nil
      
      def create_pojo
        path = "#{name.capitalize}ViewModel.java"
        path = options[:package].gsub(/\./, "/") + path if options[:package]
        template('templates/play/pojo.erb', 'app/models/'+ path)
      end
    end
    
    class Controller < Generator
      
      argument :name
      argument :actions, type: :array, default: [], banner: "actionName,method,[parameterName:parameterType,],,[viewParameterName:viewParameterType,]*"
      
      class_option :skipview, type: :boolean, default: false
      class_option :super, default: nil
      class_option :package, default: nil
      
      def create_controller
        path = "#{name.capitalize}Controller.java"
        path = options[:package].gsub(/\./, "/") + path if options[:package]
        template('templates/play/controller.erb', 'app/controllers/'+ path)
      end
      
      def add_route
        if(actions.length > 0)
          routes = ["\n# #{name}"]
          actions.each do |a|
            p_array = []
            ap = a.split(',,')
            
            first = ap.first.split(',')
            
            actionName = first.shift
            http_method = first.shift
            
            input_parameters = first
            
            #action = packgePath("controllers") + "." + name.capitalize + 'Controller.' +  actionName + "("
            
            action = "#{name.capitalize}Controller." + actionName + "("
            action = "controllers." + options[:package] + "." + action if options[:package]
            
            action += input_parameters.join(", ").gsub(/(\:)(\w)+/){|s| Play.getPackType(s) } if input_parameters.length > 0
            
            action += ")"
    
            route = "/" + name+"/" + actionName
            route = "/" + options[:package].gsub(/\./, "\/") + "/" + name + "/" +actionName if(options[:package])
            routes.push("GET     #{route}         #{action}")
          end
          append_to_file "conf/routes", routes.join("\n");
        end
      end
      
      def add_view
        if !options[:skipview]
          actions.each do |action|
            arr = []
            ap = action.split(",,")
            name = ap[0].split(",").first
            name = options[:package].gsub(/\./, "_") + "_" + name if options[:package]
            #puts action.split(",,")
            arr.push name
            arr = [name] + ap[1].split(",") if ap.length > 1

            invoke View, arr, :package => options[:package]
          end
        end
      end
    end
    
    class View < Generator
      
      argument :name
      argument :parameters, type: :array, default: [], banner: "parameterName:parameterType"
      
      class_option :package, default: nil
      
      def create_view
        path = "views/#{name}.scala.html"
        path = options[:package].gsub(/\./, "/") + path if options[:package]
        template('templates/play/view.erb', 'app/'+ path)  
      end
    end
    
    
    class Scoffold < Generator
      
      argument :name
      argument :fields, type: :array, :required => true, banner: "fieldName:fieldType"
      
      class_option :super, default: nil
      class_option :package, default: nil
       
      
      def create_controller
        
        ### add model
        invoke Pojo, [name] + fields , {:package => options[:package], :super => options[:super]}
        
        path = "#{name.capitalize}Controller.java"
        path = options[:package].gsub(/\./, "/") + path if options[:package]
        template('templates/play/scoffold/controller.erb', 'app/controllers/'+ path)
        
        #add route
        controller = "#{name.capitalize}Controller"
        controller = options[:package].gsub(/\./, "/") + controller if options[:package]
        
        routes = []
        routes.push("GET      /#{name.capitalize}                 controllers.#{controller}.index(pageIndex: Integer ?= 0, pageSize: Integer ?= 10)" )
        routes.push("GET      /#{name.capitalize}/:pageIndex      controllers.#{controller}.index(pageIndex: Integer, pageSize: Integer ?= 10)" )
        routes.push("GET      /#{name.capitalize}/new             controllers.#{controller}.create()")
        routes.push("GET      /#{name.capitalize}/update/:id      controllers.#{controller}.update(id: Integer)")
        routes.push("POST     /#{name.capitalize}/save            controllers.#{controller}.save()")
        routes.push("GET      /#{name.capitalize}/:id             controllers.#{controller}.show(id: Integer)")
        routes.push("GET      /#{name.capitalize}/delete/:id      controllers.#{controller}.delete(id: Integer)")
        
        append_to_file "conf/routes", "\n##{name.capitalize}\n" +routes.join("\n")
      
      end
      
      def create_view
        
        path = "#{name}/views/"
        path = options[:package].gsub(/\./, "/") + path if options[:package]
        template('templates/play/scoffold/views/form.erb', 'app/'+ path + "/form.scala.html")
        template('templates/play/scoffold/views/index.erb', 'app/'+ path + "/index.scala.html")
        template('templates/play/scoffold/views/show.erb', 'app/'+ path + "/show.scala.html")

      end
      
      def create_helper
        
        helper = "#{name.capitalize}Helper.java"
        helper = options[:package].gsub(/\./, "/") + controller if options[:package]
        
        template('templates/play/scoffold/helper.erb', 'app/helpers/'+ helper)
        
      end
      
      
    end
=begin    
    class Sub < Thor
      desc "sub", "command"
      def command
        puts "sub command"
      end
    end
=end    
    class Play < Thor
      
      register(Pojo, 'pojo', 'pojo is comming', 'make pojo file')
      register(Controller, 'controller', 'controller is comming', 'make controller file')
      register(View, 'view', 'view is comming', 'make view file')
      
      register(Scoffold, 'scoffold', 'view is comming', 'make view file')
      
      #desc "remote SUBCOMMAND ...ARGS", "manage set of tracked repositories"
      #subcommand "sub", Sub
      
      def self.getPackType(type)
      
        type_hash = {
          'char'       => 'Character',
          'byte'       => 'Byte',
          'short'      => 'Short',
          'int'        => 'Integer', 
          'long'       => 'Long', 
          'float'      => 'Float', 
          'double'     => 'Double',
          'boolean'    => 'Boolean'
          }

        return type_hash[type] if(type_hash.has_key? type)
        type

      end
    end
  end
  
end

Mvcgenerator::PlayGenerator::Play.start(ARGV)