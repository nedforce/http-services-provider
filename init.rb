# Include hook code here
require 'service_exposer'
require 'xmlrpc_providing'

class ActionController::Routing::RouteSet::Mapper
  def service path, options = {}
    path = path.to_s
    raise "don't specify action!" if path.match(':action') || options.include?(:action)
    unless options.include?(:controller)
      if path.match(/[a-zA-Z0-9_]/)
        options[:controller] = path
      end
    end
    options[:action] = '__dispatch_service_request'
    self.connect path, options
  end
end
