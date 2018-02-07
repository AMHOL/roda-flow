class UsersController
  attr_reader :response, :user_repository

  def initialize(response, user_repository)
    @response = response
    @user_repository = user_repository
  end

  def index
    user_repository.all.map(&:to_h)
  end

  def show(user_id)
    if (user = user_repository[user_id.to_i])
      user.to_h
    else
      response.status = 404
      {}
    end
  end

  def create(params)
    user = User.new(nil, *params.values_at('name', 'email'))

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

  def update(user_id, params)
    if (user = user_repository[user_id.to_i])
      params = params.each_with_object(user.to_h) { |(k, v), h| h[k.to_sym] = v }

      if params.values.map(&:to_s).any?(&:empty?)
        response.status = 422
        params
      else
        user_repository.update(
          User.new(*params.values)
        ).to_h
      end
    else
      response.status = 404
      {}
    end
  end

  def destroy(user_id)
    if (user = user_repository[user_id.to_i])
      user_repository.delete(user)
      {}
    else
      response.status = 404
      {}
    end
  end
end
