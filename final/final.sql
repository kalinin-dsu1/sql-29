SET search_path TO bookings;

-- 1. В каких городах больше одного аэропорта?

-- Джойним аэоропорты и города, группируем по городу, фильтруем результат с помощью агрегирующей функции
select count(*), city
from airports
group by city
having count(*)>1



-- 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
-- Обязательно использовать: подзапрос

-- Создаем СТЕ который будет находить самолет с максимальной дальностью перелета: сортируем по дальности по убыванию, выбираем первый
--
-- Создаем подзапрос:
-- Результаты запросов всех аэропортов вылета (джойн маршрутов и СТЕ) и аэропортов прилета (джойн маршрутов и СТЕ) 
-- обьединяем оператором UNION, который заодно удалит все неуникальные значения
--
-- Джойним аэропорты с результатом подзапроса для получения названий, сортируем по имени

with aircraft_code as (
	select aircraft_code
	from aircrafts
	order by range desc
	limit 1
)
select airport_name
from airports
join (
	select departure_airport as airport_code
	from routes
	join aircraft_code using(aircraft_code)
	union
	select arrival_airport
	from routes
	join aircraft_code using(aircraft_code)
) sq using(airport_code)
order by airport_name



-- 3. Вывести 10 рейсов с максимальным временем задержки вылета
-- Обязательно использовать: Оператор LIMIT

-- Выбираем рейсы, у которых указано фактическое время вылета
-- сортируем по разности между фактическим и запланированным временем вылет
-- выбираем первые 10
select flight_no
from flights
where actual_departure is not null
order by actual_departure - scheduled_departure desc
limit 10



-- 4. Были ли брони, по которым не были получены посадочные талоны?
-- Обязательно использовать: Верный тип JOIN


-- Джойним бронирования, билеты и посадочные, используем лефт джойн, чтобы получить все бронирования
-- фильтруем по бронированиям, для которого не нашлось посадочного
-- Добавляем лимит, чтобы не проверялись все записи
-- Оборачиваем в подзапрос для выведения строкового ответа

select 
	case 
		when count(*)>0 then 'Да'
		else 'Нет'
	end
from (
	select 1
	from bookings b
	left join tickets t using(book_ref)
	left join boarding_passes bp
	on t.ticket_no = bp.ticket_no
	where bp.ticket_no=bp.ticket_no
	limit 1
) sq



-- 5. Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
-- Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.
-- Обязательно использовать: Оконная функция, Подзапросы или cte

-- 1) Создаем СТЕ в котором джойним места и самолеты для получения вместимости каждого самолета
-- 2) В подзапросе джойним перелеты, и посадочные билеты 
--   для подсчета фактически перевезенных каждый рейсом людей
-- 3) результаты подзапроса джойним с СТЕ, чтобы подсчитать свободные месте и их процентное соотношение
-- 4) оконной функций считаем накопительный итог перевезенных пассажиров
--    для группировки используем планируемое время вылета, так как не везде указано фактическое
with cte as (
	select aircraft_code, count(*)
	from aircrafts 
	join seats using(aircraft_code)
	group by aircraft_code
)
select 
	flight_no,
	departure_airport_name,
	scheduled_departure::date,
	boarded,
	round(100 * boarded / count) as boarded_percent,
	sum(boarded) over(
		partition by departure_airport_name, scheduled_departure::date
		order by departure_airport_name, scheduled_departure::date
	) as boarded_total
from (
	select 
		f.flight_no,
		f.departure_airport_name,
		f.aircraft_code,
		f.scheduled_departure,
		count(*) as boarded
	from flights_v as f
	join boarding_passes as bp
	on bp.flight_id = f.flight_id
	group by f.flight_no, f.departure_airport_name, f.aircraft_code, f.scheduled_departure 
) sq
join cte 
on sq.aircraft_code = cte.aircraft_code



-- 6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.
-- Обязательно использовать: Подзапрос, Оператор ROUND

-- В подзапросе джойним перелеты с самолетами, группируем по модели, считаем количество перелетов модели и общее число перелетов
-- Округляем данные до 3 знака после запятой, чтобы получить сумму 100%
select model, round(count * 100.00 / total, 3)
from (
	select model, count(*), (select count(*) from flights) as total
	from flights
	join aircrafts using(aircraft_code)
	group by model
) t



-- 7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
-- Обязательно использовать: CTE

-- 1) Создаем СТЕ, в котором группируем связи билетов с рейсами по id и классу обслуживания и используем аггрегирующую функцию для нахождения минимальной цены
-- 2) Джойним СТЕ само на себя по id перелета, выбрав в левой части все эконом перелеты а в правой все бизнес перелеты
-- 3) фильтруем по условию(цена за эконом выше цены за бизнес)
-- 4) Оборачиваем в подзапрос для выведения строкового ответа
with cte as (
	select min(amount), flight_id, fare_conditions
	from ticket_flights
	where fare_conditions in ('Business', 'Economy')
	group by flight_id, fare_conditions 
)
select 
	case 
		when count(*)>0 then 'Да'
		else 'Нет'
	end
from (
	select cte1.min, cte2.min, cte1.flight_id
	from cte as cte1
	join cte as cte2
	on cte1.flight_id = cte2.flight_id
	and cte1.fare_conditions = 'Economy'
	and cte2.fare_conditions = 'Business'
	and cte1.min > cte2.min
) sq



-- 8. Между какими городами нет прямых рейсов?
-- Обязательно использовать: Декартово произведение в предложении FROM, Самостоятельно созданные представления, Оператор EXCEPT

-- 1) Создаем представление со всеми уникальными городами из таблицы аэропорты
create materialized view if not exists city (city)
as select distinct(city) from airports

-- 2) Создаем представление со декартовым произведением городов
create materialized view possible_routes (departure_city, arrival_city)
as select c1.city, c2.city from city c1 cross join city c2

-- 3) Создаем СТЕ, в котором выбираем все записи из второго представления с разными городами вылета/прилета,
--	  для которых не находится соответствующей записи в routes

-- 4) Фильтруем все записи, у которых совпадают города вылета/прилета

with cte as (
	select * from possible_routes 
	except
	select departure_city, arrival_city from routes
)
select cte.departure_city, cte.arrival_city
from cte
where cte.departure_city != cte.arrival_city

	
	
-- 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы
-- Обязательно использовать: Оператор RADIANS или использование sind/cosd, CASE

-- В подзапросе джойним рейсы, аэропорт(для координат) и самолеты, считаем по формуле расстояние между аэропортами
-- Кейсом считаем превышение допустимой дальности
select
	flight_no,
	aircraft_range,
	round(route_range),
	case 
		when route_range > aircraft_range then 'yes'
		else 'no'
	end as "distance exceeded"
from (
	select 
		r.flight_no,
		a.range as aircraft_range,
		6371 * acos (
			sind(da.latitude)*sind(aa.latitude) + cosd(da.latitude)*cosd(aa.latitude)*cosd(da.longitude - aa.longitude)
		) as route_range
	from routes r
	join airports da on r.departure_airport = da.airport_code 
	join airports aa on r.arrival_airport = aa.airport_code 
	join aircrafts a using(aircraft_code)
) t
order by t.aircraft_range - t.route_range


