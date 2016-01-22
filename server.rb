require "sinatra/base"
require "pg"
require "bcrypt"
require 'digest/md5'
require "pry"
require "active_support/all"

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

# -------------------------------------
    get "/" do 
        # if session["user_id"]
        #     redirect "/articles"
        # else
            erb :index
        # end
    end

# -------------------------------------
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

# -------------------------------------
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
          @error = "Invalid Email"
          erb :login
        end
        binding.pry
    end

# -------------------------------------
    get "/articles" do
        @articles = db.exec_params("SELECT articles.id, articles.title, articles.creation_time, articles.user_id, articles.content, users.fname, users.lname FROM articles JOIN users ON articles.user_id = users.id").to_a
        
        if session["user_id"]
            erb :articles
        else
            redirect "/signup"
        end
    end

# -------------------------------------
    get "/create" do
        if session["user_id"]
            @categories = db.exec_params("SELECT * FROM categories").to_a
            erb :create_article
        else
            redirect "/signup"
        end
    end

    post "/create" do
        title = params[:title]
        content = params[:content]
        user_id = current_user["id"].to_i

        # categories
        category = params[:category]
        cat_id = db.exec_params("SELECT * FROM categories WHERE name = $1", [category]).first["id"]
        new_category = params[:new_category]

        @new_article = db.exec_params("INSERT INTO articles (title, content, user_id) VALUES ($1, $2, $3) RETURNING id", [title, content,  user_id])

        if new_category
            new_cat_id = db.exec_params("INSERT INTO categories (name) VALUES ($1) RETURNING id", [category])
            db.exec_params("INSERT INTO cat_art (article_id, category_id) VALUES ($1, $2)", [@new_article, new_cat_id])
        else
            if category == "None"
                db.exec_params("INSERT INTO cat_art (article_id) VALUES ($1)", [@new_article])
            else
                db.exec_params("INSERT INTO cat_art (article_id, category_id) VALUES ($1, $2)", [@new_article, cat_id])
            end
        end


        redirect "/articles/#{new_article}"


    end

# -------------------------------------
    get "/articles/:id" do

        @article = db.exec_params("SELECT articles.id, articles.title, articles.user_id, articles.content, users.fname, users.lname FROM articles JOIN users ON users.id = articles.user_id WHERE articles.id = $1", [params[:id]]).first
        @date = db.exec_params("SELECT creation_time FROM articles WHERE id = $1", [params[:id]]).first["creation_time"].to_datetime.to_date

        if session["user_id"]
            erb :article
        else
            redirect "/signup"
        end

    end

# -------------------------------------
    get "/articles/:id/edit" do

        if session["user_id"]
            erb :update_article
        else
            redirect "/signup"
        end

    end

# -------------------------------------
    get "/categories" do
        @categories = db.exec_params("SELECT * FROM categories").to_a

        if session["user_id"]
            erb :categories
        else
            redirect "/signup"
        end

    end

# -------------------------------------
    get "/categories/:id" do
        @category = db.exec_params("SELECT * FROM categories WHERE id = $1", [params[:id]]).first
        @articles = db.exec_params("SELECT categories.id, categories.name, cat_art.article_id, articles.title, articles.creation_time, articles.content, users.fname, users.lname FROM categories JOIN cat_art ON categories.id = cat_art.category_id JOIN articles ON cat_art.article_id = articles.id JOIN users ON articles.user_id = users.id WHERE categories.id = $1", [params[:id]]).to_a

        if session["user_id"]
            erb :category
        else
            redirect "/signup"
        end

    end

# -------------------------------------
    get "/users" do 

        if session["user_id"]
            erb :users
        else
            redirect "/signup"
        end

    end

# -------------------------------------
    get "/users/:id" do

        if session["user_id"]
            erb :user
        else
            redirect "/signup"
        end

    end
   
end
