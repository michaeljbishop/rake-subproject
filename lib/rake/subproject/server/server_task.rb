$stderr.puts "loading..."

require 'rake'
require 'json'

module Rake::Subproject::Server ; end
ENCLOSINGMODULE = Rake::Subproject::Server
Dir["#{File.dirname(__FILE__)}/../_network/*.rb"].each {|rb| require rb }

Rake::Task.define_task(:'subproject:server:start', [:fd]) do |t, args|
  include Rake::Subproject::Server
  Port.open(args[:fd].to_i, 'r+') do |port|

    def log(message)
      $stderr.print "#{message}\n" if false
    end

    port.name = "server"
    log "Starting server on #{port.inspect}\n"

    SessionManager.with_each_session(port) do |session|

      log "Received session"
      request = session.read
      message = request['message']

      log "Got message: '#{message}'"
      next unless message == 'invoke_task'

      task_name = request['name']
      log "Got task name: '#{task_name}'"

      task_args = request['args']

      log "Got task args: '#{task_args}'"

      begin
        log "Executing task #{task_name}"
        Rake::Task[task_name].invoke(*task_args['array'])
        log "#{task_name} complete!"
        session.write(message: 'task_complete')
      rescue RuntimeError => e
        session.write(message: 'task_failed', exception:{message: e.message, backtrace: e.backtrace})
      ensure
        session.close
      end
    end
  end
end

$stderr.puts "...loaded"
