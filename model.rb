
def connect_to_database(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

def check_login_status()
    if session[:id] == nil
        session[:error] = "Du måste logga in för att se detta innehåll!"
        redirect('/error')
    end
end

def check_admin_rights()
    if !session[:is_admin]
        session[:error] = "Du har inte behörighet att se innehållet"
        redirect('/error')
    end
end

def get_movie_info(id)
    db = connect_to_database('db/data.db')
    result = db.execute("SELECT * FROM movies WHERE id = ?",id).first
    studio = db.execute("SELECT * FROM studios WHERE studio_id = ?",result["studio_id"]).first
    tags = db.execute("SELECT name FROM genres INNER JOIN movie_genre_rel ON genres.id == movie_genre_rel.genre_id WHERE movie_genre_rel.movie_id = ?",id)
    return [result, studio, tags]
end

def get_movies()
    db = connect_to_database('db/data.db')
    result = db.execute("SELECT * FROM movies")
end

def addMovie(title, studio_id, genres)
    db = connect_to_database('db/data.db')
    studio = db.execute("SELECT studio_id FROM studios WHERE name = ?",studio_name).first
    if studio == nil
      db.execute("INSERT INTO studios (name) VALUES (?)",studio_name)
      studio = db.execute("SELECT studio_id FROM studios WHERE name = ?",studio_name).first
    end
    result = db.execute("SELECT * FROM movies WHERE title = ?",title)
    if result.empty?
      db.execute("INSERT INTO movies (title,studio_id) VALUES (?,?)",title,studio["studio_id"])
      movie = db.execute("SELECT id FROM movies WHERE title = ?",title).first
      genres.each do |genre|
        temp = db.execute("SELECT id FROM genres WHERE name = ?",genre).first
        db.execute("INSERT INTO movie_genre_rel (movie_id,genre_id) VALUES (?,?)",movie["id"],temp["id"])
      end
      redirect('/movies')
    else
      session[:error] = "Filmen finns redan!"
      redirect('/error')
    end
end

def update_movie_info(id, title, genres, studio_name)
    db = connect_to_database('db/data.db')
    result = db.execute("SELECT studio_id FROM studios WHERE name = ?",studio_name).first
    if result == nil
        db.execute("INSERT INTO studios (name) VALUES (?)",studio_name)
        result = db.execute("SELECT studio_id FROM studios WHERE name = ?",studio_name).first
    end
    movie = db.execute("SELECT id FROM movies WHERE title = ?",title).first
    db.execute("UPDATE movies SET title=?,studio_id=? WHERE id = ?",title,result["studio_id"],id)
    currentgenres = db.execute("SELECT genre_id FROM movie_genre_rel WHERE movie_id = ?",id)
    genres_id = []
    genres.each do |currentgenre|
        genres_id.append(db.execute("SELECT id FROM genres WHERE name = ?",currentgenre).first)
    end
    relations = []
    currentgenres.each do |currentgenre|
        relations.append(db.execute("SELECT id FROM movie_genre_rel WHERE movie_id = ? AND genre_id = ?",movie["id"],currentgenre["genre_id"]).first)
    end
    i = 0
    while i < 3
        p genres_id[i]
        p relations[i]
        db.execute("UPDATE movie_genre_rel SET genre_id = ? WHERE id = ?",genres_id[i]["id"],relations[i]["id"])
        i += 1
    end
end

def movie_delete(id)
    db = connect_to_database('db/data.db')
    db.execute("DELETE FROM movies WHERE id = ?",id)
    db.execute("DELETE FROM movie_genre_rel WHERE movie_id = ?",id)
end

def login_user(username, password)
    db = connect_to_database('db/data.db')
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    if result == nil
        session[:error] = "Fel användarnamn eller lösenord!"
        redirect('/error')
    end
    password_from_db  = result["password"]
    id = result["id"]
    if BCrypt::Password.new(password_from_db) == password
      session[:id] = id
      is_admin = result["usertype"]
      if is_admin == 2
        session[:is_admin] = true
      end
      redirect('/movies')
    else 
      session[:error] = "Fel användarnamn eller lösenord!"
      redirect('/error')
    end
end

def create_new_user(username, password, password_confirm, usertype, admin_key)
    current_admin_key = "NTI2022"
    if usertype == 2 && admin_key != current_admin_key
      session[:error] = "Fel Admin-Nyckel"
      redirect('/error')
    end
    db = connect_to_database('db/data.db')
    result = db.execute("SELECT id FROM users WHERE username = ?", username)
    if result.empty?
      if (password == password_confirm)
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO users (username,password,usertype) VALUES(?,?,?)", username,password_digest,usertype)
        redirect('/')
      else
        session[:error] = "lösenordet matchade inte"
        redirect('/error')
      end
    else
      session[:error] = "Användaren finns redan"
      redirect('/error')
    end
end