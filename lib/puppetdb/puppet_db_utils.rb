##
# Module PuppetDbUtils
# #
# Utility functions around the PuppetDB
#
# @author Thomas Krieger
module PuppetDbUtils

  ##
  # Get all nodes from the PuppetDB
  #
  # @return [Hash] nodes A hash containing all nodes.
  def self.get_nodes
    conf_obj      = Config.new()
    puppet_db_url = conf_obj.config['puppetdb']['url']
    node_url      = "#{puppet_db_url}/nodes"

    begin
      response = RestClient.get(node_url,
                                content_type: 'application/json',
                                accept:       'application/json',
                                timeout:      120)
    rescue RestClient::ExceptionWithResponse => e
      e.response
      response = nil
    end

    nodes = []

    if response
      response_data = JSON.parse(response)
      response_data.each do |entry|
        if entry['deactivated'].nil?
          environment = entry['catalog_environment']
          data        = {
              environment:          environment,
              certname:             entry['certname'],
              report_timestamp:     DateTime.parse(entry['report_timestamp']).strftime('%Y-%m-%d %H:%M:%S'),
              latest_report_status: entry['latest_report_status']
          }
          nodes.push(data)
        end
      end
    end

    nodes
  end
end