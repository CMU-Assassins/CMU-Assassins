# encoding: utf-8
require 'data_mapper'
require 'slim'

module Assassins
  class App < Sinatra::Base
    before do
      @admin = nil
      if session.has_key? :admin_id
        @admin = Admin.get session[:admin_id]
        if @admin.nil?
          session.delete :admin_id
        end
      end
    end

    set :is_admin do |val|
      condition {!@admin.nil? == val}
    end

    get '/admin' do
      if !@admin.nil?
        redirect to('/admin/dashboard')
      else
        redirect to('/admin/login')
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
      if Admin.count == 0 || !@admin.nil?
        slim :'admin/create'
      else
        redirect to('/admin')
      end
    end

    post '/admin/create' do
      if Admin.count != 0 && @admin.nil?
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

    post '/admin/dashboard/prune_inactive', :is_admin => true do
      Player.prune_inactive
      redirect to('/admin/dashboard')
    end

    get '/admin/dashboard', :is_admin => true do
      slim :'admin/dashboard'
    end

    post '/admin/dashboard/start_game', :is_admin => true do
      players = Player.all(:is_verified => true)
      players.shuffle!
      start_time = Time.now
      @game.start_time = start_time
      @game.save

      players.each_index do |i|
        players[i].set_target_notify(players[(i + 1) % players.length])
        players[i].last_activity = start_time
        players[i].save!
      end

      redirect to('/admin/dashboard')
    end

    post '/admin/dashboard/send_mass_email', :is_admin => true do
      Player.send_email_all(params['subject'], params['body'])
      redirect to('/admin/dashboard')
    end
  end
end

# vim:set ts=2 sw=2 et:
