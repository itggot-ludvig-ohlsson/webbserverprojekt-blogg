require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'

enable :sessions

get('/') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true

    users = db.execute("SELECT * FROM users")
    posts = db.execute("SELECT * FROM posts")

    slim(:index, locals: {users: users, posts: posts})
end

get('/register') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true

    users = db.execute("SELECT * FROM users")

    slim(:register, locals: {users: users})
end

post('/register') do
    db = SQLite3::Database.new('db/blog.db')

    pass = BCrypt::Password.create(params["pass"])
    db.execute("INSERT INTO users (username, hashed_pass) VALUES (?,?)", params["username"], pass)

    redirect('/login')
end

get('/login') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true

    users = db.execute("SELECT * FROM users")

    slim(:login, locals: {users: users, fail: params[:fail]})
end

post('/login') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true
    credentials = db.execute("SELECT id, hashed_pass FROM users WHERE username=?", params["username"])[0]

    if credentials != nil && BCrypt::Password.new(credentials["hashed_pass"]) == params["pass"]
        session[:user] = credentials["id"]
        redirect('/')
    else
        redirect('/login?fail=true')
    end
end

post('/logout') do
    session.clear
    redirect('/')
end

get('/user/:id') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true

    user = db.execute("SELECT * FROM users WHERE id=?", params["id"])[0]
    users = db.execute("SELECT * FROM users")
    posts = db.execute("SELECT * FROM posts WHERE writer=?", params["id"][0])
    
    slim(:profile, locals: {
        users: users,
        user: user["username"],
        id: session[:user],
        profile_id: params["id"],
        content: user["about_me"],
        posts: posts
    })
end

get('/user/:id/edit') do
    if session[:user] == params["id"].to_i
        db = SQLite3::Database.new('db/blog.db')
        db.results_as_hash = true

        user = db.execute("SELECT * FROM users WHERE id=?", params["id"])[0]
        users = db.execute("SELECT * FROM users")
        
        slim(:edit_profile, locals: {users: users, user: user["username"], content: user["about_me"]})
    else
        redirect("/user/#{params["id"]}")
    end
end

post('/user/:id/edit') do
    if session[:user] == params["id"].to_i
        db = SQLite3::Database.new('db/blog.db')
        db.results_as_hash = true
        
        db.execute("UPDATE users SET about_me=? WHERE id=?", params["content"], params["id"])
    end
    
    redirect("/user/#{params["id"]}")
end

get('/user/:id/post') do
    if session[:user] == params["id"].to_i
        db = SQLite3::Database.new('db/blog.db')
        db.results_as_hash = true

        users = db.execute("SELECT * FROM users")

        slim(:create_post, locals: {users: users})
    else
        redirect("/user/#{params["id"]}")
    end
end

post('/user/:id/post') do
    if session[:user] == params["id"].to_i
        db = SQLite3::Database.new('db/blog.db')
        db.results_as_hash = true
        
        db.execute("INSERT INTO posts (writer, title, content) VALUES (?,?,?)", params["id"], params["title"], params["content"])
    end
    
    redirect("/user/#{params["id"]}")
end

post('/post/:postid/delete') do
    db = SQLite3::Database.new('db/blog.db')

    id = db.execute("SELECT writer FROM posts WHERE id=?", params["postid"])[0][0]

    if session[:user] == id.to_i
        db.execute("DELETE FROM posts WHERE id=?", params["postid"])
    end
    
    redirect back
end

get('/post/:postid/edit') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true

    users = db.execute("SELECT * FROM users")
    post = db.execute("SELECT writer, title, content FROM posts WHERE id=?", params["postid"])[0]

    if session[:user] == post["writer"].to_i
        slim(:edit_post, locals: {users: users, post: post})
    else
        redirect back
    end
end

post('/post/:postid/edit') do
    db = SQLite3::Database.new('db/blog.db')

    id = db.execute("SELECT writer FROM posts WHERE id=?", params["postid"])[0][0]

    if session[:user] == id.to_i
        db.execute("UPDATE posts SET title=?, content=? WHERE id=?", params["title"], params["content"], params["postid"])
    end
    
    redirect("/user/#{id}")
end