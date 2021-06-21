--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания,
--город и страну проживания.

select 
	concat(c.last_name, ' ', c.first_name) as "Фамилия и имя",
	a.address as "Адрес",
	c2.city as "Город",
	c3.country as "Страна"
from customer c
join address a using(address_id)
join city c2 using(city_id)
join country c3 using(country_id)



--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select 
	store_id as "ID магазина",
	count(*) as "Количество покупателей"
from customer
group by store_id



--Доработайте запрос и выведите только те магазины,
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам
--с использованием функции агрегации.

select 
	store_id as "ID магазина",
	count(*) as "Количество покупателей"
from customer
group by store_id
having count(*) > 300


-- Доработайте запрос, добавив в него информацию о городе магазина,
--а также фамилию и имя продавца, который работает в этом магазине.

select 
	s.store_id as "ID магазина",
	c.count as "Количество покупателей",
	c2.city as "Город магазина",
	concat(s2.last_name, ' ', s2.first_name) as "Фамилия и имя продавца"
from store s
join (
	select 
		store_id,
		count(*)
	from customer
	group by store_id
	having count(*) > 300
) c using(store_id)
join address a using(address_id)
join city c2 using(city_id)
join staff s2 on s.manager_staff_id = s2.staff_id


--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей,
--которые взяли в аренду за всё время наибольшее количество фильмов

-- ПРОВЕРЯЮЩЕМУ НЕТОЛОГИИ!:
-- У вас в условиях задачи, либо в результате ошибка. 
-- В результате присутствует Sean Carl c 45 взятыми в аренду фильмами.
-- Но на самом деле, у него 45 записей в табличке rental,
-- в том числе две записи с inventory_id 1177 и 1183, каждая из которых ссылается на film_id 262
-- Так что либо надо переформулировать условия задачи, либо в результате у этого покупателя должно быть на 1 фильм меньше

-- Сделал в соответствии с результатом, без обработки кейса, что один человек может повторно взять 1 и тот же фильм

select 
	count(*) as "Количество фильмов",
	concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя"
from rental r
join customer c using(customer_id)
group by customer_id
order by count(*) desc
limit 5

--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
-- 1. количество фильмов, которые он взял в аренду
-- 2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
-- 3. минимальное значение платежа за аренду фильма
-- 4. максимальное значение платежа за аренду фильма

-- ПРОВЕРЯЮЩЕМУ НЕТОЛОГИИ!:
-- Аналогично с 3 заданием, не обрабатываю кейс, при котором человек повторно берет 1 и тот же фильм.
-- И лучше указать в задании необходимую сортировку, так будет легче проверять результат

select 
	concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя",
	r.count as "Количество фильмов",
	p.sum as "Общая стоимость платежей",
	p.min as "Минимальная стоимость платежа",
	p.max as "Максимальная стоимость платежа"
from customer c
join (
	select 
		count(*),
		customer_id
	from rental
	group by customer_id
) r using(customer_id)
join (
	select
		sum(amount),
		min(amount),
		max(amount),
		customer_id
	from payment
	group by customer_id
) p using(customer_id)


--ЗАДАНИЕ №5
--Используя данные из таблицы городов составьте одним запросом всевозможные пары городов таким образом,
--чтобы в результате не было пар с одинаковыми названиями городов.
--Для решения необходимо использовать декартово произведение.

select 
	c.city as "Город 1",
	c2.city as "Город 2"
from city c
cross join city c2
where c.city != c2.city

--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date)
--и дате возврата фильма (поле return_date),
--вычислите для каждого покупателя среднее количество дней, за которые покупатель возвращает фильмы.

select 
	customer_id as "ID покупателя",
	round(avg(return_date::date - rental_date::date), 2) as "Среднее количество дней на возврат"
from rental
group by customer_id
order by customer_id 


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.

select 
	f.title as "Название фильма",
	f.rating as "Рейтинг",
	c.name as "Жанр",
	f.release_year as "Год выпуска",
	l.name as "Язык",
	f3.count as "Количество аренд",
	f3.sum as "Общая стоимость аренды"
from film f 
join "language" l using(language_id)
join film_category fc using(film_id)
join category c using(category_id) 
left join (
	select 
		count(*),
		sum(p.amount),
		film_id
	from rental r
	join inventory i using(inventory_id)
	join film f2 using(film_id)
	join payment p using(rental_id)
	group by film_id
) f3 using(film_id)
order by f.title

--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью запроса фильмы, которые ни разу не брали в аренду.

-- ПРОВЕРЯЮЩЕМУ НЕТОЛОГИИ!:
-- Укажите уже в задании в задании необходимую сортировку, так будет легче проверять результат

select 
	f.title as "Название фильма",
	f.rating as "Рейтинг",
	c.name as "Жанр",
	f.release_year as "Год выпуска",
	l.name as "Язык",
	f3.count as "Количество аренд",
	f3.sum as "Общая стоимость аренды"
from film f 
join "language" l using(language_id)
join film_category fc using(film_id)
join category c using(category_id) 
left join (
	select 
		count(*),
		sum(p.amount),
		film_id
	from rental r
	join inventory i using(inventory_id)
	join film f2 using(film_id)
	join payment p using(rental_id)
	group by film_id
) f3 using(film_id)
where f3.sum is null
order by f.title

--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

select 
	staff_id as "ID сотрудника",
	count(*) as "Количество продаж",
	case 
		when count(*)>7300 then 'Да'
	    ELSE 'Нет'
	end as "Премия"
from payment 
group by staff_id



