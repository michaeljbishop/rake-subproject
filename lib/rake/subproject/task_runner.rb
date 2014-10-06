require 'json'
module Rake::Subproject
  class TaskRunner
    attr_reader :directory

    include FileUtils
    include Rake::Subproject::Client
    
    def initialize(directory)
      @directory = directory
      @@rake_env ||= ARGV.each_with_object({}) do |arg, hash|
        hash[$1] = $2 if arg =~ /^(\w+)=(.*)$/m
      end
      
      child_socket, parent_socket  = Socket.pair(:UNIX, :STREAM, 0)
      port = Port.new(parent_socket, "client")
      @session_manager = SessionManager.new(port)
      thread = Thread.new { @session_manager.start } 
      
      at_exit do
        @session_manager.close
        port.close
        thread.join
      end

      rake_args = [
          "bundle", "exec", "--keep-file-descriptors",
          "rake",
            # Do not search parent directories for the Rakefile.
          "--no-search",
            # Include LIBDIR in the search path for required modules.
          "--libdir", File.dirname(__FILE__)+ "/server",
            # Require MODULE before executing rakefile.
          "-r", "task", "subproject:server:start[#{child_socket.fileno}]",
          {child_socket.fileno => child_socket, :chdir => @directory}
      ]

      Bundler.with_clean_env do
        @server_pid = Process.spawn(*rake_args)
      end

      # In case the rake subprocess failed (perhaps an incorrect rakefile)
      # output a message and exit.
      Signal.trap('CHLD') do
        $stderr.print "Subproject process died. Here's the invocation:\n" + rake_args.join(" ") + "\n"
        exit
      end

      ['TERM', 'KILL', 'INT'].each do |sig|
        Signal.trap(sig) do
          # If we are the ones killing the process, do not output a message
          Signal.trap('CHLD', 'IGNORE')
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
