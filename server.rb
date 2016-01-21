require "sinatra/base"
require "pg"
require "bcrypt"

class Server < Sinatra::Base 

    get "/" do 
        erb :index
    end

    get "/articles" do
        erb :articles
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
