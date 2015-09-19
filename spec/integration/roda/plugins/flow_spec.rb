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
        attr_reader :response, :user_repository

        def initialize(response, user_repository)
          @response = response
          @user_repository = user_repository
        end

        def index
          user_repository.all.map(&:to_h)
        end

        def create(params)
          response.status = 201
          user_repository.push(
            User.new(
              user_repository.all.length.next, *params.values_at('name', 'email')
            )
          ).to_h
        end
      end

      class App < Roda
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
          end
        end

        register('repositories.user', Repository.new)
        register('controllers.users') { |*args| UsersController.new(*args) }
      end
    end
  end

  describe '#index' do
    let(:users) do
      [
        { id: 1, name: 'John', email: 'john@gotmail.com' },
        { id: 2, name: 'Jill', email: 'jill@gotmail.com' }
      ]
    end

    before do
      repo = Test::App.resolve('repositories.user')
      users.each do |user_attributes|
        repo.push(Test::User.new(*user_attributes.values))
      end
    end

    it 'works' do
      get '/users', {}

      expect(last_response.body).to eq(users.to_json)
    end
  end

  describe '#create' do
    it 'works' do
      post '/users', name: 'John', email: 'john@gotmail.com'

      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq({ id: 1, name: 'John', email: 'john@gotmail.com' }.to_json)
    end
  end
end
