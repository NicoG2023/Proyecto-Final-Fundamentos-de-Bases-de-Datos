--WORKSHOP 4
--NICOLAS GUEVARA HERRAN
--CREACION DE TABLAS

create table if not exists Country(
	code int,
	name varchar(25) unique not null,
	primary key(code)
);

create table if not exists MusicalGenre(
	id_genre serial,
	name varchar(15) not null,
	description varchar(100),
	primary key(id_genre)
);

create table if not exists Community(
	id_community serial,
	name varchar(25) unique not null,
	description varchar(200),
	primary key(id_community)
);

create table if not exists Users(
	id_number uuid,
	name varchar(50) not null,
	email varchar(30) unique,
	phone varchar(50),
	nickname varchar(20) unique not null,
	password varchar(30) not null,
	musical_genre_fk int not null,
	country_fk int not null,
	primary key(id_number),
	foreign key(musical_genre_fk) references MusicalGenre(id_genre),
	foreign key(country_fk) references Country(code)
);

create table if not exists Channel(
	id_channel serial,
	name varchar(30),
	description varchar(200),
	user_fk uuid,
	primary key(id_channel),
	foreign key(user_fk) references Users(id_number)
);

create table if not exists Video(
	id_videos serial,
	name varchar(100) not null,
	description varchar(200),
	date_upload int not null,
	likes int default 0,
	dislikes int default 0,
	popular bool default false,
	user_fk uuid,
	genre_fk int,
	channel_fk int,
	primary key(id_videos),
	foreign key(user_fk) references Users(id_number),
	foreign key(genre_fk) references MusicalGenre(id_genre),
	foreign key(channel_fk) references Channel(id_channel)
);

create table if not exists BankAccount(
	UniqueID serial,
	bank_name varchar(50) not null,
	account_number bigint not null,
	country_fk int,
	user_fk uuid,
	primary key(UniqueID),
	foreign key(country_fk) references Country(code),
	foreign key(user_fk) references Users(id_number)
);

create table if not exists Comment(
	Id_comment serial,
	content varchar(300) not null,
	date_creation int not null,
	likes int default 0,
	dislikes int default 0,
	user_fk uuid,
	video_fk int,
	primary key(Id_comment),
	foreign key(user_fk) references Users(id_number),
	foreign key(video_fk) references Video(id_videos)
);


create table if not exists Playlist(
	id_playlist serial,
	name varchar(30) not null,
	likes int default 0,
	user_fk uuid,
	primary key(id_playlist),
	foreign key(user_fk) references Users(id_number)
);

create table if not exists Playlist_Video_REL(
	playlist_fk int,
	video_fk int,
	primary key(playlist_fk, video_fk),
	foreign key(playlist_fk) references Playlist(id_playlist),
	foreign key(video_fk) references Video(id_videos)
);

create table if not exists community_user_REL(
	community_fk int,
	user_fk uuid,
	expiration_date int,
	primary key(community_fk, user_fk),
	foreign key(community_fk) references Community(id_community),
	foreign key(user_fk) references Users(id_number)
);

create table if not exists Subscriber_REL(
	user_fk uuid,
	channel_fk int,
	pay bool default false,
	pay_cost float,
	date_subscriptions int not null,
	primary key(user_fk, channel_fk),
	foreign key(user_fk) references Users(id_number),
	foreign key(channel_fk) references Channel(id_channel)
);

--INSERCION DE DATOS

insert into Country(code,name) values(1,'Colombia');
insert into Country(code,name) values(2,'Argentina');
insert into Country(code,name) values(3,'Italia');
insert into Country(code,name) values(4,'Polonia');
insert into Country(code,name) values(5,'Brasil');

INSERT INTO MusicalGenre (id_genre, name, description) VALUES (1, 'Pop', 'A genre characterized by its mainstream appeal and catchy rhythms.');
INSERT INTO MusicalGenre (id_genre, name, description) VALUES (2, 'Rock', 'A genre characterized by a strong rhythm and often features electric guitar.');
INSERT INTO MusicalGenre (id_genre, name, description) VALUES (3, 'Jazz', 'A genre known for its improvisation and complex rhythms.');
INSERT INTO MusicalGenre (id_genre, name, description) VALUES (4, 'Classical', 'A genre rooted in Western liturgical and secular music.');
INSERT INTO MusicalGenre (id_genre, name, description) VALUES (5, 'Hip Hop', 'A genre featuring rhythmic and rhyming speech known as rapping.');

INSERT INTO Community (id_community, name, description) VALUES (1, 'Music Lovers', 'A community for people who enjoy all types of music.');
INSERT INTO Community (id_community, name, description) VALUES (2, 'Jazz Enthusiasts', 'A place for fans of jazz music to share and discuss.');
INSERT INTO Community (id_community, name, description) VALUES (3, 'Rock Legends', 'Dedicated to fans of rock music and its history.');
INSERT INTO Community (id_community, name, description) VALUES (4, 'Classical Appreciation', 'For those who love and appreciate classical music.');
INSERT INTO Community (id_community, name, description) VALUES (5, 'Hip Hop Heads', 'A community for fans of hip hop music and culture.');

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";--Para generar UUID

INSERT INTO Users (id_number, name, email, phone, nickname, password, musical_genre_fk, country_fk) VALUES 
(uuid_generate_v4(), 'Alice Johnson', 'alice.johnson@example.com', '123-456-7890', 'alicej', 'password123', 1, 1),
(uuid_generate_v4(), 'Bob Smith', 'bob.smith@example.com', '234-567-8901', 'bobby', 'password456', 2, 2),
(uuid_generate_v4(), 'Carol White', 'carol.white@example.com', '345-678-9012', 'carolw', 'password789', 3, 1),
(uuid_generate_v4(), 'David Brown', 'david.brown@example.com', '456-789-0123', 'daveb', 'password012', 4, 3),
(uuid_generate_v4(), 'Eve Black', 'eve.black@example.com', '567-890-1234', 'eveb', 'password345', 5, 2),
(uuid_generate_v4(), 'Frank Green', 'frank.green@example.com', '678-901-2345', 'frankg', 'password678', 1, 3),
(uuid_generate_v4(), 'Grace Blue', 'grace.blue@example.com', '789-012-3456', 'graceb', 'password901', 2, 1),
(uuid_generate_v4(), 'Hank Yellow', 'hank.yellow@example.com', '890-123-4567', 'hanky', 'password234', 3, 2),
(uuid_generate_v4(), 'Ivy Red', 'ivy.red@example.com', '901-234-5678', 'ivyr', 'password567', 4, 3),
(uuid_generate_v4(), 'Jack Purple', 'jack.purple@example.com', '012-345-6789', 'jackp', 'password890', 5, 1);

select * from users u ;

INSERT INTO Channel (id_channel, name, description, user_fk) VALUES (1, 'Rock Vibes', 'All about rock music from classic to modern.', 'ee5c92bb-d0fd-4679-9696-6a79a625045d');
INSERT INTO Channel (id_channel, name, description, user_fk) VALUES (2, 'Jazz Lounge', 'A place to relax and enjoy smooth jazz.', 'a3a0e696-1f6d-4e24-a123-f9123e0d6526');
INSERT INTO Channel (id_channel, name, description, user_fk) VALUES (3, 'Classical Harmony', 'Exploring the world of classical music.', '2e87f23d-232a-4369-a69f-ef4b76bc3015');
INSERT INTO Channel (id_channel, name, description, user_fk) VALUES (4, 'Hip Hop Beats', 'The latest and greatest in hip hop music.', 'f1e8e421-e749-4c01-ac5c-b9eb00b84599');
INSERT INTO Channel (id_channel, name, description, user_fk) VALUES (5, 'Pop Hits', 'Top pop songs and chart-toppers.', 'f01c3f6a-2cba-4ff7-b44a-c526bd55b453');

select * from channel c ;

select * from musicalgenre m ;
select * from channel c ;

select * from video v ;

INSERT INTO Video (id_videos, name, description, date_upload, likes, dislikes, popular, user_fk, genre_fk, channel_fk) VALUES 
(1, 'Rock Legends Live', 'A live performance of classic rock legends.', 20220115, 150, 10, true, 'ee5c92bb-d0fd-4679-9696-6a79a625045d', 2, 1);

INSERT INTO Video (id_videos, name, description, date_upload, likes, dislikes, popular, user_fk, genre_fk, channel_fk) VALUES 
(2, 'Smooth Jazz Night', 'A soothing jazz performance to relax your evening.', 20220210, 200, 5, true, 'a3a0e696-1f6d-4e24-a123-f9123e0d6526', 3, 2);

INSERT INTO Video (id_videos, name, description, date_upload, likes, dislikes, popular, user_fk, genre_fk, channel_fk) VALUES 
(3, 'Classical Symphony', 'An amazing symphony orchestra performing classical pieces.', 20220305, 300, 8, true, '2e87f23d-232a-4369-a69f-ef4b76bc3015', 4, 3);

INSERT INTO Video (id_videos, name, description, date_upload, likes, dislikes, popular, user_fk, genre_fk, channel_fk) VALUES 
(4, 'Hip Hop Battle', 'An intense hip hop rap battle between top artists.', 20220412, 250, 20, true, 'f01c3f6a-2cba-4ff7-b44a-c526bd55b453', 5, 4);

INSERT INTO Video (id_videos, name, description, date_upload, likes, dislikes, popular, user_fk, genre_fk, channel_fk) VALUES 
(5, 'Top Pop Hits', 'Compilation of the top pop hits of the month.', 20220520, 400, 15, true, 'f01c3f6a-2cba-4ff7-b44a-c526bd55b453', 1, 5);

INSERT INTO Video (id_videos, name, description, date_upload, likes, dislikes, popular, user_fk, genre_fk, channel_fk) VALUES 
(6, 'Rock Guitar Solo', 'A mesmerizing guitar solo by a rock legend.', 20220618, 350, 5, true, 'ee5c92bb-d0fd-4679-9696-6a79a625045d', 2, 1);

INSERT INTO Video (id_videos, name, description, date_upload, likes, dislikes, popular, user_fk, genre_fk, channel_fk) VALUES 
(7, 'Jazz Improv', 'An impromptu jazz session with talented musicians.', 20220715, 280, 3, true, 'a3a0e696-1f6d-4e24-a123-f9123e0d6526', 3, 2);

INSERT INTO Video (id_videos, name, description, date_upload, likes, dislikes, popular, user_fk, genre_fk, channel_fk) VALUES 
(8, 'Classical Ensemble', 'A beautiful performance by a classical music ensemble.', 20220810, 220, 6, false, '2e87f23d-232a-4369-a69f-ef4b76bc3015', 4, 3);

INSERT INTO Video (id_videos, name, description, date_upload, likes, dislikes, popular, user_fk, genre_fk, channel_fk) VALUES 
(9, 'Hip Hop Dance Off', 'An energetic hip hop dance competition.', 20220905, 310, 12, true, 'f1e8e421-e749-4c01-ac5c-b9eb00b84599', 5, 4);

INSERT INTO Video (id_videos, name, description, date_upload, likes, dislikes, popular, user_fk, genre_fk, channel_fk) VALUES 
(10, 'Pop Music Video', 'A new music video from a top pop artist.', 20221001, 500, 25, true, 'f01c3f6a-2cba-4ff7-b44a-c526bd55b453', 1, 5);


INSERT INTO BankAccount (UniqueID, bank_name, account_number, country_fk, user_fk) VALUES 
(1, 'Bank of America', 1234567890123456, 1, 'ee5c92bb-d0fd-4679-9696-6a79a625045d');

INSERT INTO BankAccount (UniqueID, bank_name, account_number, country_fk, user_fk) VALUES 
(2, 'Wells Fargo', 2345678901234567, 2, 'a3a0e696-1f6d-4e24-a123-f9123e0d6526');

INSERT INTO BankAccount (UniqueID, bank_name, account_number, country_fk, user_fk) VALUES 
(3, 'Chase Bank', 3456789012345678, 1, '2e87f23d-232a-4369-a69f-ef4b76bc3015');

INSERT INTO BankAccount (UniqueID, bank_name, account_number, country_fk, user_fk) VALUES 
(4, 'Citibank', 4567890123456789, 3, 'f1e8e421-e749-4c01-ac5c-b9eb00b84599');

INSERT INTO BankAccount (UniqueID, bank_name, account_number, country_fk, user_fk) VALUES 
(5, 'HSBC', 5678901234567890, 2, 'f01c3f6a-2cba-4ff7-b44a-c526bd55b453');

select * from bankaccount b ;
select * from video v ;

INSERT INTO Comment (Id_comment, content, date_creation, likes, dislikes, user_fk, video_fk) VALUES 
(1, 'Amazing performance! Loved every second of it.', 20230115, 45, 2, 'ee5c92bb-d0fd-4679-9696-6a79a625045d', 1);

INSERT INTO Comment (Id_comment, content, date_creation, likes, dislikes, user_fk, video_fk) VALUES 
(2, 'This jazz session is so relaxing. Great job!', 20230210, 30, 1, '2e87f23d-232a-4369-a69f-ef4b76bc3015', 2);

INSERT INTO Comment (Id_comment, content, date_creation, likes, dislikes, user_fk, video_fk) VALUES 
(3, 'What a fantastic symphony! Truly a masterpiece.', 20230305, 50, 3, 'a3a0e696-1f6d-4e24-a123-f9123e0d6526', 3);

INSERT INTO Comment (Id_comment, content, date_creation, likes, dislikes, user_fk, video_fk) VALUES 
(4, 'The energy in this hip hop battle is incredible!', 20230412, 60, 5, 'f01c3f6a-2cba-4ff7-b44a-c526bd55b453', 4);

INSERT INTO Comment (Id_comment, content, date_creation, likes, dislikes, user_fk, video_fk) VALUES 
(5, 'These pop hits are so catchy! Can’t stop listening.', 20230520, 80, 4, 'f01c3f6a-2cba-4ff7-b44a-c526bd55b453', 5);

INSERT INTO Comment (Id_comment, content, date_creation, likes, dislikes, user_fk, video_fk) VALUES 
(6, 'These pop hits are so ugly!', 202305145, 12, 36, 'f01c3f6a-2cba-4ff7-b44a-c526bd55b453', 5);


select * from comment;
select * from channel c ;

INSERT INTO Playlist (id_playlist, name, likes, user_fk) VALUES 
(1, 'Rock Classics', 120, 'ee5c92bb-d0fd-4679-9696-6a79a625045d');

INSERT INTO Playlist (id_playlist, name, likes, user_fk) VALUES 
(2, 'Smooth Jazz Collection', 95, 'a3a0e696-1f6d-4e24-a123-f9123e0d6526');

INSERT INTO Playlist (id_playlist, name, likes, user_fk) VALUES 
(3, 'Classical Masterpieces', 110, '2e87f23d-232a-4369-a69f-ef4b76bc3015');

INSERT INTO Playlist (id_playlist, name, likes, user_fk) VALUES 
(4, 'Hip Hop Hits', 150, 'f1e8e421-e749-4c01-ac5c-b9eb00b84599');

INSERT INTO Playlist (id_playlist, name, likes, user_fk) VALUES 
(5, 'Pop Favorites', 130, 'f01c3f6a-2cba-4ff7-b44a-c526bd55b453');

select * from playlist p ;
select * from video v ;

INSERT INTO Playlist_Video_REL (playlist_fk, video_fk) VALUES 
(1, 1);

INSERT INTO Playlist_Video_REL (playlist_fk, video_fk) VALUES 
(1, 6);

INSERT INTO Playlist_Video_REL (playlist_fk, video_fk) VALUES 
(2, 2);

INSERT INTO Playlist_Video_REL (playlist_fk, video_fk) VALUES 
(3, 3);

INSERT INTO Playlist_Video_REL (playlist_fk, video_fk) VALUES 
(4, 4);

select * from users u ;
select * from community c ;
select * from channel c ;

INSERT INTO community_user_REL (community_fk, user_fk, expiration_date) VALUES 
(1, 'f01c3f6a-2cba-4ff7-b44a-c526bd55b453', 20231231);

INSERT INTO community_user_REL (community_fk, user_fk, expiration_date) VALUES 
(2, 'a3a0e696-1f6d-4e24-a123-f9123e0d6526', 20231231);

INSERT INTO community_user_REL (community_fk, user_fk, expiration_date) VALUES 
(3, 'ee5c92bb-d0fd-4679-9696-6a79a625045d', 20231231);

INSERT INTO community_user_REL (community_fk, user_fk, expiration_date) VALUES 
(4, '2e87f23d-232a-4369-a69f-ef4b76bc3015', 20231231);

INSERT INTO community_user_REL (community_fk, user_fk, expiration_date) VALUES 
(5, 'f1e8e421-e749-4c01-ac5c-b9eb00b84599', 20231231);


select * from channel c ;

INSERT INTO Subscriber_REL (user_fk, channel_fk, pay, pay_cost, date_subscriptions) VALUES 
('2e87f23d-232a-4369-a69f-ef4b76bc3015', 1, true, 9.99, 20230101);

INSERT INTO Subscriber_REL (user_fk, channel_fk, pay, pay_cost, date_subscriptions) VALUES 
('ee5c92bb-d0fd-4679-9696-6a79a625045d', 2, false, 0.00, 20230215);

INSERT INTO Subscriber_REL (user_fk, channel_fk, pay, pay_cost, date_subscriptions) VALUES 
('a3a0e696-1f6d-4e24-a123-f9123e0d6526', 3, true, 12.99, 20230310);

INSERT INTO Subscriber_REL (user_fk, channel_fk, pay, pay_cost, date_subscriptions) VALUES 
('f1e8e421-e749-4c01-ac5c-b9eb00b84599', 4, false, 0.00, 20230425);

INSERT INTO Subscriber_REL (user_fk, channel_fk, pay, pay_cost, date_subscriptions) VALUES 
('f01c3f6a-2cba-4ff7-b44a-c526bd55b453', 5, true, 7.99, 20230505);

select * from subscriber_rel sr ;

--BUSQUEDAS

--1 All the videos uploaded for any user from an specific country
SELECT v.name AS video_name, v.description AS video_description, v.date_upload, v.likes,
    v.dislikes, v.popular, u.name AS user_name, c.name AS country_name
FROM 
    Video v
JOIN 
    Users u ON v.user_fk = u.id_number
JOIN 
    Country c ON u.country_fk = c.code
WHERE 
    c.name = 'Colombia'; -- para este caso se escoge como pais colombia
    
-- 2. Show the available music genre and count how many videos there are per genre
select * from musicalgenre m ;
select * from video v ;

select m.name as genre_name, count(v.id_videos) as num_videos from musicalgenre m
join Video v on m.id_genre = v.genre_fk 
group by m."name" ;

--3 Show the information of all videos, adding the name and email of the user who uploaded it, with more than 20 likes.

select * from video v ;
select * from users u ;

select v.name as video_name, v.description, v.likes, v.dislikes, u.name as user_name, u.email 
from Video v
join Users u on v.user_fk = u.id_number 
where v.likes > 20;

--4 Show all channels that have at least one subscriber from a specific country.

select * from country c ;
select * from users u ;
select * from channel c ;
select * from subscriber_rel sr ;

select c.name as channel_name, c.description  from channel c
join subscriber_rel sr  on sr.channel_fk = c.id_channel 
join users u  on sr.user_fk = u.id_number 
join country c2 on u.country_fk = c2.code 
where c2."name" = 'Italia';

--5 Show all the comments with the related user and video information, where the comment has the word: ugly
select * from "comment" c ;

select c.content as comment_content, u.name as user_name, v.name as video_name from "comment" c
join users u on c.user_fk = u.id_number 
join video v on c.video_fk = v.id_videos 
where c."content" like '%ugly%';

--6 Show the first three users with all the related information for country, bank account,
--and prefered musical genre, order by email.

select u.id_number, u.name as user_name, u.email, u.nickname, c.name as country_name, b.bank_name,
b.account_number, m.name as musical_genre_name, m.description as genre_description
from users u 
join country c on u.country_fk = c.code 
join bankaccount b on u.id_number = b.user_fk 
join musicalgenre m on m.id_genre = u.musical_genre_fk 
order by u.email limit 3;

--NICOLAS GUEVARA HERRAN 