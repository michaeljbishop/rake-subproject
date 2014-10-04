module Rake::Subproject::Remote
  class SessionManager

    def initialize(port)
      fail ArgumentError, "Requires a Port object" unless port.kind_of?(Rake::Subproject::Remote::Port)
      @port = port
      @session_queues = {}
    end
    
    def self.with_each_session(port, &block)
      return unless block_given?
      session_manager = self.new(port)
      threads = Set.new
      mutex = Mutex.new
      session_manager.start do |session|
        mutex.synchronize do
          threads << thread = Thread.start do
            block.call(session)
            mutex.synchronize { threads.delete thread }
          end
        end
      end
    ensure
      log "Waiting for #{threads.count} threads"
      mutex.synchronize { threads.dup }.each(&:join)
      session_manager.close
    end
    
    def start(&block)
      log "starting read loop on #{@port.inspect}"
      loop do
        envelope = @port.read
        fail "no 'message' tag in envelope" if (message = envelope['message']).nil?
        fail "no 'session_id' tag in envelope"  if (session_id = envelope['session_id']).nil? || session_id == "0"
        session_id = session_id.to_i
        fail "null(0) 'session_id' tag in envelope" if session_id == 0

        case message
        when 'create_session'
          session = Session.new(self, session_id.to_i)
          @session_queues[session.id] = Queue.new
          block.call(session) unless block.nil?
        when 'message_session'
          fail "No session for #{session_id.to_i}" if (queue = @session_queues[session_id.to_i]).nil?
          queue << envelope['payload']
        else
          fail "did not recognize message: '#{message}'"  if (session_id = envelope['session_id']).nil? || session_id == 0
        end
        
      end
    rescue EOFError => e
#       log "#{e.message}\n#{e.backtrace.join("\n")}"
    rescue IOError => e
#       log "#{e.message}\n#{e.backtrace.join("\n")}"
#       raise
    end
    
    def with_session
      return unless block_given?
      yield session = create_session
    ensure
      session.close
    end
    
    def create_session
      session = Session.send(:new, self)
      @port.write(message: 'create_session', session_id: session.id)
      @session_queues[session.id] = Queue.new
      session
    end
    
    def close
      log "session manager: closing #{@port.inspect}"
    end

    private
        
    def close_session(session)
      log "closing session: #{session.id} on #{@port.inspect}"
      @session_queues.delete(session.id)
    end
    
    def read_session(session)
      fail "No queue for #{session.inspect}" if (queue = @session_queues[session.id]).nil?
      fail EOFError if queue.empty? && @port.closed?
      queue.pop
    end
    
    def write_session(session, object)
      @port.write(message: 'message_session', session_id: session.id, payload: object)
    end
    
    private
    def log(message)
      $stderr.print "#{message}\n" if false
    end
  end

end

