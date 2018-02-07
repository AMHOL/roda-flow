class Roda
  module RodaPlugins
    module Flow

      KEY = 'flow.defaults'.freeze

      module InstanceMethods
        def flow_defaults(args = {}, &block)
          if block_given?
            defaults.merge!(args)
            yield
          else
            raise RodaError 'must pass a block when using flow defaults'
          end
        end

        private

        def defaults
          env[KEY] ||= {}
        end
      end

      module RequestMethods
        def resolve(*keys)
          yield *keys.map { |key| roda_class.resolve(key) }
        end

        private

        def match_to(to)
          container_key, @block_method = to.to_s.split('#')
          @block_arg = roda_class.resolve(container_key)
        end

        def match_inject(inject)
          @block_arg = @block_arg.call(*inject)
        end

        def match_call_with(call_with)
          @captures.concat(call_with)
        end


        def if_match(args, &block)
          path = @remaining_path
          # For every block, we make sure to reset captures so that
          # nesting matchers won't mess with each other's captures.
          @captures.clear

          if match_all(args)
            block_result(get_block(&block).call(*captures))
            throw :halt, response.finish
          else
            @remaining_path = path
            false
          end
        end

        def always(&block)
          super(&get_block(&block))
        end

        def get_block(&block)
          if block_given?
            block
          elsif @block_arg
            if @block_method
              block_arg = @block_arg.method(@block_method)
            else
              block_arg = @block_arg
            end
            clear_block_args
            block_arg
          end
        end

        def clear_block_args
          @block_arg = nil
          @block_method = nil
        end

        def _match_hash(hash)
          if hash.keys.include?(:to)
            hash = merge_defaults(hash)
          end

          super(hash)
        end

        def merge_defaults(hash)
          hash = defaults.merge(hash)
          hash = hash.delete_if { |k,v| v == false }

          # Order matters...
          sorted = %i[to inject call_with].inject({}) do |retval, key|
            retval[key] = hash[key] if hash[key]
            retval
          end

          sorted
        end

        def defaults
          env[KEY] || {}
        end

      end

    end

    register_plugin(:flow, Flow)
  end
end
