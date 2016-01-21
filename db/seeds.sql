DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS articles CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS cat_art CASCADE;
DROP TABLE IF EXISTS updates CASCADE;

CREATE TABLE users(
    id SERIAL PRIMARY KEY,
    fname VARCHAR(255),
    lname VARCHAR(255),
    email VARCHAR(255),
    password_digest VARCHAR NOT NULL,
    image VARCHAR
);

CREATE TABLE articles(
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    creation_time TIMESTAMP DEFAULT current_timestamp,
    user_id INTEGER REFERENCES users,
    content TEXT
);

CREATE TABLE categories(
    id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE cat_art(
    id SERIAL PRIMARY KEY,
    article_id INTEGER REFERENCES articles,
    category_id INTEGER REFERENCES categories
);

CREATE TABLE updates(
    id SERIAL PRIMARY KEY,
    title VARCHAR(255),
    update_time TIMESTAMP DEFAULT current_timestamp,
    user_id INTEGER REFERENCES users,
    article_id INTEGER REFERENCES articles,
    category_id INTEGER REFERENCES categories,
    content TEXT
);


