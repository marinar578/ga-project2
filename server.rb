require "sinatra/base"
require "pg"
require "bcrypt"
require 'digest/md5'
require "pry"
require "active_support/all"
require "redcarpet"

class Server < Sinatra::Base 
  enable :sessions
  set :method_override, true

  def db
    if ENV["RACK_ENV"] == "production"
      @db ||= PG.connect(
        dbname: ENV["POSTGRES_DB"],
        host: ENV["POSTGRES_HOST"],
        password: ENV["POSTGRES_PASS"],
        user: ENV["POSTGRES_USER"]
       )
    else
      @db ||= PG.connect(dbname: "wiki")
    end
  end

  def login(view)
    if session["user_id"]
      erb view
    else
      redirect "/signup"
    end
  end

  def markdown
    renderer = Redcarpet::Render::HTML
    markdown = Redcarpet::Markdown.new(renderer, extensions = {})
    @content = markdown.render(@article["content"])
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
    erb :index
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
  end

# -------------------------------------
  get "/articles" do
    @articles = db.exec_params("SELECT articles.id, articles.title, articles.creation_time, articles.user_id, articles.content, users.fname, users.lname FROM articles JOIN users ON articles.user_id = users.id ORDER BY creation_time DESC").to_a
    login(:articles)
  end

# view specific article
  # -------------------------------------
  get "/articles/:id" do
    @article = db.exec_params("SELECT articles.id, articles.title, articles.user_id, articles.creation_time, articles.content, users.fname, users.lname FROM articles JOIN users ON users.id = articles.user_id WHERE articles.id = $1", [params[:id]]).first
    @date = @article["creation_time"].to_datetime.to_date
    @updates = db.exec_params("SELECT updates.id, updates.update_time, updates.user_id, users.fname, users.lname FROM updates JOIN users ON updates.user_id = users.id WHERE article_id = $1", [params[:id]]).to_a
    markdown
    login(:article)
  end

# view specific update
  # -------------------------------------
  get "/articles/updates/:id" do
    @update = db.exec_params("SELECT updates.id, updates.title, updates.user_id, updates.update_time, updates.content, users.fname, users.lname FROM updates JOIN users ON users.id = updates.user_id WHERE updates.id = $1", [params[:id]]).first
    @date = @update["update_time"].to_datetime.to_date
    
    renderer = Redcarpet::Render::HTML
    markdown = Redcarpet::Markdown.new(renderer, extensions = {})
    @content = markdown.render(@update["content"])

    login(:update)
  end

# add new article
  # -------------------------------------
  get "/create" do
    @categories = db.exec_params("SELECT * FROM categories ORDER BY name").to_a
    login(:create_article)
  end

  post "/create" do
    title = params[:title]
    content = params[:content]
    user_id = current_user["id"]

    # adding multiple categories by saving the selected cats into array @db_cats
    categories = db.exec_params("SELECT * FROM categories").to_a
    @db_cats = []

    # going through categories in database and adding each to the above array if it was selected
    categories.each do |cat|
      if params[cat["id"]]
        @db_cats.push(params[cat["id"]].to_i) 
      end
    end

    @new_article = db.exec_params("INSERT INTO articles (title, content, user_id) VALUES ($1, $2, $3) RETURNING id", [title, content,  user_id]).first["id"].to_i
    
    # inserting category id into updates and cat_art tables (THERE'S GOTTA BE A BETTER WAY, THIS PROBABLY OPENS THE DATABASE CONNECTION LIKE A HUNDRED TIMES)
    @db_cats.each do |cat|
      db.exec_params("INSERT INTO updates (title, user_id, article_id, category_id, content) VALUES ($1, $2, $3, $4, $5)", [title, user_id, @new_article, cat, content])
      db.exec_params("INSERT INTO cat_art (article_id, category_id) VALUES ($1, $2)", [@new_article, cat])
    end

    redirect "/articles/#{@new_article}"
  end


# edit article
  # -------------------------------------
  get "/articles/:id/edit" do
    @article = db.exec_params("SELECT articles.id, articles.title, articles.user_id, articles.content, users.fname, users.lname FROM articles JOIN users ON users.id = articles.user_id WHERE articles.id = $1", [params[:id]]).first
    @categories = db.exec_params("SELECT * FROM categories ORDER BY name").to_a
    @cat_art = db.exec_params("SELECT categories.name, categories.id, cat_art.category_id, cat_art.article_id FROM categories JOIN cat_art ON categories.id = cat_art.category_id JOIN articles ON cat_art.article_id = articles.id WHERE articles.id = $1 ORDER BY categories.name", [params[:id]]).to_a
    login(:update_article)
  end

  put "/articles/:id/edit" do
    title = params[:title]
    content = params[:content]
    user_id = current_user["id"].to_i
    
    @update = db.exec_params("INSERT INTO updates (title, user_id, article_id, content) VALUES ($1, $2, $3, $4) RETURNING update_time, id", [title, user_id, params[:id], content])
    @time = @update.first["update_time"]
    # @update_id = @update.first["id"]

    db.exec_params("UPDATE articles SET title = $1, content = $2, creation_time = $3, user_id = $4 WHERE id = $5", [title, content, @time, user_id, params[:id]])
    

    # # handling multiple categories
    # categories = db.exec_params("SELECT * FROM categories").to_a
    # @add_cats = []
    # @remove_cats = []

    
    # categories.each do |cat|
    #   if params[cat["id"]]
    #     @add_cats.push(params[cat["id"]].to_i) 
    #   end
    #   if params[cat["name"]]
    #     @remove_cats.push(params[cat["id"]].to_i)
    #   end
    # end
  

    # @db_cats.each do |cat|
    #   db.exec_params("UPDATE cat_art SET category_id = $1 WHERE article_id = $2", [cat, params[:id]])
    #   db.exec_params("INSERT INTO cat_upd (category_id, update_id) VALUES ($1, $2)", [cat, @update_id]) 
    # end
    

    redirect "/articles/#{params[:id]}"
  end

# delete article
  # -------------------------------------
  delete "/articles/:id/edit" do
    user_id = current_user["id"].to_i

    db.exec_params("DELETE FROM updates WHERE article_id = $1", [params[:id]])
    db.exec_params("DELETE FROM cat_art WHERE article_id = $1", [params[:id]])
    db.exec_params("DELETE FROM articles WHERE id = $1", [params[:id]])

    redirect "/articles"
  end


# -------------------------------------
  get "/categories" do
    @categories = db.exec_params("SELECT * FROM categories ORDER BY name").to_a
    login(:categories)
  end

  post "/categories" do
    if params[:category].length > 0
      db.exec_params("INSERT INTO categories (name) VALUES ($1)", [params[:category]])
      redirect "/categories"
    else
      @error = "Please enter a category"
    end
  end


# -------------------------------------
  get "/categories/:id" do
    @category = db.exec_params("SELECT * FROM categories WHERE id = $1", [params[:id]]).first
    @articles = db.exec_params("SELECT categories.id, categories.name, cat_art.article_id, articles.title, articles.creation_time, articles.content, articles.user_id, users.fname, users.lname FROM categories JOIN cat_art ON categories.id = cat_art.category_id JOIN articles ON cat_art.article_id = articles.id JOIN users ON articles.user_id = users.id WHERE categories.id = $1 ORDER BY creation_time DESC", [params[:id]]).to_a
    login(:category)
  end

# -------------------------------------
  get "/users" do 
    @users = db.exec_params("SELECT * FROM users").to_a
    login(:users)
  end

# -------------------------------------
  get "/users/:id" do
    @user = db.exec_params("SELECT * FROM users WHERE id = $1", [params[:id]]).first
    @articles = db.exec_params("SELECT articles.id, articles.title, articles.creation_time, articles.user_id, articles.content, users.fname, users.lname FROM articles JOIN users ON articles.user_id = users.id WHERE users.id = $1", [params[:id]]).to_a
    login(:user)
  end


# edit user info (name, pw, email)
  # -------------------------------------
  get "/users/:id/edit" do
    @user = db.exec_params("SELECT * FROM users WHERE id = $1", [current_user["id"]]).first
    login(:user_profile)
  end

  put "/users/:id/edit" do
    if params[:password].length > 0
      password = BCrypt::Password.create(params[:password])
    else
      password = db.exec_params("SELECT password_digest FROM users WHERE id = $1", [params[:id]]).first["password_digest"]
    end
    
    db.exec_params("UPDATE users SET fname = $1, lname = $2, email = $3, password_digest = $4, image = $5 WHERE id = $6", [params[:fname], params[:lname], params[:email], password, params[:image], params[:id]])
    redirect "/users/#{params[:id]}/edit"
  end


# sign out
  # -------------------------------------
  get "/signout" do
    session.clear
    redirect "/"
  end


  # -------------------------------------
   
end
