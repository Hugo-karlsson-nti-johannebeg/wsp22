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
  password = result["password"]
  id =result["id"]
  

  

  if BCrypt::Password.new(password) == password
    session[:id] = id
    redirect('/todos')
  else 
    "Fel Lösen"
  end
  redirect('/')
end 

get('/todos') do
  id = session[:id].to_i
  db = SQLite3::Database.new('db/data.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM todos WHERE user_id = ?",id)
  slim(:"todos/index",locals:{todos:result})
end




post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/data.db')
    db.execute("INSERT INTO users (username,password,usertype) VALUES(?,?,?)", username,password,1)
    redirect('/')


  else
    "lösenordet matchade inte"
  end

end