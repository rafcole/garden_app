DROP TABLE plantings;
DROP TABLE users_gardens;
DROP TABLE gardens;
DROP TABLE users;

CREATE TABLE users(
  id serial PRIMARY KEY,
  user_name varchar(200) UNIQUE NOT NULL,
  pw_hash varchar(200) NOT NULL,
  email varchar(200) UNIQUE NOT NULL, 
  temp_user boolean DEFAULT false
);

CREATE TABLE gardens(
  id serial PRIMARY KEY,
  name varchar(200) NOT NULL,
  area_sq_ft decimal(5, 1) NOT NULL,
  "private" boolean default TRUE
);

CREATE TABLE users_gardens(
  id serial PRIMARY KEY,
  user_id int REFERENCES users(id) ON DELETE CASCADE,
  garden_id int REFERENCES gardens(id) ON DELETE CASCADE
);

CREATE TABLE plantings(
  id serial PRIMARY KEY,
  garden_id integer REFERENCES gardens(id) ON DELETE CASCADE,
  name varchar(200) NOT NULL,
  description text,
  num_plants int NOT NULL,
  area_per_plant_sq_ft decimal(3, 1) NOT NULL,
  planting_date date NOT NULL,
  grow_time decimal(4, 1) NOT NULL
);

INSERT INTO users(user_name, pw_hash, email) values ('Bill', 'idk', 'bill@williampickle.org');
INSERT INTO gardens(name, area_sq_ft) values('Front yard', 10), ('Back yard', 20), ('Barren', 5);
INSERT INTO users_gardens(user_id, garden_id) VALUES(1, 1), (1, 2);
INSERT INTO plantings(name, garden_id, description, num_plants, area_per_plant_sq_ft, planting_date, grow_time)
VALUES ('Broccoli', 1, 'v tasty', 5, 1.1, '2022-06-30', 5.5),
       ('Cabbage', 1, 'nappa', 4, 2.2, '2022-08-01', 2.5),
       ('Past plums', 2, 'canned', 1, 10, '2022-05-01', 5),
       ('Asparagus', 1, 'Cosmic crisp', 2, 20, '2022-01-01', 10);