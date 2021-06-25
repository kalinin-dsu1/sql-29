--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Cделайте запрос к таблице payment.
--Пронумеруйте все продажи от 1 до N по дате продажи.
select 
	payment_id, 
	payment_date,
	row_number() over(order by payment_date) 
from payment

--ЗАДАНИЕ №2
--Используя оконную функцию добавьте колонку с порядковым номером
--продажи для каждого покупателя,
--сортировка платежей должна быть по дате платежа.

select 
	payment_id, 
	payment_date,
	customer_id,
	row_number() over(partition by customer_id order by payment_date) 
from payment
join customer using(customer_id)

--ЗАДАНИЕ №3
--Для каждого пользователя посчитайте нарастающим итогом сумму всех его платежей,
--сортировка платежей должна быть по дате платежа.

select 
	customer_id,
	payment_id, 
	payment_date,
	amount,
	sum(amount) over(partition by customer_id order by payment_date) as sum_amount
from payment
join customer using(customer_id)

--ЗАДАНИЕ №4
--Для каждого покупателя выведите данные о его последней оплате аренде.

select 
	customer_id,
	payment_id, 
	payment_date,
	amount 
from (
	select 
		customer_id,
		payment_id, 
		payment_date,
		amount,
		row_number() over(partition by customer_id order by payment_date desc) 
	from payment
	join customer using(customer_id)
) sq1
where row_number = 1


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника магазина
--стоимость продажи из предыдущей строки со значением по умолчанию 0.0
--с сортировкой по дате продажи

select
	staff_id,
	payment_id,
	payment_date,
	amount,
	lag(amount, 1, 0.) over (partition by staff_id order by payment_date) as last_amount
from staff
join payment 
	using(staff_id)


--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за март 2007 года
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (дата без учета времени)
--с сортировкой по дате продажи

select
	staff_id,
	payment_date,
	sum_amount,
	sum(sum_amount) over(partition by staff_id order by payment_date) as sum
from (
	select 
		staff_id,
		payment_date::date,
		sum(amount) as sum_amount
	from staff
	join payment using(staff_id)
	where payment_date::date >= date('2007/03/01') AND payment_date::date < date('2007/04/01')
	group by staff_id, payment_date::date
) sq

--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

with cte (
	customer_name,
	country_id,
	count,
	sum,
	max
) as ( 
	select 
		concat(c.first_name, ' ', c.last_name),
		country_id,
		count(*),
		sum(amount),
		max(rental_date)
	from customer c
	join address using(address_id)
	join city using(city_id)
	join country using(country_id)
	join rental r on r.customer_id = c.customer_id 
	join payment using (rental_id)
	group by c.customer_id, country_id	
)
select 
	country,
	(
		select customer_name 
		from cte
		where cte.country_id = c.country_id
		order by count desc
		limit 1
	) as "Покупатель, арендовавший наибольшее количество фильмов",
	(
		select customer_name 
		from cte
		where cte.country_id = c.country_id
		order by sum desc
		limit 1
	) as "Покупатель, арендовавший фильмов на самую большую сумму",
	(
		select customer_name 
		from cte
		where cte.country_id = c.country_id
		order by max desc
		limit 1
	) as "Покупатель, который последним арендовал фильм"
from country c

