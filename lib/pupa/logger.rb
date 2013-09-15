require 'logger'

require 'colored'

module Pupa
  # A logger factory.
  class Logger
    # Returns a configured logger.
    #
    # @param [String] progname the name of the program performing the logging
    # @param [String] level the log level, one of "DEBUG", "INFO", "WARN",
    #   "ERROR", "FATAL" or "UNKNOWN"
    # @param [String,IO] logdev the log device
    # @return [Logger] a configured logger
    def self.new(progname, level: 'INFO', logdev: STDOUT)
      logger = ::Logger.new(logdev)
      logger.level = ::Logger.const_get(level)
      logger.progname = progname
      logger.formatter = proc do |severity, datetime, progname, msg|
        message = "#{datetime.strftime('%T')} #{severity} #{progname}: #{msg}\n"
        case severity
        when 'DEBUG'
          message.magenta
        when 'INFO'
          message.white
        when 'WARN'
          message.yellow
        when 'ERROR'
          message.red
        when 'FATAL'
          message.bold.red_on_white
        end
      end
      logger
    end
  end
end
