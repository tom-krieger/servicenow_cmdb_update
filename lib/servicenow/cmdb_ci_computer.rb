##
# Class to describe a ServieNOW computer ci
#
# The class has attributes to describe a ServiceNOW computer ci.
#
# This class is to show how filling ServiceNOW CMDB can be done. But it has to be customized to work with
# the CMDB you have in use. This imlementation uses three custom fields u_last_puppet_run, u_last_puppet_report,
# u_puppet_role to add some Puppet data to ServiceNOW.
#
# @author Thomas Krieger

class CmdbCiComputer

  # @!attribute
  # The ServiceNOW useranme
  # @!visibility private
  attr_reader :username

  # @!attribute password
  # The ServiceNOW password
  # @!visibility private
  attr_reader :password

  # @!attribute
  # The ServiceNOW base URL.
  # @!visibility private
  attr_reader :service_now_url

  # @!attribute
  # The internal list of used attributes. All attributes in this list must be available in this class and in ServiceNOW
  # cmdb server object.
  # @!visibility private
  attr_reader :attr_list

  # @!attribute
  # The sys_id for AVWare instances.
  # @!visibility private
  attr_reader :vmware_vm_id

  # @!attribute
  # Debug flag.
  # @!visibility private
  attr_reader :debug

  # @!attribute
  # The last Puppet run status
  attr_reader :last_puppet_run_state

  # @!attribute
  # The date of the last puppet run
  attr_reader :last_puppet_report

  # @!attribute
  # The logger object.
  # @!visibility private
  attr_reader :logger

  # @!attribute
  # The sys_id of the CI.
  attr_accessor :sys_id

  # @!attribute
  # The name of the ci.
  attr_accessor :name

  # @!attribute
  # The amount of RAM of the ci IN MB.
  attr_accessor :ram

  # @!attribute
  # # The environment the ci belobgs to.
  attr_accessor :environment

  # @!attribute
  # The asset tag.
  attr_accessor :asset_tag

  # @!attribute
  # The manufacturer of the ci.
  attr_accessor :manufacturer

  # @!attribute
  # The company the ci belongs to.
  attr_accessor :company

  # @!attribute
  # The serial number of the ci.
  attr_accessor :serial_number

  # @!attribute
  # The model id.
  attr_accessor :model_id

  # @!attribute
  # The person the ci is assigned to.
  attr_accessor :assigned_to

  # @!attribute
  # The os domain.
  attr_accessor :os_domain

  # @!attribute
  # The operating system running on the ci.
  attr_accessor :os

  # @!attribute
  # The version of the operating system.
  attr_accessor :os_version

  # @!attribute
  # The service pack installed in the operating system.
  attr_accessor :os_service_pack

  # @!attribute
  # The DNS domain of the ci.
  attr_accessor :dns_domain

  # @!attribute
  # The whole disk space assigned to the ci.
  attr_accessor :disk_space

  # @!attribute
  # The short description of the ci.
  attr_accessor :short_description

  # @!attribute
  # The CPU manufacturer.
  attr_accessor :cpu_manufacturer

  # @!attribute
  # The CPU type.
  attr_accessor :cpu_type

  # @!attribute
  # The CPU speed in MHz.
  attr_accessor :cpu_speed

  # @!attribute
  # The CPU count.
  attr_accessor :cpu_count

  # @!attribute
  # The number of CPU cores.
  attr_accessor :cpu_core_count

  # @!attribute
  # The hostname of tge ci.
  attr_accessor :host_name

  # @!attribute
  # The defaut gateway.
  attr_accessor :default_gateway

  # @!attribute
  # The IP address.
  attr_accessor :ip_address

  # @!attribute
  # The MAC address.
  attr_accessor :mac_address

  # @!attribute
  # The PuppetDB facts for the ci.
  attr_accessor :facts

  # @!attribute
  # The address width of the ci, e.g . 32 or 64 bit.
  attr_accessor :os_address_width

  # @!attribute
  # Virtual flag.
  attr_accessor :is_virtual

  # @!attribute
  # Location of the ci.
  attr_accessor :location

  # @!attribute
  # The status of the ci
  attr_accessor :install_status

  # @!attribute
  # The hardware status of the ci
  attr_accessor :hardware_status

  # @!attribute
  # Last puppet run
  attr_accessor :u_last_puppet_run

  # @!attribute
  # Last puppet report time
  attr_accessor :u_last_puppet_report

  # @!attribute
  # The ci class.
  attr_accessor :sys_class_name

  # @!attribute
  # The Puppet role
  attr_accessor :u_puppet_role

  ##
  # Constructor
  # @!method initialize
  #
  # Params:
  # @param sys_id [String] The sys_id of the ci
  # @param ci_name [String] The name of the ci
  # @param environment [String] The environment the ci lives
  # @param debug [Boolean] Switch debug output on
  # @param last_puppet_run_state [String] The state of last puppet run
  # @param [String] last_puppet_report Last Puppet report time
  def initialize(sys_id: nil, ci_name: nil, environment: nil, last_puppet_run_state: nil, last_puppet_report: nil,
                 debug: false, logger: nil)
    @attr_list = %w[sys_id name ram environment asset_tag manufacturer company serial_number model_id assigned_to
                    os_domain os os_version os_service_pack dns_domain disk_space short_description cpu_manufacturer
                    cpu_type cpu_speed cpu_count cpu_core_count host_name default_gateway ip_address mac_address
                    os_address_width is_virtual location install_status hardware_status u_last_puppet_run
                    u_last_puppet_report sys_class_name u_puppet_role]

    conf_obj               = Config.new()
    config                 = conf_obj.config
    @service_now_url       = config['servicenow']['url']
    @username              = config['servicenow']['username']
    @password              = config['servicenow']['password']
    @vmware_vm_id          = config['servicenow']['vmware_vm_id']
    @debug                 = debug
    @last_puppet_run_state = last_puppet_run_state
    @last_puppet_report    = last_puppet_report
    @sys_id                = nil
    @logger                = logger

    unless environment.nil?
      @environment = environment
    end

    unless sys_id.nil?
      @sys_id = sys_id
      get_cmdb_ci_by_sys_id
    else
      unless ci_name.nil?
        @name = ci_name
        get_cmdb_ci_by_name
      end
    end

  end


  ##
  # Create a ServiceNOW cmdb computer ci from PuppetDB facts
  # The name of the ci is required. If the attribute is nil, an exception will be thrown.
  #
  # @raise CiKeyNotDefined
  def create_cmdb_ci_from_facts()
    url = "#{@service_now_url}/table/cmdb_ci_server"

    if @name.nil?
      raise CiKeyNotDefined.new("CI needs a name")
    end

    request = create_request_from_facts

    unless request.empty?
      create_node(url, request)
    end
  end


  ##
  # Update a ServiceNOW computer ci.
  # If the sys_id attribute is nil, the ci will be created instead of updated.
  # To update a ci the sys_id is mandatory.
  #
  # @raise CiKeyNotDefined
  def update_cmdb_ci_from_facts()

    if @sys_id.nil?
      create_cmdb_ci_from_facts
    else
      url = "#{@service_now_url}/table/cmdb_ci_server/#{@sys_id}"

      if @sys_id.nil? && @name.nil?
        @logger.warn("Neither name nor sys_id are given") unless @logger.nil?
        raise CiKeyNotDefined.new("Neither name nor sys_id are given")
      end

      request = create_request_from_facts

      unless request.empty?
        update_node(url, request)
        puts "   => changed" if @debug
      else
        puts "   => unchanged" if @debug
      end
    end
  end


  ##
  # Dump the attributes as hash
  def dump_data
    create_attr_hash
  end


  private


  ##
  # Get a ci from Snow by name
  #
  # @!visibility private
  def get_cmdb_ci_by_name
    url = "#{@service_now_url}/table/cmdb_ci_server?name=#{@name}"

    get_node_data(url)
  end


  ##
  # Get a ci from Snow by sys_id
  #
  # @!visibility private
  def get_cmdb_ci_by_sys_id
    url = "#{@service_now_url}/table/cmdb_ci_server/#{@sys_id}"

    get_node_data(url)
  end


  ##
  # Create a hash from the facts for ci update
  #
  # @return [Hash] request The hash with changes values
  # @!visibility private
  def create_request_from_facts
    kernel       = ''
    os           = ''
    arch         = ''
    model_id     = ''
    productname  = ''
    manufacturer = ''
    datacenter   = ''
    puppet_role  = ''
    virtual      = ''
    sys_class    = 'Server'
    request      = {}

    @facts.each do |data|

      certname    = data['certname']
      environment = data['environment']
      fact_name   = data['name']
      fact_value  = data['value']

      if certname.downcase == @name.downcase

        if @environment.downcase != environment.downcase
          request['environment'] = environment.capitalize
        end

        if fact_name == 'kernel'
          kernel = fact_value
        end

        if fact_name == 'operatingsystem'
          os = fact_value
        end

        if (fact_name == 'macaddress') && (@mac_address != fact_value)
          request['mac_address'] = fact_value
        end

        if (fact_name == 'memorysize_mb')
          ram = fact_value.to_f.round(half: :up)
          if (@ram != ram.to_s)
            request['ram'] = ram.to_i
          end
        end

        if (fact_name == 'disks')
          disk_space = calculate_disk_space(fact_value)
          if (@disk_space != disk_space.to_s)
            request['disk_space'] = disk_space
          end
        end

        if (fact_name == 'dmi')
          serial = get_serial_number(fact_value)
          if (@serial_number != serial)
            request['serial_number'] = serial
          end
        end

        if (fact_name == 'operatingsystemrelease') && (@os_version != fact_value)
          request['os_version'] = fact_value
        end

        if (fact_name == 'domain') && (@dns_domain != fact_value)
          request['dns_domain'] = fact_value
        end

        if (fact_name == 'ipaddress') && (@ip_address != fact_value)
          request['ip_address'] = fact_value
        end

        if (fact_name == 'hostname') && (@host_name != fact_value)
          request['host_name'] = fact_value
        end

        if fact_name == 'cpuspeed'
          cpuspeed = fact_value.to_f.round(half: :up).to_i
          if (@cpu_speed != cpuspeed.to_s)
            request['cpu_speed'] = cpuspeed
          end
        end

        if (fact_name == 'processor0') && (@cpu_type != fact_value)
          request['cpu_type'] = fact_value
        end

        if (fact_name == 'processorcount') && (@cpu_count != fact_value.to_s)
          request['cpu_count'] = fact_value
        end

        if (fact_name == 'physicalprocessorcount') && (@cpu_core_count != fact_value.to_s)
          request['cpu_core_count'] = fact_value
        end

        if (fact_name == 'processorcount') && (@cpu_count != fact_value.to_s)
          request['cpu_count'] = fact_value
        end

        if (fact_name == 'manufacturer')
          mf        = split_snow_hash(@manufacturer)
          mf_sys_id = mf[:value]
          manuf     = get_manufacturer_name(mf_sys_id)

          if (manuf != fact_value)
            request['manufacturer'] = fact_value
            manufacturer            = fact_value
          end
        end

        if (fact_name == 'defaultgateway') && (@default_gateway != fact_value)
          request['default_gateway'] = fact_value
        end

        if fact_name == 'architecture'
          arch = fact_value
        end

        if (fact_name == 'cpumanufacturer')
          mf        = split_snow_hash(@cpu_manufacturer)
          mf_sys_id = mf[:value]
          manuf     = get_manufacturer_name(mf_sys_id)
          if (manuf != fact_value)
            request['cpu_manufacturer'] = fact_value
          end
        end

        if (fact_name == 'uuid') && (@asset_tag != fact_value)
          request['asset_tag'] = fact_value
        end

        if fact_name == 'virtual'
          model_id = fact_value
          if fact_value == 'vmware'
            sys_class = 'VMware Virtual Machine Instance'
          end
        end

        if fact_name == 'productname'
          productname = fact_value
        end

        if fact_name == 'trusted'
          datacenter  = get_datacenter(fact_value)
          puppet_role = get_puppet_role(fact_value)
        end
      end
    end

    if @os != "#{kernel} #{os}"
      request['os'] = "#{kernel} #{os}"
    end

    if arch == 'x86_64'
      os_address_width = 64
    elsif arch == 'i386'
      os_address_width = 32
    else
      os_address_width = ''
    end

    if @os_address_width != os_address_width.to_s
      request['os_address_width'] = os_address_width
    end

    data         = "#{manufacturer} #{productname}"
    model_sys_id = get_model_sys_id(data)
    unless model_sys_id.nil?
      if @model_id != model_sys_id
        request['model_id'] = model_sys_id
      end
    end

    request = process_datacenter(datacenter, request)

    if @u_puppet_role != puppet_role
      request['u_puppet_role'] = puppet_role
    end

    if @u_last_puppet_run != @last_puppet_run_state
      request['u_last_puppet_run'] = @last_puppet_run_state
    end

    if @u_last_puppet_report != @last_puppet_report
      request['u_last_puppet_report'] = @last_puppet_report
    end

    unless request.empty?
      request['name'] = @name
    end

    request
  end


  ##
  # Process datacenter information
  #
  # @param datacenter [String] The datscenter
  # @return [Hash] request The updated request hash
  # @!visibility private
  def process_datacenter(datacenter, request)
    unless datacenter.empty?
      case datacenter.downcase
      when 'none'
        location = 'Amberg'

      when 'home'
        location = 'Amberg'

      when 'strato'
        location = 'Berlin'

      else
        location = 'Amberg'

      end

      dc_sys_id = get_location_sys_id(location)

      unless dc_sys_id.nil?
        loc_hash = split_snow_hash(@location)
        loc      = loc_hash[:value]
        if dc_sys_id != loc
          request['location'] = loc
        end
      end
    end

    request
  end


  ##
  # Get datacenter from trusted facts
  #
  # @param data [Hash] The trusted facts.
  # @return [String] datacenter The datacenter from trusted facts
  # @!visibility private
  def get_datacenter(data)
    data['extensions']['pp_datacenter'] || 'n/a'
  end


  ##
  # # Get pp_role attribute from trusted facts.
  #
  # @param data [Hash] The trusted facts.
  # @return [String] role The puppet role.
  # @!visibility private
  def get_puppet_role(data)
    data['extensions']['pp_role'] || 'none'
  end


  ##
  # Get the serial number
  #
  # @param data [Hash] The data.
  # @return [String] serial_number The serial number
  # @!visibility private
  def get_serial_number(data)
    data['product']['serial_number'] || 'n/a'
  end


  ##
  # Calculate the whole disk space from facts
  #
  # @param data [Hash] The disk data.
  # @return [Integer] sum_sizes The sum of all disks
  # @!visibility private
  def calculate_disk_space(data)
    sum_sizes = 0

    data.each do |disk_name, disk|

      unless disk_name =~ %r{^sr}
        if disk.has_key?('size_bytes')
          sum_sizes = sum_sizes + disk['size_bytes']
        end
      end
    end

    sum_sizes = sum_sizes / 1024 / 1024 / 1024

    sum_sizes
  end


  ##
  # Split the ServiceNow Url reference and get the sys_id
  #
  # @param h [Hash] The ServiceNow reference.
  # @return [Hash] Key, value pairs
  # @!visibility private
  def split_snow_hash(h)
    hash = {}
    h.gsub!(%r{"}, '')
    h.gsub!(%r{^\{}, '')
    h.gsub!(%r{\}}, '')
    h.split(',').each do |pair|

      key, value = pair.split(/=>/)
      key.strip!
      hash[key.to_sym] = value.strip
    end

    hash
  end


  ##
  # Update all attributes from a hash
  #
  # @param data [Hash] The hash to write to the class attributes.
  # @!visibility private
  def update_attributes(data)

    unless data.nil?
      @attr_list.each do |attr|
        data.has_key?(attr) ? value = data[attr].to_s : value = ''
        self.__send__(("#{attr}="), value)
      end
    end
  end


  ##
  # Create a hash from all attributes
  #
  # @return [Hash] data The hash created from the class attributes.
  # @!visibility private
  def create_attr_hash
    data = {}
    self.instance_variables.each do |attr|
      value = self.instance_variable_get(attr)
      key   = attr.to_s.sub(%r{^\@}, '').sub(%r{\@}, '')
      if @attr_list.include?(key)
        data[key] = value
      end
    end

    data
  end


  ##
  # Get the data of a ci
  #
  # @param url [String] The url to use for the request
  # @!visibility private
  def get_node_data(url)
    begin
      response      = RestClient.get(url,
                                     authorization: "Basic #{Base64.strict_encode64("#{@username}:#{@password}")}",
                                     content_type:  'application/json',
                                     accept:        'application/json',
                                     timeout:       120)
      response_data = JSON.parse(response)
      result        = response_data['result'][0]

    rescue RestClient::ExceptionWithResponse => e
      e.response
      @logger.err(e.response) unless @logger.nil?
      result = nil
    end

    update_attributes(result)
  end


  ##
  # Update a ci
  #
  # @param url [String] The url to use for the request
  # @param request [Hash] The hash with attributes to change
  # @!visibility private
  def update_node(url, request)
    begin
      response      = RestClient.put(url,
                                     request.to_json,
                                     authorization: "Basic #{Base64.strict_encode64("#{@username}:#{@password}")}",
                                     content_type:  'application/json',
                                     accept:        'application/json',
                                     timeout:       120)
      response_data = JSON.parse(response)
      result        = response_data['result']

    rescue RestClient::ExceptionWithResponse => e
      e.response
      @logger.err(e.response) unless @logger.nil?
      result = nil
    end

    update_attributes(result)
  end


  ##
  # Create a ci
  #
  # @param url [String] The url to use for the request
  # @param request [Hash] The hash with attributes to change
  # @!visibility private
  def create_node(url, request)
    begin
      response      = RestClient.post(url,
                                      request.to_json,
                                      authorization: "Basic #{Base64.strict_encode64("#{@username}:#{@password}")}",
                                      content_type:  'application/json',
                                      accept:        'application/json',
                                      timeout:       120)
      response_data = JSON.parse(response)
      result        = response_data['result']

    rescue RestClient::ExceptionWithResponse => e
      e.response
      @logger.err(e.response) unless @logger.nil?
      result = nil
    end

    update_attributes(result)
  end


  ##
  # Get the sys_id of the hardware model from Snow.
  #
  # @param model [String] The model.
  # @return [String] sys_id The sys_id of the model or nil if not found.
  # @!visibility private
  def get_model_sys_id(model)
    query_data = URI::encode(model)
    url        = "#{@service_now_url}/table/cmdb_hardware_product_model?sysparm_query=display_name%3D#{query_data}"
    sys_id     = get_record_sys_id(url)
    sys_id
  end


  ##
  # Get the sys_id of a location
  #
  # @param location [String] The location (city name)
  # @return [String] sysid The sys_id of the location or nil if not found
  # @!visibility private
  def get_location_sys_id(location)
    query_data = URI::encode(location)
    url        = "#{@service_now_url}/table/cmn_location?sysparm_query=city%3D#{query_data}"
    sys_id     = get_record_sys_id(url)
    sys_id
  end


  ##
  # Read manufacturer name by sys_id.
  #
  # @param sys_id [String] The sys_id of teh manufacturer.
  # @return [String] name The name of the manufakturer
  # @!visibility private
  def get_manufacturer_name(sys_id)
    url  = "#{@service_now_url}/table/core_company/#{sys_id}"
    name = nil
    begin
      response      = RestClient.get(url,
                                     authorization: "Basic #{Base64.strict_encode64("#{@username}:#{@password}")}",
                                     content_type:  'application/json',
                                     accept:        'application/json',
                                     timeout:       120)
      response_data = JSON.parse(response)
      result        = response_data['result']
      unless result.nil?
        name = result['name'] || nil
      end

    rescue RestClient::ExceptionWithResponse => e
      e.response
      @logger.err(e.response) unless @logger.nil?
    end

    name
  end


  ##
  # get a record's sysid from a predefined url
  #
  # @param url [String] The url to use
  # @return [String] sys_id The sys_id of the record to lookup or nil if not found
  # @!visibility private
  def get_record_sys_id(url)
    sys_id = nil
    begin
      response      = RestClient.get(url,
                                     authorization: "Basic #{Base64.strict_encode64("#{@username}:#{@password}")}",
                                     content_type:  'application/json',
                                     accept:        'application/json',
                                     timeout:       120)
      response_data = JSON.parse(response)
      result        = response_data['result'][0]
      if result.nil?
        sys_id = nil
      else
        sys_id = result['sys_id']
      end

    rescue RestClient::ExceptionWithResponse => e
      e.response
      @logger.err(e.response) unless @logger.nil?
    end

    sys_id
  end
end