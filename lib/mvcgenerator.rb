require "mvcgenerator/version"
require "thor"

module Mvcgenerator
  
  class Mvc < Thor
    
    desc "fetch <repository> [<refspec>...]", "Download objects and refs from another repository"
    options :all => :boolean, :multiple => :boolean
    option :append, :type => :boolean, :aliases => :a
    def fetch(respository, *refspec)
      # implement git fetch here
    end
 
    desc "生成play framework的mvc代码"
    subcommand "play", Play
    
    desc "生成Kohana的mvc代码"
    subcommand "kohana", Kohana
    
  end
  
end
