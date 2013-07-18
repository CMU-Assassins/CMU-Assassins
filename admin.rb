# encoding: utf-8
require 'data_mapper'
require 'slim'

module Assassins
  class App < Sinatra::Base
    helpers do
      def admin?
        session.has_key? :admin_id
      end
    end

    get '/admin' do
      if admin?
        redirect to('/admin/dashboard')
      else
        redirect to('/admin/login')
      end
    end

    get '/admin/dashboard' do
      if admin?
        slim :'admin/dashboard'
      else
        redirect to('/admin')
      end
    end

    get '/admin/login' do
      if Admin.count == 0
        redirect to('/admin/create')
      else
        slim :'admin/login'
      end
    end

    post '/admin/login' do
      user = Admin.first(:username => params['username'])

      if (user.nil?)
        return slim :'admin/login', :locals => {:errors =>
          ['Invalid username. Please try again.']}
      end

      if (user.password != params['password'])
        return slim :'admin/login', :locals => {:errors =>
          ['Incorrect password. Please try again.']}
      end

      session[:admin_id] = user.id
      redirect to('/admin/dashboard')
    end

    get '/admin/logout' do
      session.delete :admin_id
      redirect to('/')
    end

    get '/admin/create' do
      if Admin.count == 0 || admin?
        slim :'admin/create'
      else
        redirect to('/admin')
      end
    end

    post '/admin/create' do
      if Admin.count != 0 && !admin?
        return redirect to('/')
      end

      if params['password'] != params['password_confirm']
        return slim :'admin/create', :locals => {:errors =>
          ["Passwords don't match"]}
      end

      admin = Admin.new(:username => params['username'],
                        :password => params['password'])
      if admin.save
        session[:admin_id] = admin.id
        redirect to('/admin/dashboard')
      else
        slim :'admin/create', :locals => {:errors => admin.errors.full_messages}
      end
    end
  end
end

# vim:set ts=2 sw=2 et:
