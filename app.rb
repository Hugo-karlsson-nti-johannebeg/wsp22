require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'


enable :sessions

get('/') do
  slim(:register)
end

get('/showlogin') do
  slim(:login)
end

post('/login') do
  username = params[:username]
  session[:username] = username 
  password_confirm = params[:password_confirm]
  password = params[:password]
  db = SQLite3::Database.new('db/data.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  p "result is #{result}"
  password_from_db  = result["password"]
  id =result["id"]
  

  

  if BCrypt::Password.new(password_from_db) == password
    session[:id] = id
    redirect('/movies')
  else 
    "Fel Lösen"
  end
end 

post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  usertype = params[:usertype]
  db = SQLite3::Database.new('db/data.db')
  
  result = db.execute("SELECT id FROM users WHERE username = ?", username)

  if result.empty?
    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db.execute("INSERT INTO users (username,password,usertype) VALUES(?,?,?)", username,password_digest,usertype)
      redirect('/')
    
    
    else
      "lösenordet matchade inte"
    end
  else
    "Användaren finns redan"
  end

end

get('/movies') do
  if session[:id] == nil
    "Du måste logga in"
  else
    db = SQLite3::Database.new('db/data.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM movies")
    user = db.execute("SELECT usertype FROM users WHERE id = ?",session[:id]).first
    is_admin = user["usertype"] == 2
    slim(:"todos/index",locals:{movies:result,is_admin:is_admin})
  end
end

get('/movies/new') do
  if session[:id] == nil
    "Du måste logga in"
  else
    db = SQLite3::Database.new('db/data.db')
    db.results_as_hash = true
    result = db.execute("SELECT usertype FROM users WHERE id = ?",session[:id]).first
    if result["usertype"] == 2
      slim(:"todos/new")
    else
      "Du har ej behörighet"
    end
  end
end

post('/movies/new') do
  title = params[:title]
  studio_name = params[:studio_name]
  db = SQLite3::Database.new('db/data.db')
  db.results_as_hash = true
  studio = db.execute("SELECT studio_id FROM studios WHERE name = ?",studio_name).first
  if studio == nil
    db.execute("INSERT INTO studios (name) VALUES (?)",studio_name)
    studio = db.execute("SELECT studio_id FROM studios WHERE name = ?",studio_name).first
  end
  result = db.execute("SELECT * FROM movies WHERE title = ?",title)
  if result.empty?
    db.execute("INSERT INTO movies (title,studio_id) VALUES (?,?)",title,studio["studio_id"])
    redirect('/movies')
  else
    "Filmen finns redan!"
  end
end