require "rake/subproject/version"

module Rake::Subproject
  module TaskManager

    def define_subproject(path)
      return if runners[path]
      runners[path] = Rake::Subproject::TaskRunner.new(path)
    end

    def [](task_name, scopes=nil)
      self.lookup(task_name, scopes) or 
      runners.each do |dir, subproject|
        task_name.match /^#{dir}[\/\:](.*)/ do |md|
          return Rake::Task.define_task task_name do |t|
            subproject.invoke_task(md[1])
          end
        end
      end
      super
    end

    private

    def runners
      @runners ||= {}
    end
  end
end
