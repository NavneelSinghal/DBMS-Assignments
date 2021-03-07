with tbl as (
select city, count(*) from (
select distinct a1.city as city, a2.city as c2
from airports as a1, airports as a2, flights
where flights.originairportid = a1.airportid
and flights.destairportid = a2.airportid
and a1.state = 'New York'
and a2.state = 'New York'
) as tbl
group by city
),
citytbl as (
select distinct city
from airports
where airports.state = 'New York'
)
select city as name
from tbl
where count = (select count(*) - 1 from citytbl)
order by city;

