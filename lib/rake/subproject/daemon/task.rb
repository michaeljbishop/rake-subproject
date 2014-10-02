require 'rake'
require 'json'
require 'securerandom'

task :'subproject:server:start', [:fd] do |t, args|
  fd = args[:fd].to_i
  stream = IO.open(fd, 'r+')
  begin
    loop do
      command_hash = JSON.parse(stream.readline)
      message   = command_hash['message']
      next unless message == 'invoke_task'

      id = SecureRandom.uuid
      stream.puts ::JSON.generate(message: 'invoke_task_ack', uuid: id)

      task_name = command_hash['name']
      task_args = command_hash['args']
      Rake::Task[task_name].invoke(*task_args)
      stream.puts ::JSON.generate(message: 'invoke_task_complete', uuid: id)
    end
  rescue EOFError
    stream.close
    exit
  end
end
