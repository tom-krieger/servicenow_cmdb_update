##
# Class PuppetDbNode.
# Methods around the PuppetDB and how to get information for nodes from PuppetDB
#
# @author Thomas Krieger
class PuppetDbNode

  # @!attribute
  # The name of the node
  attr_accessor :certname

  # @!attribute
  # The environment the node is running.
  attr_accessor :environment

  # @!attribute
  # URL of PuppetDB
  attr_reader :puppet_db_url

  # @!attribute
  # The facts for the node
  attr_reader :facts

  # @!attribute
  # The logger object
  # @!visibility private
  attr_reader :logger


  ##
  # Constructor
  #
  # @param certname [String] The fqdn of the node.
  def initialize(certname, logger: nil)
    conf_obj       = Config.new()
    @puppet_db_url = conf_obj.config['puppetdb']['url']
    @certname      = certname
    @logger        = logger

    unless @certname.nil?
      get_facts_for_node
    end
  end


  ##
  # Get all facts as hash for a node.
  # Set the facts as´´tribute.
  def get_facts_for_node
    url              = "#{@puppet_db_url}/facts"
    request_body_map = {
        query: ["=", "certname", "#{@certname}"],
    }
    begin
      response = RestClient.post(url,
                                 request_body_map.to_json, # Encode the entire body as JSON
                                 content_type: 'application/json',
                                 accept:       'application/json',
                                 timeout:      120)
    rescue RestClient::ExceptionWithResponse => e
      e.response
      @logger.err(e.response) unless @logger.nil?
    end

    @facts = {}

    if response
      response_data = JSON.parse(response)
      @facts        = response_data
    elsif e.response
      pp e.response
      @logger.err(e.response) unless @logger.nil?
    end

  end

end