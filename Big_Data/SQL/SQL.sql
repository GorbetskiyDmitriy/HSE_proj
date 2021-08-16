/* 1. Жанровые фильмы. */

-- SQL 1

/* Создаю таблицу в которой содержатся уже необходимые сведения по каждому жанру фильма.
В подзапросе из графы genres достаются все отдельные жанры и переписываются в разные строки.
Далее считается количество фильмов каждого жанра и создается таблица */


CREATE TABLE genre_films USING PARQUET AS

SELECT genre
	,count(genre) AS n_films
FROM (
	SELECT explode(split(genres, '[,]', - 1)) AS genre
	FROM title_basics_csv
	)
GROUP BY 1;

-- SQL 2

/* Обычный select * с условием, ничего необычно */

SELECT *
FROM genre_films
WHERE genre = 'Horror';

/* 2.Хорошие жанровые фильмы. */

-- SQL 1

/* Тут все очень похоже на предыдущее задание. В подзапросе мы опять из колонки genres достаем все отдельные жанры и переписываются в разные строки. 
Потом мы к каждому фильму из таблицы title_ratings_csv джойним рейтинг фильма и создаем отдельную таблицу с результатами. 
Потому что фильтр у нас может быть по рейтингу, то полностью готовую таблицу мы не можем создать, только таблицу, к которой может быть применен минимальный запрос */

CREATE TABLE good_genre_films USING PARQUET AS

SELECT genre
	,averageRating
	,numVotes
FROM (
	SELECT tconst
		,explode(split(genres, '[,]', - 1)) AS genre
	FROM title_basics_csv
	) AS req
INNER JOIN title_ratings_csv AS tab
	ON tab.tconst = req.tconst;
	
/* Простой запрос с небольшими условиями*/

-- SQL 2
SELECT genre
	,count(genre) AS n_films
	,max(numVotes) AS max_n_votes
FROM good_genre_films
WHERE averageRating >= 4
	AND genre = 'Thriller'
GROUP BY 1;

/*3.И швец, и жнец.*/

-- SQL 1.1

/* Для начала найдем все фильмы, где режиссер и сценарист один и тот же человек:
 1. Дня начала выкинем все записи, где есть NULL
 2. Достаем всех режиссеров из одной колонки и переносим записи в новые строки
 3. Делаем тоже самое для сценаристов
 4. Оставляем только записи, где режиссер и сценарист один и тот же человек*/

CREATE TABLE writer_director USING PARQUET AS

SELECT *
FROM (
	SELECT tconst
		,director
		,explode(split(writers, '[,]', - 1)) AS writer
	FROM (
		SELECT tconst
			,explode(split(directors, '[,]', - 1)) AS director
			,writers
		FROM (
			SELECT *
			FROM title_crew_csv
			WHERE directors IS NOT NULL
				AND writers IS NOT NULL
			) a
		) b
	) c
WHERE director = writer;

-- SQL 1.2

/*Создаем таблицу со всеми фильмами и переводом их названия на русский.
1. Проделываем опять операцию с жанрами
2. Соединяем полученную таблицу с title_akas_csv и оставляем только необходимые поля*/

CREATE TABLE film_genre USING PARQUET AS

SELECT tconst
	,primaryTitle
	,title
	,genre
FROM (
	SELECT tconst
		,primaryTitle
		,explode(split(genres, '[,]', - 1)) AS genre
	FROM title_basics_csv
	) AS req
LEFT JOIN (
	SELECT titleId
		,title
	FROM title_akas_csv
	WHERE region = 'RU'
	) AS tab
	ON req.tconst = tab.titleId;

-- SQL 1.3

/* Соединяем две таблицы воедино, оставляем только необходимые поля:
из первой таблицы достаем только режиссера (сценарист у нас тот же) и объединяем с его идентификатор с его именем
оставляем только жанр фильма, имя режиссера (сценариста), наименование фильма и наименование фильма на русском*/

CREATE TABLE writer_director_frame USING PARQUET AS

SELECT genre
	,primaryName
	,primaryTitle
	,title
FROM film_genre AS req
INNER JOIN (
	SELECT tconst
		,primaryName
	FROM writer_director AS req
	INNER JOIN name_basics_csv AS tab
		ON req.director = tab.nconst
	) AS tab
	ON req.tconst = tab.tconst;

-- SQL 2

/*Опять очень простой запрос вида select * с нужным фильтром*/

SELECT *
FROM writer_director_frame
WHERE genre = 'Drama';

/*4.Лучший в своем жанре.*/

-- SQL 1.1

/*Найдем для начала лучшие фильмы в каждом из существующих жанров:
1. В самом первом подзапросе делаем простой финт ушами и расписываем genres построчно. Достаем наименование фильма и его жанр
2. Каждый фильм соединяем с таблицей с рейтингом (title_ratings_csv). Теперь у нас каждый фильм имеет свой жанр, рейтинг, количество голосов и id фильма в виде INTEGER
3. Теперь ко всему этому применяем оконную функцию ROW_NUMBER() с сортировкой по условию (максимальная средняя оценка, если оценки одинаковые, 
то выбрать по наибольшему количеству оценок (numVotes), потом по наименьшему идентификатору фильма tconst)
4. Выбираем фильмы, которые имеют номер строки равный = 1. Таким образом мы получили лучший фильм в каждом жанре.
Как жаль, что это не терадата и простым qualify здесь не отделаешься без подзапроса.*/

CREATE TABLE best_in_genre USING PARQUET AS

SELECT *
FROM (
	SELECT ROW_NUMBER() OVER (
			PARTITION BY genre ORDER BY averageRating DESC
				,numVotes DESC
				,film_id ASC
			) AS row_number
		,*
	FROM (
		-- все фильмы, их жанры и рейтинги
		SELECT cast(SUBSTRING(req.tconst, 3, 20) AS BIGINT) AS film_id
			,genre
			,primaryTitle
			,averageRating
			,cast(numVotes AS BIGINT) AS numVotes
		FROM (
			SELECT tconst
				,primaryTitle
				,explode(split(genres, '[,]', - 1)) AS genre
			FROM title_basics_csv
			) AS req
		INNER JOIN title_ratings_csv AS tab
			ON tab.tconst = req.tconst
		)
	)
WHERE row_number = 1;

-- SQL 1.2

/*Вот тут небольшая хитрость, мы воспользовались таблицей из второго номера. В этой таблице жанр каждого фильма, рейтинг и количество голосов.
1. Считаем средневзвешенную оценку по каждому жанру и количество фильмов в жанре.
2.  Соединяем результаты каждого жанра с лучшим фильмом из этого жанра (таблица, которую мы создали до этого) */

CREATE TABLE best_in_genre_frame USING PARQUET AS

SELECT req.genre
	,n_films
	,avgRating
	,primaryTitle AS best_title
	,averageRating AS best_rating
FROM (
	-- Все жанры и их средние оценки
	SELECT genre
		,count(genre) AS n_films
		,round(sum(averageRating * numVotes) / sum(numVotes), 2) AS avgRating
	FROM good_genre_films
	GROUP BY 1
	) AS req
INNER JOIN best_in_genre AS tab
	ON req.genre = tab.genre;

-- SQL 2

/*Опять select * */

SELECT *
FROM best_in_genre_frame
WHERE genre = 'Drama';

/*5.Любимчики режиссера.*/

-- SQL 1.1

/*Для начала создадим простую таблицу, где будут идентификатор фильма, наименование, средний рейтинг и количество голосов.
Пригодиться чтобы писать чуть проще подзапросы*/

CREATE TABLE films_with_rating USING PARQUET AS

-- все фильмы, их рейтинг и количество голосов
SELECT req.tconst
	,primaryTitle
	,averageRating
	,cast(numVotes AS BIGINT) AS numVotes
FROM title_basics_csv AS req
INNER JOIN title_ratings_csv AS tab
	ON tab.tconst = req.tconst;

-- SQL 1.2

/*Будем решать задачу постепенно, соберем статистику по каждому режиссеру без учета его любимчиков.
1. Возьмем для начала идентификатор каждого режиссера и каждого его фильма.
2. К фильму добавляем необходимые данные для подсчета статистик
3. Группируемся по режиссеру и считаем для него количество фильмов, средневзвешенный рейтинг по фильмам, максимальное количество голосов*/

CREATE TABLE director_rating USING PARQUET AS

SELECT director
	,count(req.tconst) AS directors_films
	,round(sum(averageRating * numVotes) / sum(numVotes), 2) AS directors_avgRating
	,max(numVotes) AS directors_maxVotes
FROM (
	SELECT explode(split(directors, '[,]', - 1)) AS director
		,tconst
	FROM title_crew_csv
	) AS req
INNER JOIN films_with_rating AS tab
	ON req.tconst = tab.tconst
GROUP BY 1;

-- SQL 1.3

/*Тоже самое делаем для актеров. Считаем все показатели по фильмам вне зависимости от режиссера.
Тут чуть легче, потому что нет необходимости использовать explode*/

CREATE TABLE actor_rating USING PARQUET AS

SELECT nconst
	,-- актер
	count(req.tconst) AS actors_films
	,round(sum(averageRating * numVotes) / sum(numVotes), 2) AS actors_avgRating
	,max(numVotes) AS actors_maxVotes
FROM title_principals_csv AS req
INNER JOIN films_with_rating AS tab
	ON req.tconst = tab.tconst
WHERE category IN (
		'actor'
		,'actress'
		,'self'
		)
GROUP BY 1;

-- SQL 1.4

/* Найдем для каждого режиссера максимальное количество совместных фильмов с любимчиком (любимчиками)
1. Для каждого режиссера находим все его фильмы
2. Раздуваем таблицу путем добавления в отдельную строку каждого актера. Получаем таблицу режиссер-фильм-актер
3. Группируем все по режиссеру и актеру, считаем количество общих фильмов
4. Для каждого режиссера  оставляем данные вида режиссер-максимальное количество совместных фильмов с любимчиком */

CREATE TABLE director_max_with_fav USING PARQUET AS

SELECT director
	,max(num_together_films) AS max_with_fav
FROM (
	SELECT director
		,nconst
		,-- актер
		count(req.tconst) AS num_together_films -- фильм
	FROM title_principals_csv AS req
	LEFT JOIN (
		SELECT explode(split(directors, '[,]', - 1)) AS director
			,tconst
		FROM title_crew_csv
		) AS tab
		ON req.tconst = tab.tconst
	WHERE category IN (
			'actor'
			,'actress'
			,'self'
			)
	GROUP BY 1
		,2
	)
GROUP BY 1;

-- SQL 1.5

/*Найдем для каждого режиссера его любимчика
1. Первые два шага аналогичны предыдущей таблице
2. Теперь мы делаем inner join после которого остаются записи с режиссером и актером, где количество общих фильмов = максимальному количеству совместных фильмов режиссера с любимчиком
3. Приводим данные к виду режиссер-любимчик-количество совместных фильмов*/

CREATE TABLE director_actor USING PARQUET AS

SELECT req.director
	,nconst
	,num_together_films
FROM (
	SELECT director
		,nconst
		,-- актер
		count(req.tconst) AS num_together_films -- фильм
	FROM title_principals_csv AS req
	LEFT JOIN (
		SELECT explode(split(directors, '[,]', - 1)) AS director
			,tconst
		FROM title_crew_csv
		) AS tab
		ON req.tconst = tab.tconst
	WHERE category IN (
			'actor'
			,'actress'
			,'self'
			)
	GROUP BY 1
		,2
	) AS req
INNER JOIN director_max_with_fav AS tab
	ON req.director = tab.director
		AND req.num_together_films = tab.max_with_fav

-- SQL 1.6

/*Создаем таблицу, где находятся только все режиссеры, все их фильмы и все актеры фильма.
Все в отдельных строках. Данная таблица просто упростит наш следующих шаг*/

CREATE TABLE director_actor_all_films USING PARQUET AS

SELECT nconst
	,-- актер
	req.tconst
	,-- фильм
	director
FROM title_principals_csv AS req
LEFT JOIN (
	SELECT explode(split(directors, '[,]', - 1)) AS director
		,tconst
	FROM title_crew_csv
	) AS tab
	ON req.tconst = tab.tconst
WHERE category IN (
		'actor'
		,'actress'
		,'self'
		);

-- SQL 1.7

/* Теперь из предыдущей таблицы оставляем фильмы, где участвовали режиссеры и их любимчики.
Данная таблица упростит наш следующих шаг*/

CREATE TABLE director_fav_actor_all_films USING PARQUET AS

SELECT req.nconst
	,-- актер
	req.tconst
	,-- фильм
	req.director
FROM director_actor_all_films AS req
INNER JOIN director_actor AS tab
	ON req.director = tab.director
		AND req.nconst = tab.nconst;

-- SQL 1.8

/*Теперь по всем этим фильмам считаем статистики как мы это делали раньше. В данной таблице будут средние рейтинги режиссера и его любимчика (для совместных фильмов)*/

CREATE TABLE director_and_actor_rating USING PARQUET AS

SELECT director
	,req.nconst
	,-- актер
	count(req.tconst) AS togeter_films
	,round(sum(averageRating * numVotes) / sum(numVotes), 2) AS together_avgRating
	,max(numVotes) AS together_maxVotes
FROM director_fav_actor_all_films AS req
INNER JOIN films_with_rating AS tab
	ON req.tconst = tab.tconst
GROUP BY 1
	,2;

-- SQL 1.9

/*На данном этапе создали 3 таблицы со статистиками, это, пожалуй, все что нам необходимо.
Имеем таблицы:
1. Рейтинг отдельно для режиссера
2. Рейтинг отдельно для любимчика
3. Совместный рейтинг режиссера и любимчика
Теперь остается все поклеить в одну таблицу, что в данном случае и происходит.
Используем пару раз вспомогательную таблицу name_basics_csv чтобы перевести идентификатор режиссера и любимчика в их имена*/

CREATE TABLE director_and_actor_forever USING PARQUET AS

SELECT dir.primaryName AS director_name
	,t1.*
	,t2.nconst AS actor
	,act.primaryName AS actor_name
	,actors_films
	,actors_avgRating
	,actors_maxVotes
	,togeter_films
	,together_avgRating
	,together_maxVotes
FROM director_rating AS t1
INNER JOIN name_basics_csv AS dir
	ON dir.nconst = t1.director
INNER JOIN director_and_actor_rating AS t2
	ON t1.director = t2.director
INNER JOIN name_basics_csv AS act
	ON act.nconst = t2.nconst
INNER JOIN actor_rating AS t3
	ON t2.nconst = t3.nconst;

-- SQL 2

/* На этом все, опять обычный запрос вида select *. Однако нам надо теперь выбрать необходимые колонки для отображения. 
Здесь не выводится:
director - идентификатор режиссера
actor - идентификатор любимчика */

SELECT director_name
	,directors_films
	,directors_avgRating
	,directors_maxVotes
	,actor_name
	,actors_films
	,actors_avgRating
	,actors_maxVotes
	,togeter_films
	,together_avgRating
	,together_maxVotes
FROM director_and_actor_forever
WHERE director = 'nm0000233';


/* PS Надо бы установить primary index для каждой таблицы, где используется where, однако все запросы и так очень быстро работают в колабе*/