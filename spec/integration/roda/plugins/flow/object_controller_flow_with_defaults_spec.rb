require 'spec_helper'
require 'support/test_repository'
require 'support/users_controller'

RSpec.describe 'flow plugin with defaults' do
  before do
    module Test
      class App < Roda
        plugin :all_verbs
        plugin :json
        plugin :container
        plugin :flow

        route do |r|
          r.on 'defaults' do
            r.on 'users' do
              r.resolve('repositories.user') do |user_repo|
                flow_defaults(inject: [r.response, user_repo], call_with: [r.params]) do
                  r.is do
                    r.get to: 'controllers.users#index',
                      call_with: false

                    r.post to: 'controllers.users#create'
                  end

                  r.on :user_id do |user_id|
                    flow_defaults(call_with: [user_id]) do
                      r.get to: 'controllers.users#show'

                      r.put to: 'controllers.users#update',
                        call_with: [user_id, r.params]

                      r.delete to: 'controllers.users#destroy'
                    end
                  end
                end
              end
            end
          end
        end

        register('repositories.user', ::TestRepository.new)
        register('controllers.users') { |*args| ::UsersController.new(*args) }
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
        repo.push(::User.new(*user_attributes.values))
      end
    end

    it 'returns a 200 with users array representation', focus: true do
      get '/defaults/users', {}

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq(users.to_json)
    end
  end

  describe '#show' do
    let(:user) do
      { id: 1, name: 'John', email: 'john@gotmail.com' }
    end

    before do
      Test::App.resolve('repositories.user').push(::User.new(*user.values))
    end

    context 'with invalid user_id' do
      it 'returns a 404 with an empty hash representation' do
        get '/defaults/users/2', {}

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq({}.to_json)
      end
    end

    context 'with valid user_id' do
      it 'returns a 200 with the user representation' do
        get '/defaults/users/1', {}

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq(user.to_json)
      end
    end
  end

  describe '#create' do
    context 'with invalid params' do
      it 'returns a 422 with an invalid user representation' do
        post '/defaults/users', name: '', email: 'john@gotmail.com'

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
        post '/defaults/users', name: 'John', email: 'john@gotmail.com'

        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq({ id: 1, name: 'John', email: 'john@gotmail.com' }.to_json)
      end
    end
  end

  describe '#update' do
    let(:user) do
      { id: 1, name: 'John', email: 'john@gotmail.com' }
    end

    before do
      Test::App.resolve('repositories.user').push(::User.new(*user.values))
    end

    context 'with invalid user_id' do
      it 'returns a 404 with an empty hash representation' do
        put '/defaults/users/2', name: 'John Smith'

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq({}.to_json)
      end
    end

    context 'with valid user_id' do
      context 'with invalid params' do
        it 'returns a 422 with the invalid user representation' do
          put '/defaults/users/1', name: ''

          expect(last_response.status).to eq(422)
          expect(last_response.body).to eq(user.update(name: '').to_json)
        end
      end

      context 'with valid params' do
        it 'returns a 200 with the user representation' do
          put '/defaults/users/1', name: 'John Smith'

          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq(user.update(name: 'John Smith').to_json)
        end
      end
    end
  end

  describe '#destroy' do
    let(:user) do
      { id: 1, name: 'John', email: 'john@gotmail.com' }
    end

    before do
      Test::App.resolve('repositories.user').push(::User.new(*user.values))
    end

    context 'with invalid user_id' do
      it 'returns a 404 with an empty hash representation' do
        delete '/defaults/users/2', {}

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq({}.to_json)
      end
    end

    context 'with valid user_id' do
      it 'returns a 200 with an empty hash representation' do
        delete '/defaults/users/1', {}

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq({}.to_json)
      end
    end
  end
end
