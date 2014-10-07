module Rake::Subproject
  module TaskManager #:nodoc: all

    def define_subproject(path)
      raise "Subproject path '#{path}' does not exist" unless File.exist?(path)

      directory = File.directory?(path) ? path : File.dirname(path)

      return if runners[path]
      runners[directory] = Rake::Subproject::TaskRunner.new(path)
    end

    def [](task_name, scopes=nil)
      self.lookup(task_name, scopes) or 
      runners.each do |dir, subproject|
        task_name.match /^#{dir}[\/\:](.*)/ do |md|
        # Here, we need a remote task class that can receive the 
          return Rake::Task.define_task task_name do |t, args|
            subproject.invoke_task(md[1], args)
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
