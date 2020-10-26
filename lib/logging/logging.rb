##
# Implement some syslog logging
#
# @author Thomas Krieger
class Logging

  # @!attribute
  # The syslog facility to log to.
  # @!visibility private
  attr_reader :facility

  # @!attribute
  # The logger object.
  # @!visibility private
  attr_reader :logger


  ##
  # The constructor.
  def initialize()
    @logger = Syslog::Logger.new('servicenow_cmdb_update', Syslog::LOG_DAEMON)
  end


  # Log with debug level.
  def debug(msg)
    @logger.debug msg
  end


  # Log with info level.
  def info(msg)
    @logger.info msg
  end


  # Log with warning level.
  def warn(msg)
    @logger.warn msg
  end


  # Log with error level.
  def err(msg)
    @logger.error msg
  end


end