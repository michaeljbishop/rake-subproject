require "rake/subproject/version"

module Rake::Subproject::TaskManager
  class RakeRunner
    include FileUtils

    def run(*args)
      ruby '-S', 'rake', *args
    end
  end

  def define_subproject(path)
    subprojects << path
  end

  def subprojects
    @subprojects ||= Set.new
  end

  def [](task_name, scopes=nil)
    self.lookup(task_name, scopes) or 
    subprojects.each do |subproject|
      task_name.match /^#{subproject}[\/\:](.*)/ do |md|
        return Rake::Task.define_task task_name do |t|
          RakeRunner.new.run md[1], {chdir: subproject}, {verbose: false}
        end
      end
    end
    super
  end
end
