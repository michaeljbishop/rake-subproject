
module Rake::Subproject::Remote
  class Session
    def initialize(manager, id = nil)
      @id = id
      @manager = manager
    end
    
    def id
      @id || object_id
    end
    
    def write(object)
      @manager.send(:write_session, self, object)
    end

    def read
      @manager.send(:read_session, self)
    end
    
    def close
      @manager.send(:close_session, self)
    end
  end
end
