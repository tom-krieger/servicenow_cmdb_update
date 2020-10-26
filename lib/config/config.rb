##
# The configuration class.
# Make configuration available and load the configuration from file.
#
# For the available configurations please look into the config.yaml.tmpl file.
#
# @author Thomas Krieger
class Config

  # @!attribute
  # The whole config
  attr_reader :config

  # @!attribute
  # The Puppetdb part of the config.
  attr_reader :puppetdb

  # @!attribute
  # The ServiceNOW part of the config.
  attr_reader :servicenoe

  # @!attribute
  # The syslog part of the config.
  attr_reader :syslog

  ##
  # The constructor, loading the configuration from the configuration file.
  def initialize()
    @config     = YAML.load_file('config.yaml')
    @puppetdb   = @config['puppetdb']
    @servicenow = @config['servicenoe']
    @syslog     = @config['syslog']
  end

end