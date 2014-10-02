require 'json'
module Rake::Subproject
  class TaskRunner
    attr_reader :directory

    include FileUtils

    def initialize(directory)
      @directory = directory
      @mutex = Mutex.new
      
      @@rake_env ||= ARGV.each_with_object({}) do |arg, hash|
        hash[$1] = $2 if arg =~ /^(\w+)=(.*)$/m
      end
      
      child_socket, @parent_socket  = Socket.pair(:UNIX, :STREAM, 0)
      
      Bundler.with_clean_env do
        @server_pid = Process.spawn(
          "bundle", "exec", "--keep-file-descriptors",
          "rake",
            # Do not search parent directories for the Rakefile.
          "--no-search",
            # Include LIBDIR in the search path for required modules.
          "--libdir", File.dirname(__FILE__),
            # Require MODULE before executing rakefile.
          "-r", "daemon/task", "subproject:server:start[#{child_socket.fileno}]",
          {child_socket.fileno => child_socket, :chdir => @directory})
      end
      child_socket.close
      
      at_exit do
        @parent_socket.close
        Process.wait @server_pid
      end
    end
    
    def invoke_task(name, *args)
    
      @parent_socket.puts ::JSON.generate(message: 'invoke_task', name: name, args: args)
      command_hash = JSON.parse(@parent_socket.readline)
      message   = command_hash['message']
      fail "returned message was not ACK (was #{message})" unless message == 'invoke_task_ack'
      
      task_invocation_id = command_hash['uuid']

      command_hash = JSON.parse(@parent_socket.readline)
      message   = command_hash['message']
      fail "returned message was not invoke_task_complete (was #{message})" unless message == 'invoke_task_complete'
      uuid = command_hash['uuid']
      fail "returned uuid was not #{task_invocation_id} (was #{uuid})" unless uuid == task_invocation_id
    end
  end
end
