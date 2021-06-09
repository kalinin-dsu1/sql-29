--=============== МОДУЛЬ 2. РАБОТА С БАЗАМИ ДАННЫХ =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите уникальные названия регионов из таблицы адресов

SELECT DISTINCT district 
FROM address



--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания, чтобы запрос выводил только те регионы,
--названия которых начинаются на "K" и заканчиваются на "a", и названия не содержат пробелов

SELECT DISTINCT district FROM address 
WHERE district LIKE 'K%a' AND NOT district LIKE '% %'



--ЗАДАНИЕ №3
--Получите из таблицы платежей за прокат фильмов информацию по платежам, которые выполнялись
--в промежуток с 17 марта 2007 года по 19 марта 2007 года включительно,
--и стоимость которых превышает 1.00.
--Платежи нужно отсортировать по дате платежа.

SELECT payment_id, payment_date, amount FROM payment 
WHERE amount > 1 AND payment_date::date BETWEEN '2007-03-17' AND '2007-03-19'
ORDER BY payment_date 


--ЗАДАНИЕ №4
-- Выведите информацию о 10-ти последних платежах за прокат фильмов.

SELECT payment_id, payment_date, amount FROM payment 
ORDER BY payment_date DESC
LIMIT 10


--ЗАДАНИЕ №5
--Выведите следующую информацию по покупателям:
-- 1. Фамилия и имя (в одной колонке через пробел)
-- 2. Электронная почта
-- 3. Длину значения поля email
-- 4. Дату последнего обновления записи о покупателе (без времени)
--Каждой колонке задайте наименование на русском языке.

SELECT CONCAT(last_name, ' ', first_name) AS "Фамилия и имя",
	email AS "Электронная почта",
	char_length(email) AS "Длина Email",
	last_update::date AS "Дата"
FROM customer

--ЗАДАНИЕ №6
--Выведите одним запросом активных покупателей, имена которых Kelly или Willie.
--Все буквы в фамилии и имени из нижнего регистра должны быть переведены в высокий регистр.

SELECT UPPER(last_name), UPPER(first_name) FROM customer
WHERE first_name IN ('Kelly','Willie')




--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите одним запросом информацию о фильмах, у которых рейтинг "R"
--и стоимость аренды указана от 0.00 до 3.00 включительно,
--а также фильмы c рейтингом "PG-13" и стоимостью аренды больше или равной 4.00.

SELECT film_id, title, description, rating, rental_rate FROM film
WHERE (rating = 'R' AND rental_rate BETWEEN 0 AND 3) OR (rating = 'PG-13' AND rental_rate >= 4)

--ЗАДАНИЕ №2
--Получите информацию о трћх фильмах с самым длинным описанием фильма.
SELECT film_id, title, description, rating, rental_rate FROM film
ORDER BY CHAR_LENGTH(description) DESC
LIMIT 3



--ЗАДАНИЕ №3
-- Выведите Email каждого покупателя, разделив значение Email на 2 отдельных колонки:
--в первой колонке должно быть значение, указанное до @,
--во второй колонке должно быть значение, указанное после @.

SELECT 
	customer_id, 
	email AS Email,
	SPLIT_PART(email, '@', 1) AS "Email before @",
	SPLIT_PART(email, '@', 2) AS "Email after @"
FROM customer 



--ЗАДАНИЕ №4
--Доработайте запрос из предыдущего задания, скорректируйте значения в новых колонках:
--первая буква должна быть заглавной, остальные строчными.

SELECT 
	customer_id, 
	email AS Email,
	INITCAP(SPLIT_PART(email, '@', 1)) AS "Email before @",
	INITCAP(SPLIT_PART(email, '@', 2)) AS "Email after @"
FROM customer 
