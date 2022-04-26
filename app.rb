require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions

get('/') do
  slim(:register)
end

get('/showlogin') do
  slim(:login)
end

get('/error') do
  slim(:error)
end

before('/movies') do
  check_login_status()
end

get('/movies') do
  result = get_movies()
  slim(:"todos/index",locals:{movies:result,is_admin:session[:is_admin]})
end

before('/movies/new') do
  check_login_status()
  check_admin_rights()
end

get('/movies/new') do
  slim(:"todos/new")
end

post('/movies/new') do
  title = params[:title]
  studio_name = params[:studio_name]
  genres = [params[:genre1],
            params[:genre2],
            params[:genre3]]
  addMovie(title, studio_name, genres)
end

before('/movies/:id') do
  check_login_status()
end

get('/movies/:id') do
  id = params[:id]
  info = get_movie_info(id)
  slim(:"todos/show",locals:{movie:info[0],studio:info[1],tags:info[2]})
end

before('/movies/:id/edit') do
  check_login_status()
  check_admin_rights()
end

get('/movies/:id/edit') do
  id = params[:id]
  info = get_movie_info(id)
  slim(:"todos/edit",locals:{movie:info[0],studio:info[1],tags:info[2]})
end

post('/movies/:id/update') do
  id = params[:id].to_i
  title = params[:title]
  studio_name = params[:studio_name]
  genres = [
      params[:tag1],
      params[:tag2],
      params[:tag3]
  ]
  update_movie_info(id, title, genres, studio_name)
  redirect('/movies')
end

post('/movies/:id/delete') do
  id = params[:id].to_i
  movie_delete(id)
  redirect('/movies')
end

post('/login') do
  username = params[:username]
  password = params[:password]
  login_user(username, password)
end 

post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  usertype = params[:usertype].to_i
  admin_key = params[:admin_key]
  create_new_user(username, password, password_confirm, usertype, admin_key)
end
