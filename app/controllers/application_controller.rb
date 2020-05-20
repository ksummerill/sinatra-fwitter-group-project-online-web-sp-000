require './config/environment'
require 'rack-flash'

class ApplicationController < Sinatra::Base

  use Rack::Flash

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
    # added next two lines. not sure if they're necessary.
    enable :sessions
    use Rack::Flash
    set :session_secret, "password_security"
  end

  # load homepage for sign up and login
  get '/' do
    erb :index
  end

  # load signup page
  get '/signup' do
    if Helpers.logged_in?(session)
      redirect '/tweets'
    else
      erb :'/users/create_user'
    end
  end

  # create the user and save it to the database
  # also log the user in and add the user_id to the sessions hash
  post '/signup' do
    if params.none? {|key, value| value == ""}
      @user = User.create(username: params[:username], email: params[:email], password: params[:password])
      session[:user_id] = @user.id
      redirect 'tweets/tweets'
    else
      flash[:error] = "Please complete all the information to create your account"
      redirect '/signup'
    end
  end

  # if the user isn't already logged in, show login page
  get '/login' do
    if !Helpers.logged_in?(session)
      erb :'/users/login'
    else
      redirect '/tweets'
    end
  end

  post '/login' do
    @user = User.find_by(username: params[:username])
      if @user && @user.authenticate(params[:password])
        session[:user_id] = @user.id
        redirect '/tweets'
    else
      flash[:error] = "Login error. Please try again or sign up for a Fwitter account."
      redirect '/login'
    end
  end

  get '/tweets' do
    if !Helpers.logged_in?(session)
      redirect '/login'
    end
    @tweets = Tweet.all
    @user = Helpers.current_user(session)
    erb :'/tweets/tweets'
  end

  # shows all tweets from a single user
  get '/users/:slug' do
    @user = User.find_by_slug(params[:slug])
    erb :'/users/show'
  end

  get '/tweets/new' do
    if !Helpers.logged_in?(session)
      flash[:message] = "You Must Be Logged in to Make Tweets"
      redirect '/login'
    end
      erb :'tweets/new'
  end

  # The tweet should be created and saved to the database
  post '/tweets' do
    if !params[:content].empty?
      Tweet.create(content: params[:content], user_id: session[:user_id])
      redirect '/tweets/tweets'
    else
      flash[:error] = "Please enter a tweet"
      redirect '/tweets/new'
    end
  end

  # clear session hash and redirect to /login
  # redirects a user to the index page if the user tries to access /logout while not logged in
  get '/logout' do
    session.clear
    flash[:message] = "See ya later, Alligator!"
    redirect '/login'
  end

end
