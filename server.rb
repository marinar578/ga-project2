require "sinatra/base"
require "pg"
require "bcrypt"
require 'digest/md5'
require "pry"


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
          {}
        end
    end


    get "/" do 
        if session["user_id"]
            erb :articles
        else
            erb :index
        end
    end

    get "/signup" do
        erb :signup
    end

    post "/signup" do
        fname = params[:fname]
        lname = params[:lname]
        email_address = params[:email].downcase
        
        encrypted_password = BCrypt::Password.create(params[:password])
        
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
        @user = db.exec_params("SELECT * FROM users WHERE email = $1", [params[:email]]).first
        if @user
          if BCrypt::Password.new(@user["password_digest"]) == params[:password]
            session["user_id"] = @user["id"]
            redirect "/articles"
          else
            @error = "Invalid Password"
            erb :login
          end
        else
          @error = "Invalid Username"
          erb :login
        end
        binding.pry
    end

    get "/articles" do
        if session["user_id"]
            erb :articles
        else
            redirect "/"
        end
    end

    get "/articles/:id" do
        if session["user_id"]
            erb :article
        else
            redirect "/"
        end
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
