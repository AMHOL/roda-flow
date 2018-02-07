require 'spec_helper'
require 'support/test_repository'
require 'support/users_controller'

RSpec.describe 'flow plugin' do
  before do
    module Test
      class App < Roda
        plugin :all_verbs
        plugin :json
        plugin :container
        plugin :flow

        route do |r|
          r.get 'ping' do
            'pong'
          end

          r.on 'users' do
            r.resolve 'repositories.user' do |user_repository|
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
                  to: 'controllers.users#destroy',
                  inject: [response, user_repository],
                  call_with: [user_id]
                )
              end
            end
          end
        end

        register('repositories.user', ::TestRepository.new)
        register('controllers.users') { |*args| ::UsersController.new(*args) }
      end
    end
  end

  describe 'GET /ping' do
    it 'does not match a trailing slash' do
      get '/ping/', {}

      expect(last_response.status).to eq(404)
    end

    it 'does not match a trailing wildcard route' do
      get '/ping/2', {}

      expect(last_response.status).to eq(404)
    end

    it 'matches /ping' do
      get '/ping', {}

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('pong')
    end
  end

  describe 'GET /users' do
    let(:users) do
      [
        { id: 1, name: 'John', email: 'john@gotmail.com' },
        { id: 2, name: 'Jill', email: 'jill@gotmail.com' }
      ]
    end

    before do
      repo = Test::App.resolve('repositories.user')
      users.each do |user_attributes|
        repo.push(::User.new(*user_attributes.values))
      end
    end

    it 'returns a 200 with users array representation' do
      get '/users', {}

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq(users.to_json)
    end
  end

  describe 'GET /users/:user_id' do
    let(:user) do
      { id: 1, name: 'John', email: 'john@gotmail.com' }
    end

    before do
      Test::App.resolve('repositories.user').push(::User.new(*user.values))
    end

    context 'with invalid user_id', focus: true do
      it 'returns a 404 with an empty hash representation' do
        get '/users/2', {}

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq({}.to_json)
      end
    end

    context 'with valid user_id' do
      it 'returns a 200 with the user representation' do
        get '/users/1', {}

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq(user.to_json)
      end
    end
  end

  describe 'POST /users' do
    context 'with invalid params' do
      it 'returns a 422 with an invalid user representation' do
        post '/users', name: '', email: 'john@gotmail.com'

        expect(last_response.status).to eq(422)
        expect(last_response.body).to eq({
          id: nil,
          name: '',
          email: 'john@gotmail.com'
        }.to_json)
      end
    end

    context 'with valid params' do
      it 'returns a 201 with the user representation' do
        post '/users', name: 'John', email: 'john@gotmail.com'

        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ id: 1, name: 'John', email: 'john@gotmail.com' }.to_json)
      end
    end
  end

  describe 'PUT /users/:user_id' do
    let(:user) do
      { id: 1, name: 'John', email: 'john@gotmail.com' }
    end

    before do
      Test::App.resolve('repositories.user').push(::User.new(*user.values))
    end

    context 'with invalid user_id' do
      it 'returns a 404 with an empty hash representation' do
        put '/users/2', name: 'John Smith'

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq({}.to_json)
      end
    end

    context 'with valid user_id' do
      context 'with invalid params' do
        it 'returns a 422 with the invalid user representation' do
          put '/users/1', name: ''

          expect(last_response.status).to eq(422)
          expect(last_response.body).to eq(user.update(name: '').to_json)
        end
      end

      context 'with valid params' do
        it 'returns a 200 with the user representation' do
          put '/users/1', name: 'John Smith'

          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq(user.update(name: 'John Smith').to_json)
        end
      end
    end
  end

  describe 'DELETE /users/:user_id' do
    let(:user) do
      { id: 1, name: 'John', email: 'john@gotmail.com' }
    end

    before do
      Test::App.resolve('repositories.user').push(::User.new(*user.values))
    end

    context 'with invalid user_id' do
      it 'returns a 404 with an empty hash representation' do
        delete '/users/2', {}

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq({}.to_json)
      end
    end

    context 'with valid user_id' do
      it 'returns a 200 with an empty hash representation' do
        delete '/users/1', {}

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq({}.to_json)
      end
    end
  end
end
