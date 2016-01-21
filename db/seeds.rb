require 'pg'

if ENV["RACK_ENV"] == "production"
    conn = PG.connect(
        dbname: ENV["POSTGRES_DB"],
        host: ENV["POSTGRES_HOST"],
        password: ENV["POSTGRES_PASS"],
        user: ENV["POSTGRES_USER"]
     )
else
    conn = PG.connect(dbname: "wiki")
end

conn.exec("DROP TABLE IF EXISTS users")
conn.exec("DROP TABLE IF EXISTS articles")
conn.exec("DROP TABLE IF EXISTS categories")
conn.exec("DROP TABLE IF EXISTS cat_art")
conn.exec("DROP TABLE IF EXISTS updates")

conn.exec("CREATE TABLE users(
    id SERIAL PRIMARY KEY,
    fname VARCHAR(255),
    lname VARCHAR(255),
    email VARCHAR(255),
    password_digest VARCHAR NOT NULL
  )"
)

conn.exec("CREATE TABLE articles(
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    creation_time TIMESTAMP DEFAULT current_timestamp,
    user_id INTEGER REFERENCES users,
    category_id INTEGER REFERENCES cat_art
  )"
)

conn.exec("CREATE TABLE categories(
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    article_id INTEGER REFERENCES cat_art
  )"
)

conn.exec("CREATE TABLE cat_art(
    id SERIAL PRIMARY KEY,
    article_id INTEGER REFERENCES cat_art,
    category_id INTEGER REFERENCES cat_art
  )"
)

conn.exec("CREATE TABLE updates(
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    update_time TIMESTAMP DEFAULT current_timestamp,
    user_id INTEGER REFERENCES users,
    article_id INTEGER REFERENCES articles,
    category_id INTEGER REFERENCES categories
  )"
)


# conn.exec("INSERT INTO wiki (name, email, message) VALUES (
#     'Bryan',
#     'bryan.mytko@generalassemb.ly',
#     'This is a test message from the seeded data'
#   )"
# )
