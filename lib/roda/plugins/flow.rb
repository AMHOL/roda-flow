class Roda
  module RodaPlugins
    module Flow
      def self.load_dependencies(app, _opts = nil)
        app.plugin :container
      end

      module RequestMethods
        def if_match(args, &block)
          path = @remaining_path
          # For every block, we make sure to reset captures so that
          # nesting matchers won't mess with each other's captures.
          @captures.clear

          kwargs = {}

          if args.last === Base::RequestMethods::TERM && args.first.is_a?(::Hash)
            kwargs = args.shift
          end

          kwargs = args.pop if args.last.is_a?(::Hash)

          return unless match_all(args)

          container_keys = Array(kwargs.fetch(:resolve, []))

          resolutions = container_keys.map do |resolution|
            if resolution.respond_to?(:call)
              resoltion.call(captures)
            else
              roda_class.resolve(resolution)
            end
          end

          block = kwargs.fetch(:to, block)
          injections = kwargs.fetch(:inject, [])

          unless block.nil? || block.respond_to?(:call)
            block, method = block.to_s.split('#')
            block = roda_class.resolve(block).call(*injections).method(method)
          end

          block_result(block.call(*(captures + resolutions)))
          throw :halt, response.finish
        ensure
          @remaining_path = path
        end
      end
    end

    register_plugin(:flow, Flow)
  end
end
