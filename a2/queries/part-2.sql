with recursive path(airportid, dayofweek) as (
select distinct flights.destairportid, flights.dayofweek
from flights
where flights.originairportid = 10140
union
select distinct flights.destairportid, flights.dayofweek
from flights, path
where path.airportid = flights.originairportid
and flights.dayofweek = path.dayofweek
)
select distinct airports.city as name
from path, airports
where path.airportid = airports.airportid
order by airports.city;

