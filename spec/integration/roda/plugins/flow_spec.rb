require 'spec_helper'

RSpec.describe 'flow plugin' do
  before do
    module Test
      User = Struct.new(:id, :name, :email)

      class Repository
        attr_accessor :data

        def initialize(data = {})
          self.data = data
        end

        def all
          data.values
        end

        def push(obj)
          data[obj.id] = obj
        end

        def update(obj)
          data[obj.id] = obj
        end
      end

      class UsersController
        attr_reader :request, :user_repository

        def initialize(request, user_repository)
          @request = request
          @user_repository = user_repository
        end

        def index
          user_repository.all
        end

        def create
          user_repository.push(
            User.new(
              user_repository.all.length.next, *request.params.values_at('name', 'email')
            )
          ).to_h
        end
      end

      class Application < Roda
        plugin :json
        plugin :flow

        route do |r|
          r.on 'users', resolve: 'repositories.user' do |user_repository|
            r.is do
              r.get to: 'controllers.users#index', inject: [r, user_repository]
              r.post to: 'controllers.users#create', inject: [r, user_repository]
            end
          end
        end

        register('repositories.user') { Repository.new }
        register('controllers.users') { |*args| UsersController.new(*args) }
      end
    end
  end

  it 'works' do
    get '/users', {}

    expect(last_response.body).to eq([].to_json)
  end

  it 'works' do
    post '/users', name: 'John', email: 'john@hotmail.com'

    expect(last_response.body).to eq({ id: 1, name: 'John', email: 'john@hotmail.com' }.to_json)
  end
end
