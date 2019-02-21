require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'

enable :sessions

get('/') do
    slim(:index)
end

get('/register') do
    slim(:register)
end

post('/register') do
    db = SQLite3::Database.new('db/blog.db')

    pass = BCrypt::Password.create(params["pass"])
    db.execute("INSERT INTO users (username, hashed_pass) VALUES (?,?)", params["username"], pass)

    redirect('/login')
end

get('/login') do
    slim(:login, locals: {fail: params[:fail]})
end

post('/login') do
    db = SQLite3::Database.new('db/blog.db')
    db.results_as_hash = true
    credentials = db.execute("SELECT hashed_pass FROM users WHERE username=?", params["username"])

    if credentials.length > 0 && BCrypt::Password.new(credentials[0]["hashed_pass"]) == params["pass"]
        session[:logged_in] = true
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

    user = db.execute("SELECT * FROM users WHERE id=?", params["id"])

    slim(:profile, locals: {user: user[0]})
end

get('/user/:id/edit') do
    if session[:user] == params["id"]
        db = SQLite3::Database.new('db/blog.db')
        db.results_as_hash = true

        user = db.execute("SELECT * FROM users WHERE id=?", params["id"])[0]

        slim(:edit_profile, locals: {name: user["username"]})
    else
        redirect("/user/#{params["id"]}")
    end
end

get('/user/:id/posts') do
    # WIP
end

=begin
get('*') do
    if request.path_info == "/login" || request.path_info == "/register" || session[:logged_in]
        pass
    else
        redirect('/login')
    end
end

post('*') do
    if request.path_info == "/login" || request.path_info == "/register" || request.path_info == "/logout" || session[:logged_in]
        pass
    else
        "ACCESS DENIED"
    end
end

get('/users') do
    db = SQLite3::Database.new('db/users.db')
    db.results_as_hash = true

    users = db.execute("SELECT * FROM users")

    db.results_as_hash = false
    departments = db.execute("SELECT title FROM departments")
    
    slim(:users, locals: {users: users, positions: departments})
end

get('/users/new') do
    slim(:create_user)
end

post('/users') do
    db = SQLite3::Database.new('db/users.db')
    db.results_as_hash = true

    departments = db.execute("SELECT * FROM departments")
    db.execute("INSERT INTO users (name, email, tel, department_id) VALUES (?,?,?,?)", params["name"], params["email"], params["tel"], (departments.find do |i| i["title"] == params["department"] end)["id"])
    
    redirect('/users')
end

post('/users/:id/delete') do
    db = SQLite3::Database.new('db/users.db')
    db.execute("DELETE FROM users WHERE id=?", params["id"])

    redirect('/users')
end

get('/users/:id') do
    db = SQLite3::Database.new('db/users.db')
    db.results_as_hash = true

    departments = db.execute("SELECT * FROM departments")
    user = db.execute("SELECT * FROM users WHERE id=?", params["id"])

    slim(:show_user, locals: {user: user[0], positions: departments})
end

get('/users/:id/update') do
    db = SQLite3::Database.new('db/users.db')
    db.results_as_hash = true

    user = db.execute("SELECT * FROM users WHERE id=?", params["id"])[0]

    slim(:update_user, locals: {name: user["name"], email: user["email"], tel: user["tel"], department: user["department_id"] - 1})
end

post('/users/:id/update') do
    db = SQLite3::Database.new('db/users.db')
    db.results_as_hash = true
    
    departments = db.execute("SELECT * FROM departments")
    db.execute("UPDATE users SET name=?, email=?, tel=?, department_id=? WHERE id=?", params["name"], params["email"], params["tel"], (departments.find do |i| i["title"] == params["department"] end)["id"], params["id"])

    redirect("/users/#{params["id"]}")
end
=end