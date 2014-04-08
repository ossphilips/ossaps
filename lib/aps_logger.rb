require 'logger'

class ApsLogger
  attr_accessor :logger
  def initialize log_file
    @@logger = Logger.new log_file
  end

  def self.log level, message
    raise 'ApsLogger should be initialized with logfile before it can be used' unless @@logger
    @@logger.send(level, message) if [:warn, :error, :fatal].include?(level) || ENV['VERBOSE']
    $stdout.puts message if level == :fatal || ENV['VERBOSE']
    raise message if level == :fatal
  end
end
