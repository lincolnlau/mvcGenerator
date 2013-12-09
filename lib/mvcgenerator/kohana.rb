module Mvcgenerator
  module KohanaGenerator
    class Kohana < Thor::Group
      include Thor::Actions
    end
    
    class ViewModel < Thor::Group
      include Thor::Actions
    end
    
    class Controller < Thor::Group
      include Thor::Actions
    end
    
    class View < Thor::Group
      include Thor::Actions
    end
    
    
    class Scoffold < Thor::Group
      include Thor::Actions
    end
    
  end
end