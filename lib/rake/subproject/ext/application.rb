module Rake
  class Application
    prepend Subproject::TaskManager
  end
end
