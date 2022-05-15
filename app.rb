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
  if !check_login_status(session[:id])
    session[:error] = "Du måste vara inloggad för att se innehållet."
    redirect('/error')
  end
end

get('/movies') do
  result = get_movies()
  slim(:"todos/index",locals:{movies:result,is_admin:session[:is_admin]})
end

before('/movies/new') do
  if !check_login_status(session[:id]) or !check_admin_rights(session[:id])
    session[:error] = "Du har ej behörighet att visa detta innehåll"
    redirect('/error')
  end
end

get('/movies/new') do
  slim(:"todos/new")
end

post('/movies') do
  title = params[:title]
  studio_name = params[:studio_name]
  genres = [params[:genre1],
            params[:genre2],
            params[:genre3]]
  if title == "" or studio_name == "" or params[:genre1] == "" or params[:genre2] == "" or params[:genre3] == ""  or (params[:genre1] == params[:genre2] or params[:genre1] == params[:genre3] or params[:genre2] == params[:genre3])
    session[:error] = "Fälten får inte vara tomma"
    redirect('/error')
  end
  if !addMovie(title, studio_name, genres)
    session[:error] = "Ett fel uppstod när filmen skulle läggas till."
    redirect('/error')
  else
    redirect('/movies')
  end
end

before('/movies/:id') do
  if !check_login_status(session[:id])
    session[:error] = "Du måste vara inloggad för att se innehållet."
    redirect('/error')
  end
end

get('/movies/:id') do
  id = params[:id].to_i
  user_id = session[:id]
  info = get_movie_info(id)
  comments = get_game_comments(id)
  slim(:"todos/show",locals:{movie:info[0],studio:info[1],tags:info[2],comments:comments})
end

before('/movies/:id/edit') do
  if !check_login_status(session[:id]) or !check_admin_rights(session[:id])
    session[:error] = "Du har ej behörighet att visa detta innehåll"
    redirect('/error')
  end
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
  if title == "" or studio_name == "" or params[:tag1] == "" or params[:tag2] == "" or params[:tag3] == "" or (params[:tag1] == params[:tag2] or params[:tag1] == params[:tag3] or params[:tag2] == params[:tag3])
    session[:error] = "Fälten får inte vara tomma."
    redirect('/error')
  end
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
  if username == "" or password == ""
    session[:error] = "Fälten får inte vara tomma"
    redirect('/error')
  end
  if session[:last_login] != nil and Time.now - session[:last_login] < 5
    session[:error] = "Du loggade in för snabbt, försök igen senare."
    redirect('/error')
  end
  result = login_user(username, password)
  if result[0]
    session[:last_login] = Time.now
    session[:id] = result[2]
    session[:is_admin] = result[1]
    redirect('/movies')
  else
    session[:error] = "Fel användarnamn eller lösenord!"
    redirect('/error')
  end
end 

post('/users') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  usertype = params[:usertype].to_i
  admin_key = params[:admin_key]
  if username == "" or password == "" or password_confirm == "" or (usertype == 2 and admin_key == "")
    session[:error] = "Fälten får inte vara tomma."
    redirect('/error')
  end
  if !create_new_user(username, password, password_confirm, usertype, admin_key)
    session[:error] = "Ett fel uppstod när kontot skapades."
    redirect('/error')
  else
    redirect('/')
  end
end

get('/comments/:id/new') do
  session[:current_movie] = params[:id]
  slim(:"/comments/new")
end

post('/comments') do
  comment = params[:comment]
  movie_id = session[:current_movie]
  user_id = session[:id]
  if comment == ""
    session[:error] = "Fältet får inte vara tomt"
    redirect('/error')
  end
  add_comment(comment,movie_id,user_id)
  redirect('/movies')
end

get('/comments') do
  id = session[:id]
  comments = get_user_comments(id)
  slim(:"/comments/index",locals:{comments:comments})
end

post('/comments/:id/delete') do
  id = params[:id]
  if !check_comment_edit_rights(id,session[:id])
    session[:error] = "Du har inte behörighet"
    redirect('/error')
  end
  delete_comment(id)
  redirect('/movies')
end

before('/comments/:id/edit') do
  if !check_comment_edit_rights(params[:id],session[:id])
    session[:error] = "Du har inte behörighet"
    redirect('/error')
  end
end

get('/comments/:id/edit') do
  id = params[:id]
  comment = get_comment_info(id)
  slim(:"comments/edit",locals:{comment:comment})
end

post('/comments/:id/update') do
  id = params[:id]
  comment = params[:comment]
  if comment == ""
    session[:error] = "Fältet får inte vara tomt"
    redirect('/error')
  end
  edit_comment(id,comment)
  redirect('/movies')
end