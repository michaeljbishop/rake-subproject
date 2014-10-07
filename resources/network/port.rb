class Port #:nodoc: all
  attr_accessor :name

  def self.open(fd, option)
    return unless block_given?
    IO.open(fd, option) do |io|
      yield port = self.new(io, "server")
    end
  end

  DELIMITER = "\0"

  def initialize(io, name = nil)
    fail ArgumentError, "Requires an IO object" unless io.kind_of?(IO)
    @io = io
    self.name = name
  end
  
  def inspect
    "Port(#{self.name || @io.fileno})"
  end
  
  def read
    log "reading #{self.inspect}..."
    json_message = @io.readline(DELIMITER).chomp(DELIMITER)
    log "... #{self.inspect} received: #{json_message}"
    ::JSON.parse(json_message)
  end
  
  def write(object)
    json_message = ::JSON.generate(object)
    @io.print(json_message+DELIMITER)
    @io.flush
    log "#{self.inspect} wrote: #{json_message}"
  end
  
  def close
    log "closing #{self.inspect}"
    @io.close
  end
  
  def closed?
    @io.closed?
  end
  
  private
  def log(message)
    $stderr.print "#{message}\n" if false
  end
end
