require 'json'
module Rake::Subproject
  class TaskRunner #:nodoc: all
    attr_reader :directory

    include FileUtils
    include Rake::Subproject::Client
    
    def initialize(path)
      raise "Subproject path '#{path}' does not exist" unless File.exist?(path)
      if File.directory?(path)
        @directory = path
      else
        rakefile = path
        @directory = File.dirname(path)
      end

      @@rake_env ||= ARGV.each_with_object({}) do |arg, hash|
        hash[$1] = $2 if arg =~ /^(\w+)=(.*)$/m
      end
      
      child_socket, parent_socket  = Socket.pair(:UNIX, :STREAM, 0)
      port = Port.new(parent_socket, "client")
      @session_manager = SessionManager.new(port)
      thread = Thread.new { @session_manager.start } 
      
      ObjectSpace.define_finalizer(self) do
        @session_manager.close
        port.close
        thread.join
      end

      prefix = []
      rake_args = [
          "rake",
            # Do not search parent directories for the Rakefile.
          "--no-search",
            # Include LIBDIR in the search path for required modules.
          "--libdir", File.dirname(__FILE__)+ "/server",
            # Require MODULE before executing rakefile.
          "-r", "task", "subproject:server:start[#{child_socket.fileno}]",
          
      ]
      
      if File.exist? "#{@directory}/Gemfile"
        prefix = %W(bundle exec --keep-file-descriptors)
      end
      
      rake_args = prefix + rake_args + ['--rakefile', File.basename(rakefile)] unless rakefile.nil?
      rake_args << {child_socket.fileno => child_socket, :chdir => @directory}

      Bundler.with_clean_env do
        @server_pid = Process.spawn(*rake_args)
      end

      (Set.new(Signal.list.keys) & Set.new(['TERM', 'KILL', 'INT'])).each do |sig|
        Signal.trap(sig) do
          Process.kill(sig, @server_pid)
        end
      end
      
      child_socket.close
    end
    
    def invoke_task(name, args)
      log "TaskRunner#invoke_task: #{name} with #{args}"
      session = @session_manager.with_session do |session|
        session.write(message: 'invoke_task', name: name, args: {hash: args.to_hash, array: args.to_a})
        response = session.read
        if (response['message'] == 'task_failed')
          e = ::Rake::Subproject::Error.new(response['exception']['message'])
          e.set_backtrace(response['exception']['backtrace'] + Thread.current.backtrace)
          raise e
        end
      end
    end

    private
    def log(message)
      $stderr.print "#{message}\n" if false
    end
  end
end
