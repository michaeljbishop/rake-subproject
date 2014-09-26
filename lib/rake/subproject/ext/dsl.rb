module Rake::DSL
  def subproject(path)
    Rake.application.define_subproject(path)
  end
end
