module Rake
  class Application #:nodoc: all
    prepend Subproject::TaskManager
  end
end
