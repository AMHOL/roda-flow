class RegisterLambdas

  def self.run(app)
    app.register('index_users') do |user_repository|
      -> { user_repository.all.map(&:to_h) }
    end

    app.register('show_user') do |response, user_repository|
      lambda do |user_id|
        if (user = user_repository[user_id.to_i])
          user.to_h
        else
          response.status = 404
          {}
        end
      end
    end

    app.register('create_user') do |response, user_repository|
      lambda do |params|
        user = ::User.new(nil, *params.values_at('name', 'email'))

        if !params.values.map(&:to_s).any?(&:empty?)
          response.status = 201
          user_repository.push(
            user
          ).to_h
        else
          response.status = 422
          user.to_h
        end
      end
    end

    app.register('update_user') do |response, user_repository|
      lambda do |user_id, params|
        if (user = user_repository[user_id.to_i])
          params = params.each_with_object(user.to_h) { |(k, v), h| h[k.to_sym] = v }

          if params.values.map(&:to_s).any?(&:empty?)
            response.status = 422
            params
          else
            user_repository.update(
              ::User.new(*params.values)
            ).to_h
          end
        else
          response.status = 404
          {}
        end
      end
    end

    app.register('destroy_user') do |response, user_repository|
      lambda do |user_id|
        if (user = user_repository[user_id.to_i])
          user_repository.delete(user)
          {}
        else
          response.status = 404
          {}
        end
      end
    end
  end
end
