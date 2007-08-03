module ActionController
  # CgiRequest and TestRequest provide concrete implementations.
  class AbstractRequest
    cattr_accessor :relative_url_root
    remove_method :relative_url_root

    # The hash of environment variables for this request,
    # such as { 'RAILS_ENV' => 'production' }.
    attr_reader :env

    # The requested content type, such as :html or :xml.
    attr_writer :format

    # The HTTP request method as a lowercase symbol, such as :get.
    # Note, HEAD is returned as :get since the two are functionally
    # equivalent from the application's perspective.
    def method
      @request_method ||=
        if @env['REQUEST_METHOD'] == 'POST' && !parameters[:_method].blank?
          parameters[:_method].to_s.downcase.to_sym
        else
          @env['REQUEST_METHOD'].downcase.to_sym
        end

      @request_method == :head ? :get : @request_method
    end

    # Is this a GET (or HEAD) request?  Equivalent to request.method == :get
    def get?
      method == :get
    end

    # Is this a POST request?  Equivalent to request.method == :post
    def post?
      method == :post
    end

    # Is this a PUT request?  Equivalent to request.method == :put
    def put?
      method == :put
    end

    # Is this a DELETE request?  Equivalent to request.method == :delete
    def delete?
      method == :delete
    end

    # Is this a HEAD request? request.method sees HEAD as :get, so check the
    # HTTP method directly.
    def head?
      @env['REQUEST_METHOD'].downcase.to_sym == :head
    end

    def headers
      @env
    end

    # Determine whether the body of a HTTP call is URL-encoded (default)
    # or matches one of the registered param_parsers. 
    #
    # For backward compatibility, the post format is extracted from the
    # X-Post-Data-Format HTTP header if present.
    def content_type
      @content_type ||=
        begin
          # Receive header sans any charset information.
          content_type = @env['CONTENT_TYPE'].to_s.sub(/\s*\;.*$/, '').strip.downcase

          if x_post_format = @env['HTTP_X_POST_DATA_FORMAT']
            case x_post_format.to_s.downcase
            when 'yaml'
              content_type = Mime::YAML.to_s
            when 'xml'
              content_type = Mime::XML.to_s
            end
          end

          Mime::Type.lookup(content_type)
        end
    end

    # Returns the accepted MIME type for the request
    def accepts
      @accepts ||=
        if @env['HTTP_ACCEPT'].to_s.strip.empty?
          [ content_type, Mime::ALL ].compact # make sure content_type being nil is not included
        else
          Mime::Type.parse(@env['HTTP_ACCEPT'])
        end
    end

    # Returns the Mime type for the format used in the request. If there is no format available, the first of the 
    # accept types will be used. Examples:
    #
    #   GET /posts/5.xml   | request.format => Mime::XML
    #   GET /posts/5.xhtml | request.format => Mime::HTML
    #   GET /posts/5       | request.format => request.accepts.first (usually Mime::HTML for browsers)
    def format
      @format ||= parameters[:format] ? Mime::Type.lookup_by_extension(parameters[:format]) : accepts.first
    end

    # Returns true if the request's "X-Requested-With" header contains
    # "XMLHttpRequest". (The Prototype Javascript library sends this header with
    # every Ajax request.)
    def xml_http_request?
      not /XMLHttpRequest/i.match(@env['HTTP_X_REQUESTED_WITH']).nil?
    end
    alias xhr? :xml_http_request?

    # Determine originating IP address.  REMOTE_ADDR is the standard
    # but will fail if the user is behind a proxy.  HTTP_CLIENT_IP and/or
    # HTTP_X_FORWARDED_FOR are set by proxies so check for these before
    # falling back to REMOTE_ADDR.  HTTP_X_FORWARDED_FOR may be a comma-
    # delimited list in the case of multiple chained proxies; the first is
    # the originating IP.
    def remote_ip
      return @env['HTTP_CLIENT_IP'] if @env.include? 'HTTP_CLIENT_IP'

      if @env.include? 'HTTP_X_FORWARDED_FOR' then
        remote_ips = @env['HTTP_X_FORWARDED_FOR'].split(',').reject do |ip|
            ip =~ /^unknown$|^(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\./i
        end

        return remote_ips.first.strip unless remote_ips.empty?
      end

      @env['REMOTE_ADDR']
    end

    # Returns the lowercase name of the HTTP server software.
    def server_software
      (@env['SERVER_SOFTWARE'] && /^([a-zA-Z]+)/ =~ @env['SERVER_SOFTWARE']) ? $1.downcase : nil
    end


    # Returns the complete URL used for this request
    def url
      protocol + host_with_port + request_uri
    end

    # Return 'https://' if this is an SSL request and 'http://' otherwise.
    def protocol
      ssl? ? 'https://' : 'http://'
    end

    # Is this an SSL request?
    def ssl?
      @env['HTTPS'] == 'on' || @env['HTTP_X_FORWARDED_PROTO'] == 'https'
    end

    # Returns the host for this request, such as example.com.
    def host
    end

    # Returns a host:port string for this request, such as example.com or
    # example.com:8080.
    def host_with_port
      host + port_string
    end

    # Returns the port number of this request as an integer.
    def port
      @port_as_int ||= @env['SERVER_PORT'].to_i
    end

    # Returns the standard port number for this request's protocol
    def standard_port
      case protocol
        when 'https://' then 443
        else 80
      end
    end

    # Returns a port suffix like ":8080" if the port number of this request
    # is not the default HTTP port 80 or HTTPS port 443.
    def port_string
      (port == standard_port) ? '' : ":#{port}"
    end

    # Returns the domain part of a host, such as rubyonrails.org in "www.rubyonrails.org". You can specify
    # a different <tt>tld_length</tt>, such as 2 to catch rubyonrails.co.uk in "www.rubyonrails.co.uk".
    def domain(tld_length = 1)
      return nil if !/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/.match(host).nil? or host.nil?

      host.split('.').last(1 + tld_length).join('.')
    end

    # Returns all the subdomains as an array, so ["dev", "www"] would be returned for "dev.www.rubyonrails.org".
    # You can specify a different <tt>tld_length</tt>, such as 2 to catch ["www"] instead of ["www", "rubyonrails"]
    # in "www.rubyonrails.co.uk".
    def subdomains(tld_length = 1)
      return [] unless host
      parts = host.split('.')
      parts[0..-(tld_length+2)]
    end

    # Return the request URI, accounting for server idiosyncracies.
    # WEBrick includes the full URL. IIS leaves REQUEST_URI blank.
    def request_uri
      if uri = @env['REQUEST_URI']
        # Remove domain, which webrick puts into the request_uri.
        (%r{^\w+\://[^/]+(/.*|$)$} =~ uri) ? $1 : uri
      else
        # Construct IIS missing REQUEST_URI from SCRIPT_NAME and PATH_INFO.
        script_filename = @env['SCRIPT_NAME'].to_s.match(%r{[^/]+$})
        uri = @env['PATH_INFO']
        uri = uri.sub(/#{script_filename}\//, '') unless script_filename.nil?
        unless (env_qs = @env['QUERY_STRING']).nil? || env_qs.empty?
          uri << '?' << env_qs
        end
        @env['REQUEST_URI'] = uri
      end
    end

    # Returns the interpreted path to requested resource after all the installation directory of this application was taken into account
    def path
      path = (uri = request_uri) ? uri.split('?').first.to_s : ''

      # Cut off the path to the installation directory if given
      path.sub!(%r/^#{relative_url_root}/, '')
      path || ''      
    end
    
    # Returns the path minus the web server relative installation directory.
    # This can be set with the environment variable RAILS_RELATIVE_URL_ROOT.
    # It can be automatically extracted for Apache setups. If the server is not
    # Apache, this method returns an empty string.
    def relative_url_root
      @@relative_url_root ||= case
        when @env["RAILS_RELATIVE_URL_ROOT"]
          @env["RAILS_RELATIVE_URL_ROOT"]
        when server_software == 'apache'
          @env["SCRIPT_NAME"].to_s.sub(/\/dispatch\.(fcgi|rb|cgi)$/, '')
        else
          ''
      end
    end


    # Receive the raw post data.
    # This is useful for services such as REST, XMLRPC and SOAP
    # which communicate over HTTP POST but don't use the traditional parameter format.
    def raw_post
      @env['RAW_POST_DATA'] ||= body.read
    end

    # Returns both GET and POST parameters in a single hash.
    def parameters
      @parameters ||= request_parameters.update(query_parameters).update(path_parameters).with_indifferent_access
    end

    def path_parameters=(parameters) #:nodoc:
      @path_parameters = parameters
      @symbolized_path_parameters = @parameters = nil
    end

    # The same as <tt>path_parameters</tt> with explicitly symbolized keys 
    def symbolized_path_parameters 
      @symbolized_path_parameters ||= path_parameters.symbolize_keys
    end

    # Returns a hash with the parameters used to form the path of the request 
    #
    # Example: 
    #
    #   {:action => 'my_action', :controller => 'my_controller'}
    def path_parameters
      @path_parameters ||= {}
    end


    #--
    # Must be implemented in the concrete request
    #++

    # The request body is an IO input stream.
    def body
    end

    def query_parameters #:nodoc:
    end

    def request_parameters #:nodoc:
    end

    def cookies #:nodoc:
    end

    def session #:nodoc:
    end

    def session=(session) #:nodoc:
      @session = session
    end

    def reset_session #:nodoc:
    end


    def self.parse_formatted_request_parameters(mime_type, body)
      case strategy = ActionController::Base.param_parsers[mime_type]
        when Proc
          strategy.call(body)
        when :xml_simple, :xml_node
          body.blank? ? {} : Hash.from_xml(body).with_indifferent_access
        when :yaml
          YAML.load(body)
        else
          {}
      end
    rescue Exception => e # YAML, XML or Ruby code block errors
      { "exception" => "#{e.message} (#{e.class})", "backtrace" => e.backtrace,
        "body" => body, "format" => mime_type }
    end
  end
end