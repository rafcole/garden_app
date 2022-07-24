DROP TABLE plantings;
DROP TABLE users_gardens;
DROP TABLE gardens;
DROP TABLE users;

CREATE TABLE users(
  id serial PRIMARY KEY,
  user_name varchar(200) UNIQUE NOT NULL,
  pw_hash varchar(200),
  email varchar(200) UNIQUE NOT NULL
);

CREATE TABLE gardens(
  id serial PRIMARY KEY,
  name varchar(200) NOT NULL,
  area_sq_ft decimal(5, 1) NOT NULL,
  private boolean default true
);

CREATE TABLE users_gardens(
  id serial PRIMARY KEY,
  user_id int REFERENCES users(id) ON DELETE CASCADE,
  garden_id int REFERENCES gardens(id) ON DELETE CASCADE
);

CREATE TABLE plantings(
  id serial PRIMARY KEY,
  name varchar(200) NOT NULL,
  description text,
  num_plants int NOT NULL,
  area_per_plant_sq_ft decimal(3, 1) NOT NULL,
  planting_date date NOT NULL,
  grow_time decimal(4, 1) NOT NULL
);