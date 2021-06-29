--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах
--со специальным атрибутом "Behind the Scenes".

select film_id, title, special_features
from film
where special_features @> array['Behind the Scenes']

--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

select film_id, title, special_features
from film
where special_features::varchar ilike '%Behind the Scenes%'

select film_id, title, special_features
from film
where 'Behind the Scenes' = any(special_features);

select film_id, title, special_features
from film
where array_position(special_features, 'Behind the Scenes') is not null

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в CTE. CTE необходимо использовать для решения задания.

with cte as (
	select film_id, title, special_features
	from film
	where special_features @> array['Behind the Scenes']
)
select customer_id, count(*) as film_count
from cte
join inventory using(film_id)
join rental using(inventory_id)
group by customer_id
order by customer_id


--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

select customer_id, count(*) as film_count
from (
	select film_id, title, special_features
	from film
	where special_features @> array['Behind the Scenes']
) as sq
join inventory using(film_id)
join rental using(inventory_id)
group by customer_id
order by customer_id

--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view if not exists 
	customer_bts_rentals
	(customer_id, film_count) 
as
	select customer_id, count(*) as film_count
	from (
		select film_id, title, special_features
		from film
		where special_features @> array['Behind the Scenes']
	) as sq
	join inventory using(film_id)
	join rental using(inventory_id)
	group by customer_id
	order by customer_id
with no data

refresh materialized view customer_bts_rentals

select * from customer_bts_rentals

drop materialized view customer_bts_rentals

--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ скорости выполнения запросов
-- из предыдущих заданий и ответьте на вопросы:

--1. Каким оператором или функцией языка SQL, используемых при выполнении домашнего задания,
-- поиск значения в массиве происходит быстрее
Поиск значений в массиве быстрее всего происходит 
при использовании функций работы с массивами
array_position @> <@ &&

--2. какой вариант вычислений работает быстрее:
-- с использованием CTE или с использованием подзапроса
в 10 версии быстрее подзапрос
в 12 версии разницы нет

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.

select 
	sq2.staff_id, 
	film_id, 
	title,
	amount,
	payment_date,
	c.last_name as customer_last_name,
	c.first_name as customer_first_name
from (
	select * from (
		select
			rental_id,
			customer_id,
			staff_id,
			amount,
			payment_date,
			row_number() over(partition by staff_id order by payment_date) 
		from payment		
	) sq1
	where row_number = 1
) sq2
join customer c using(customer_id)
join rental using(rental_id)
join inventory using(inventory_id)
join film using(film_id)

--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- Либо моя локальная база отличается, либо скриншот в дз неправильный, но в решении я уверен на 100%, проверял результаты вручную
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

with
rental_cte as (
	select 
	store_id, count, rental_date
	from (
		select
		*,
		row_number() over(partition by store_id order by count desc)
		from (
			select
				store_id,
				count(*),
				rental_date::date
			from rental
			join staff using(staff_id)
			join store using(store_id)
			group by store_id, rental_date::date
		) rental_sq_1
	) rental_sq_2
	where row_number = 1
),
payment_cte as (
	select 
		store_id, sum, payment_date
	from (
		select *,
		row_number() over(partition by store_id order by sum)
		from (
			select
				store_id,
				sum(amount),
				payment_date::date
			from payment
			join staff using(staff_id)
			join store using(store_id)
			group by store_id, payment_date::date
		) payment_sq_1
	) payment_sq_2
	where row_number = 1
)
select 
	store_id as "ID магазина",
	rental_cte.rental_date as "День, в который арендовали больше всего фильмов",
	rental_cte.count as "Количество фильмов, взятых в аренду в этот день",
	payment_cte.payment_date as "День, в который продали фильмов на наименьшую сумму",
	payment_cte.sum as "Сумма продажи в этот день"
from store
join rental_cte using(store_id)
join payment_cte using(store_id)

