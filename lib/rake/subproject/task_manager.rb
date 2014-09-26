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
    subproject_semaphores[path] ||= Mutex.new
  end

  def subprojects
    @subprojects ||= Set.new
  end

  def [](task_name, scopes=nil)
    self.lookup(task_name, scopes) or 
    subprojects.each do |subproject|
      task_name.match /^#{subproject}[\/\:](.*)/ do |md|
        return Rake::Task.define_task task_name do |t|
          subproject_semaphores[subproject].synchronize do
            RakeRunner.new.run md[1], {chdir: subproject}, {verbose: false}
          end
        end
      end
    end
    super
  end
  private

  def subproject_semaphores
    @subproject_semaphores ||= {}.extend(MonitorMixin)
  end
end
