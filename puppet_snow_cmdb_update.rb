$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

##
# Ruby code to demonstrate how to read all nodes from PuppetDB and create/update CMDB Servers in ServieNOW with content
# from PuppetDB. This code is intended to show how this can work. It uses custom fields in ServiceNOW which must not be
# available in your ServiceNOW instance.
#
# For PuppetDB access this Ruby code has to run on the puppet Master node or on a PuppetDB node.
#
# The code was written and was tested with Ruby 2.7.0.
#
# Class documentation can be found in the doc folder.
#

require 'optparse'
require 'yaml'
require 'ostruct'
require 'open-uri'
require 'json'
require 'base64'
require 'uri'
require 'rest-client'
require 'pp'
require 'syslog/logger'
require 'lib/puppetdb/puppet_db_node'
require 'lib/puppetdb/puppet_db_utils'
require 'lib/servicenow/cmdb_ci_computer'
require 'lib/config/config'
require 'lib/logging/logging'
require 'lib/exceptions/exceptions'

##
# main configurations
config = Config.new()
debug  = config.config['debug']
config.config['syslog']['log_to_syslog'] ? logger = Logging.new() : logger = nil
logger.info('starting cmdb update') unless logger.nil?
nodes = PuppetDbUtils.get_nodes()

##
# main loop
nodes.each do |node_data|

  node             = node_data[:certname]
  environment      = node_data[:environment]
  last_puppet_run  = node_data[:latest_report_status]
  report_timestamp = node_data[:report_timestamp]

  puts "Updating node #{node} in environment #{environment} (#{last_puppet_run}) " if debug
  logger.info("Updating node #{node} in environment #{environment} (#{last_puppet_run})") unless logger.nil?
  ci       = CmdbCiComputer.new(ci_name:               node, environment: environment, debug: debug,
                                last_puppet_run_state: last_puppet_run, last_puppet_report: report_timestamp,
                                logger:                logger)
  pdbnode  = PuppetDbNode.new(node, logger: logger)
  ci.facts = pdbnode.facts
  ci.update_cmdb_ci_from_facts
  puts "\n" if debug

end

logger.info('finished cmdb update') unless logger.nil?

exit 0
