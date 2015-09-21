# roda-flow

```ruby
User = Struct.new(:id, :name, :email)

class Repository
  attr_accessor :data

  def initialize(data = {})
    self.data = data
  end

  def all
    data.values
  end

  def [](id)
    data[id]
  end

  def push(obj)
    obj.id = data.values.length.next
    data[obj.id] = obj
  end

  def update(obj)
    data[obj.id] = obj
  end

  def delete(obj)
    data.delete(obj.id)
  end
end

class UsersController
  attr_reader :response, :user_repository

  def initialize(response, user_repository)
    @response = response
    @user_repository = user_repository
  end

  def index
    user_repository.all.map(&:to_h)
  end

  # call_with will pass arguments to the method or registered proc
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

class App < Roda
  plugin :all_verbs
  plugin :json
  plugin :flow

  route do |r|
    r.on 'users', resolve: 'repositories.user' do |user_repository|
      r.is do
        r.get to: 'controllers.users#index', inject: [response, user_repository]
        r.post(
          to: 'controllers.users#create',
          inject: [response, user_repository],
          call_with: [r.params]
        )
      end

      r.on :user_id do |user_id|
        r.get(
          to: 'controllers.users#show',
          inject: [response, user_repository],
          call_with: [user_id]
        )
        r.put(
          to: 'controllers.users#update',
          inject: [response, user_repository],
          call_with: [user_id, r.params]
        )
        r.delete(
          # to: can also be a registered proc, just omit the "#" and method name
          to: 'controllers.users#destroy',
          inject: [response, user_repository],
          call_with: [user_id]
        )
      end
    end
  end

  register('repositories.user', Repository.new)
  # Inject will pass the arguments to the register block
  register('controllers.users') do |response, user_repository|
    UsersController.new(response, user_repository)
  end
end
```

## Contributing

1. Fork it ( https://github.com/AMHOL/roda-flow )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

[MIT](LICENSE.txt)
