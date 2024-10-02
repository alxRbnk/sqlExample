-- 1) Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT aircraft_code, fare_conditions, COUNT(seat_no)
FROM seats
GROUP BY aircraft_code, fare_conditions

-- 2) Найти 3 самых вместительных самолета (модель + кол-во мест)
SELECT aircrafts_data.model, COUNT(seat_no)
FROM seats
JOIN aircrafts_data ON seats.aircraft_code = aircrafts_data.aircraft_code
GROUP BY seats.aircraft_code, aircrafts_data.model
ORDER BY COUNT(seat_no) DESC
LIMIT 3

-- 3) Найти все рейсы, которые задерживались более 2 часов
SELECT *
FROM flights
WHERE actual_departure > scheduled_departure + INTERVAL '2 hours'

-- 4) Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
SELECT t.ticket_no, t.passenger_name, t.contact_data
FROM tickets as t
JOIN ticket_flights as t_f ON t.ticket_no = t_f.ticket_no
WHERE t_f.fare_conditions = 'Business'
ORDER BY t.ticket_no DESC
LIMIT 10

-- 5) Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
SELECT f.*
FROM flights f
LEFT JOIN ticket_flights tf ON f.flight_id = tf.flight_id AND tf.fare_conditions = 'Business'
LEFT JOIN boarding_passes bp ON tf.ticket_no = bp.ticket_no
WHERE bp.ticket_no IS NULL;

-- 6) Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
SELECT DISTINCT a.airport_name, a.city
FROM airports_data a
JOIN flights f ON a.airport_code = f.departure_airport
WHERE f.actual_departure > f.scheduled_departure;

-- 7) Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
SELECT a.airport_name, COUNT(f.flight_id) AS flight_count
FROM airports_data a
JOIN flights f ON a.airport_code = f.departure_airport
GROUP BY a.airport_name
ORDER BY flight_count DESC;

-- 8) Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
SELECT *
FROM flights
WHERE scheduled_arrival <> actual_arrival AND actual_arrival IS NOT NULL;

-- 9) Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
SELECT s.aircraft_code, a.model, s.seat_no
FROM seats s
JOIN aircrafts_data a ON s.aircraft_code = a.aircraft_code
WHERE a.model->>'ru' = 'Аэробус A321-200' AND s.fare_conditions <> 'Economy'
ORDER BY s.seat_no;

-- 10) Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
SELECT airport_code, airport_name, city
FROM airports_data
WHERE city IN (
    SELECT city
    FROM airports_data
    GROUP BY city
    HAVING COUNT(airport_code) > 1
)
ORDER BY city, airport_code;

-- 11) Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
SELECT t.passenger_id, t.passenger_name, SUM(b.total_amount) AS total_spent
FROM tickets t
JOIN bookings b ON t.book_ref = b.book_ref
GROUP BY t.passenger_id, t.passenger_name
HAVING SUM(b.total_amount) > (SELECT AVG(total_amount) FROM bookings);

-- 12) Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
SELECT
    f.flight_id,
    f.flight_no,
    f.scheduled_departure,
    f.departure_airport,
    f.arrival_airport
FROM flights f
WHERE f.departure_airport = 'SVX'
AND f.arrival_airport IN ('SVO', 'VKO', 'DME')
AND f.scheduled_departure > NOW()
ORDER BY f.scheduled_departure ASC
LIMIT 1;

-- 13) Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
SELECT
    MIN(amount) AS cheapest_ticket,
    MAX(amount) AS expensive_ticket
FROM
    ticket_flights;

-- 14) Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints)
CREATE TABLE Customers (
id SERIAL PRIMARY KEY,
firstName VARCHAR(50) NOT NULL,
lastName VARCHAR(50) NOT NULL,
email VARCHAR(100) NOT NULL UNIQUE,
phone VARCHAR(15)
);

-- 15) Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints
CREATE TABLE Orders (
id SERIAL PRIMARY KEY,
customerId INT NOT NULL,
quantity INT NOT NULL CHECK (quantity > 0),
FOREIGN KEY (customerId) REFERENCES Customers(id)
);

-- 16) Написать 5 insert в эти таблицы
INSERT INTO aircrafts_data (aircraft_code, model, range)
VALUES
    ('A321', '{"en": "Airbus A321-200", "ru": "Аэробус A321-200"}', 5600);

INSERT INTO airports_data (airport_code, airport_name, city, coordinates, timezone)
VALUES
    ('SVX', '{"en": "Koltsovo Airport", "ru": "Кольцово"}', '{"en": "Yekaterinburg", "ru": "Екатеринбург"}', '(60.802700042725,56.743099212646)', 'Asia/Yekaterinburg');

INSERT INTO boarding_passes (ticket_no, flight_id, boarding_no, seat_no)
VALUES
    ('TK123', 'FL001', 'B1', '12A');

INSERT INTO bookings (book_ref, book_date, total_amount)
VALUES
    ('BR001', '2024-10-01', 20000.00);

INSERT INTO flights (flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival)
VALUES
    ('FL001', 'SU100', '2024-10-01 10:00:00', '2024-10-01 12:00:00', 'SVX', 'SVO', 'Scheduled', 'A321', NULL, NULL);

-- 17) Удалить таблицы
DROP TABLE
IF EXISTS aircrafts_data, airports_data, boarding_passes,
          bookings, flights, seats, ticket_flights,
          tickets CASCADE;