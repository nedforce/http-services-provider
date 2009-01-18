module ServiceExposer
  def self.included(mod)
    raise "Can only be included in children of ActionController::Base, not in #{mod}" unless mod.ancestors.include? ActionController::Base
    mod.class_eval do
      cattr_accessor :service_dispatcher
      attr_internal :service_request
    end
    mod.service_dispatcher = Dispatcher.new()
  end
  
  def __dispatch_service_request
    action, self.service_request = self.class.service_dispatcher.dispatch(request)
    self.send(action)
  end

  class Dispatcher
    def initialize
      @map = Mapper.new 
      @processors = {}
    end
    
    def add_specifier(specifier)
      @map.specifiers << specifier
    end
    
    def draw_routes &block
      yield(@map)
    end
    
    # processes the request and returns the action to which
    # this request should be dispatched, as well as a service_request object
    # that contains the processed request
    def dispatch(request)
      type = recognize(request)
      service_request = process(request, type)
      action = match(type, request, service_request, @map.route_set.routes_for(type))
      [action, service_request]
    end
    
    # sets the processor for a certain type of request
    def set_processor type, processor
      @processors[type] = processor
    end    
    
    # see wich processor recognizes this request
    def recognize request
      type, processor = @processors.find do |type, processor|
        processor.recognize?(request)    
      end
      raise "unrecognized service request" unless type
      type
    end
    
    # call on the processor to process this request
    # and generate an object that contains all relevant information.    
    def process request, type
      @processors[type].process(request)
    end
    
    # call on the processor to match the given service request
    # to an action, given a set of routes
    def match type, request, service_request, routes
      @processors[type].match(request, service_request, routes)
    end
    
    class Mapper      
      attr_accessor :route_set
      attr_accessor :specifiers
      def initialize
        @route_set = RouteSet.new
        @specifiers = []
      end
      def method_missing(method, *args)
        specifier = @specifiers.find do |s|
          s.class.method_defined?(method)          
        end
        if specifier
          specifier.send(method, route_set, *args)
        else
          super(method, *args)
        end
      end
      
      class RouteSet
        def initialize 
          @set = {}
        end
        def add(type, *options)
          @set[type] ||= []
          @set[type] << options
        end
        def routes_for type; @set[type]; end
      end
    end
  end
end
      
