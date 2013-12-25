require "thor"

module Mvcgenerator
  module PlayGenerator
    
    class Generator < Thor::Group
      include Thor::Actions
      
      def self.source_root
          File.dirname(__FILE__)
      end 
      

      def exist_play_project

        if(!File.exist?(File.expand_path("conf/application.conf")))
          puts "Can't auto generate code without in  the directory of play project's root directory, please change to a play project 's root directory first.\n"
          raise Error, "This command must be run in a play project's root direcotry!!"
        end
      end
      
    end
    
    class Pojo < Generator
      
        argument :name
        argument :fields, type: :array, :required => true, banner: "fieldName:fieldType"
    
        class_option :super, default: nil
        class_option :package, default: nil
      
      def create_pojo
        path = "#{name.capitalize}ViewModel.java"
        path = options[:package].gsub(/\./, "/") + "/" + path if options[:package]
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
        path = options[:package] ? options[:package].gsub(/\./, "/") + path : "controllers/" + path;
        template('templates/play/controller.erb', 'app/'+ path)
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
            
            action = "#{name.capitalize}Controller." + actionName + "("
            action =  (options[:package] ?  options[:package] : "controllers") + "." + action
            
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
        template('templates/play/view.erb', 'app/views/'+ path) 
      end
    end
    
    
    class Scoffold < Generator
      
      argument :name
      argument :fields, type: :array, :required => true, banner: "fieldName:fieldType"
      
      class_option :super, default: nil
      class_option :package, default: nil
      
      class_option :skipjs, type: :boolean, default: true
      class_option :skipcss, type: :boolean, default: true
      
      def create_model
        
        insert_into_file "conf/application.conf", "\nebean.default=\"models.*\"", :after => /^#\s*ebean.default="models.\*"$/
        
        #insert_into_file "conf/application.conf", :after => "/# ebean.default=\"models.*\"\n/" do
          
        #end
        
        path = "#{name.capitalize}.java"
        path = options[:package].gsub(/\./, "/") + "/" + path if options[:package]
        template('templates/play/scoffold/model.erb', 'app/models/'+ path)
      end 
      
      
      
      def create_controller
        
        ### add model
        #invoke Pojo, [name] + fields , {:package => options[:package], :super => options[:super]}
        
        id_field = nil
        fields.each do |field|
        ps = field.split(":")
        id_field = ps if ps.length > 2 && ps[2] == "Id"
        end
        
        path = "#{name.capitalize}Controller.java"
        path = package_to_directory + path if options[:package]
         
        template('templates/play/scoffold/controller.erb', 'app/controllers/'+ path)
        
        #add route
        controller = "#{name.capitalize}Controller"
        controller = options[:package] + "." + controller if options[:package]
        
        routes = []
        routes.push("GET      /#{name.capitalize}                         controllers.#{controller}.index(pageIndex: Integer ?= 0, pageSize: Integer ?= 10)" )
        routes.push("GET      /#{name.capitalize}/new                     controllers.#{controller}.create()")
        routes.push("GET      /#{name.capitalize}/update/:#{id_field[0]}  controllers.#{controller}.update(#{id_field[0]}: #{Play.getPackType(id_field[1])})")
        routes.push("POST     /#{name.capitalize}/save                    controllers.#{controller}.save()")
        routes.push("GET      /#{name.capitalize}/:#{id_field[0]}         controllers.#{controller}.show(#{id_field[0]}: #{Play.getPackType(id_field[1])})")
        routes.push("GET      /#{name.capitalize}/delete/:#{id_field[0]}  controllers.#{controller}.delete(#{id_field[0]}: #{Play.getPackType(id_field[1])})")
        
        append_to_file "conf/routes", "\n##{name.capitalize}\n" +routes.join("\n")
        
        if !options[:skipjs]
          create_file "app/assets/javascripts/#{package_to_directory}#{name}/index.coffee"
          create_file "app/assets/javascripts/#{package_to_directory}#{name}/form.coffee"
          create_file "app/assets/javascripts/#{package_to_directory}#{name}/show.coffee"
        end
        
        if !options[:skipcss]
          create_file "app/assets/stylesheets/#{package_to_directory}#{name}/index.less"
          create_file "app/assets/stylesheets/#{package_to_directory}#{name}/form.less"
          create_file "app/assets/stylesheets/#{package_to_directory}#{name}/show.less"
        end
      
      end
      
      def create_view
        
        path = "#{package_to_directory}#{name}/"
        template('templates/play/scoffold/views/form.erb', 'app/views/'+ path + "/form.scala.html")
        template('templates/play/scoffold/views/index.erb', 'app/views/'+ path + "/index.scala.html")
        template('templates/play/scoffold/views/show.erb', 'app/views/'+ path + "/show.scala.html")

      end
      
      def create_helper
        
        #helper = "#{name.capitalize}Helper.java"
        #helper = package_to_directory + helper if options[:package]
        
        #template('templates/play/scoffold/helper.erb', 'app/helpers/'+ helper)
        
      end
      
      private
      def package_to_directory
        options[:package] ? dir = options[:package].gsub(/\./, "/") + "/" : "" 
      end
      
    end
    
    class Init < Generator
      
      def initLayout
        
        directory "templates/play/scoffold/views/layouts", "app/views/layouts/"
        
        filenames = Dir.glob("app/views/layouts/*.erb")
        filenames.each do |filename|
          File.rename(filename, filename[0..-5]+".scala.html")
        end
      end
      
      def installBootstrap3
        puts "\t\tcopy css and js"
        directory "templates/play/public", "public/"
        
        puts "\t\tinstall bootstrap3 into public"
        directory "templates/bootstrap", "public/bootstrap/"  
      end

    end
   
    class Play < Thor
      
      register(Pojo, 'pojo', 'pojo is comming', 'make pojo file')
      register(Controller, 'controller', 'controller is comming', 'make controller file')
      register(View, 'view', 'view is comming', 'make view file')
      
      register(Scoffold, 'scoffold', 'view is comming', 'make view file')
      
      register(Init, 'init', 'initlayout', 'initlayout')
      
      def self.getPackType(type)
      
        type_hash = {
          'char'       => 'Character',
          'byte'       => 'Byte',
          'short'      => 'Short',
          'int'        => 'Integer', 
          'long'       => 'Long', 
          'float'      => 'Float', 
          'double'     => 'Double',
          'boolean'    => 'Boolean',
          'string'     => 'String'
          }

        return type_hash[type] if(type_hash.has_key? type)
        type

      end
    end
  end
  
end

Mvcgenerator::PlayGenerator::Play.start(ARGV)