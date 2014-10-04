require 'rake'
require_relative 'port'
require_relative 'session'
require_relative 'session_manager'

private
def log(message)
  $stderr.print "#{message}\n" if false
end

task :'subproject:server:start', [:fd] do |t, args|
  Rake::Subproject::Remote::Port.open(args[:fd].to_i, 'r+') do |port|

    port.name = "server"
    log "Starting server on #{port.inspect}\n"

    Rake::Subproject::Remote::SessionManager.with_each_session(port) do |session|
      log "Received session"
      request = session.read
      message = request['message']

      log "Got message: '#{message}'"
      next unless message == 'invoke_task'

      task_name = request['name']
      log "Got task name: '#{task_name}'"

      task_args = request['args']

      log "Got task args: '#{task_args}'"

      log "Executing task #{task_name}"
      Rake::Task[task_name].invoke(*task_args['array'])
      log "#{task_name} complete!"

      session.write(message: 'task_complete')
      session.close
    end
  end
end
