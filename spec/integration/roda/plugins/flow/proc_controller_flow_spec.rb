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
      end

      class App < Roda
        plugin :all_verbs
        plugin :json
        plugin :flow

        route do |r|
          r.on 'users', resolve: 'repositories.user' do |user_repository|
            r.is do
              r.get to: 'controllers.index_users', inject: [user_repository]
              r.post(
                to: 'controllers.create_user',
                inject: [response, user_repository],
                call_with: [r.params]
              )
            end

            r.on :user_id do |user_id|
              r.get(
                to: 'controllers.show_user',
                inject: [response, user_repository],
                call_with: [user_id]
              )
              r.put(
                to: 'controllers.update_user',
                inject: [response, user_repository],
                call_with: [user_id, r.params]
              )
            end
          end
        end

        register('repositories.user', Repository.new)
        namespace('controllers') do
          register('index_users') do |user_repository|
            -> { user_repository.all.map(&:to_h) }
          end

          register('show_user') do |response, user_repository|
            lambda do |user_id|
              if (user = user_repository[user_id.to_i])
                user.to_h
              else
                response.status = 404
                {}
              end
            end
          end

          register('create_user') do |response, user_repository|
            lambda do |params|
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
          end

          register('update_user') do |response, user_repository|
            lambda do |user_id, params|
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
          end
        end
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

    it 'returns a 200 with users array representation' do
      get '/users', {}

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq(users.to_json)
    end
  end

  describe '#show' do
    let(:user) do
      { id: 1, name: 'John', email: 'john@gotmail.com' }
    end

    before do
      Test::App.resolve('repositories.user').push(Test::User.new(*user.values))
    end

    context 'with invalid user_id' do
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

  describe '#create' do
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

  describe '#update' do
    let(:user) do
      { id: 1, name: 'John', email: 'john@gotmail.com' }
    end

    before do
      Test::App.resolve('repositories.user').push(Test::User.new(*user.values))
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
end
