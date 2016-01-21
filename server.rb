require "sinatra/base"
require "pg"
require "bcrypt"
require 'digest/md5'


class Server < Sinatra::Base 

    enable :sessions

    def db
        if ENV["RACK_ENV"] == "production"
            PG.connect(
                dbname: ENV["POSTGRES_DB"],
                host: ENV["POSTGRES_HOST"],
                password: ENV["POSTGRES_PASS"],
                user: ENV["POSTGRES_USER"]
             )
        else
            PG.connect(dbname: "wiki")
        end
    end

    def current_user
        if session["user_id"]
          @user ||= db.exec_params("SELECT * FROM users WHERE id = $1", [session["user_id"]]).first
        else
          # THE USER IS NOT LOGGED IN
          {}
        end
    end


    get "/" do 
        # if not signed in:
        erb :index

        # if signed in, redirect:
        # redirect "/articles"
    end

    get "/signup" do
        erb :signup
    end

    post "/signup" do
        fname = params[:fname]
        lname = params[:lname]
        email_address = params[:email].downcase
        
        password = params[:password]
        encrypted_password = BCrypt::Password.create(params[:login_password])
        
        hash = Digest::MD5.hexdigest(email_address)
        image = "http://www.gravatar.com/avatar/#{hash}"

        @user = db.exec_params("INSERT INTO users (fname, lname, email, password_digest, image) VALUES ($1, $2, $3, $4, $5) RETURNING id", [fname, lname, email_address, encrypted_password, image])

        session["user_id"] = @user.first["id"]
        # if signup is successful, redirect:
        redirect "/articles"
    end

    get "/login" do
        erb :login
    end

    post "/login" do
        # if login is successful, redirect:
        email = params[:email]
        password = params[:password]


        # erb :articles
    end

    get "/articles" do
        # this doesn't work but something like this has to happen for everything
        if session["user_id"]
            erb :articles
        else
            redirect "/"
        end


    end

    get "/articles/:id" do
        erb :article
    end

    get "/articles/:id/edit" do
        erb :update
    end

    get "/categories" do
        erb :categories
    end

    get "/categories/:id" do
        erb :category
    end

    get "/users" do 
        erb :users
    end

    get "/users/:id" do
        erb :user
    end
   
end
