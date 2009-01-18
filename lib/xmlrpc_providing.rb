module XMLRPCProviding
  def self.included(mod)
    unless mod.kind_of? ServiceExposer
      mod.send(:include, ServiceExposer)
    end
    mod.send(:include, InstanceMethods)
    require 'xmlrpc/marshal'
    mod.service_dispatcher.add_specifier(XMLRPCSpecifier.new)
    mod.service_dispatcher.set_processor(:xmlrpc, XMLRPCProcessor.new)
  end
  
  # Included in ServiceExposer::Dispatcher::Mapper to draw routes 
  class XMLRPCSpecifier
    
    # <tt>method</tt>: a string that should match the xmlrpc method
    # <tt>options</tt>: a hash, valid keys:
    # 
    # * :action => the action this route wil target
    # 
    #   map.xmlrpc ':action'
    #   map.xmlrpc 'bla', :action => 'bla'
    def xmlrpc route_set, method, options = {}
      raise "specify action!" unless method.match(':action') || options.include?(:action)
      route_set.add(:xmlrpc, method, options)
    end
  end
  
  # Methods to process an xmlrpc request
  class XMLRPCProcessor
    
    # called to determine if this is an xmlrpc request
    def recognize?(request)
      XMLRPC::Marshal.load_call(request.raw_post)
    rescue
      false
    end
    
    # called after recognize, return value is assigned to service_request
    def process(request)
      XMLRPCRequest.new(*XMLRPC::Marshal.load_call(request.raw_post))
    end
    
    # called to see if this request matches any of the service routes.
    def match(request, service_request, routes)      
      routes.each do |method, options|
        unless method.match(':action')
          return options[:action] if service_request.methodname == method
        else          
          matcher = Regexp.escape(method).sub(':action', '([A-Za-z0-9_]*)')
          matcher = "^#{matcher}$"
          if match = service_request.methodname.match(matcher)
            return match[1]
          end
        end
      end
      raise "no service route matches #{service_request.methodname}"
    end
  end
  
  class XMLRPCRequest
    attr_accessor :methodname
    attr_accessor :params
    def initialize methodname, params
      @methodname = methodname
      @params = params
    end
  end
  
  module InstanceMethods
    def render_xmlrpc(thing)
      render :text => XMLRPC::Marshal.dump_response(thing)
    end
  end
end