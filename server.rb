require 'sinatra'
require 'pg'
require 'sinatra/reloader'
require 'pry'


def connect
  begin
    connection = PG.connect(dbname: 'movies')
    yield(connection)
  ensure
    connection.close
  end
end


get '/actors' do
  @results = nil
  connect do |connection|
   @results =  connection.exec('SELECT name, id FROM actors ORDER BY name')
 end
 erb :'/actors/index'
end

get '/actors/:id' do
  @results = nil

  connect do |connection|
   @results =  connection.exec_params(
    'SELECT movies.title, cast_members.character, movies.id, actors.name
     FROM movies
     JOIN cast_members ON cast_members.movie_id = movies.id
     JOIN actors ON actors.id = cast_members.actor_id
     WHERE actors.id = $1', [params["id"]])
 end
 erb :'/actors/show'
end

get '/movies' do
  @results = nil
  sort_by = params["sort_by"]
  sort_by = "movies" if params["sort_by"] == nil
    query =
    'SELECT movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio, movies.id
    FROM movies
    JOIN genres ON genres.id = movies.genre_id
    JOIN studios ON studios.id = movies.studio_id'
  query += " ORDER BY movies.title" if sort_by == "movies"
  query += " ORDER BY movies.year" if sort_by == "year"
  query += " ORDER BY movies.rating DESC" if sort_by == "rating"
  query += " ORDER BY genres.name" if sort_by == "genre"
  query += " ORDER BY studios.name" if sort_by == "studio"
  connect do |connection|
   @results =  connection.exec(query)
  end
  erb :'/movies/index'
end

get '/movies/:id' do
  @results = nil
  id = params["id"]
  query = 'SELECT movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio, movies.id, movies.synopsis, cast_members.character, actors.name AS actor_name, actors.id
      FROM movies
      JOIN genres ON genres.id = movies.genre_id
      JOIN studios ON studios.id = movies.studio_id
      JOIN cast_members ON cast_members.movie_id = movies.id
      JOIN actors ON actors.id = cast_members.actor_id
      WHERE movies.id = ' + id
  connect do |connection|
    @results = connection.exec(query)
  end
  erb :'/movies/show'
end

# Visiting `/actors/:id` will show the details for a given actor.
# This page should contain a list of movies that the actor has starred in and what their role was. Each movie should link to the details page for that movie.
