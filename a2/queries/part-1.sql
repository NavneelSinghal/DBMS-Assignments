with recursive path(airportid, carrier) as (
select distinct flights.destairportid, flights.carrier
from flights
where flights.originairportid = 10140
union
select distinct flights.destairportid, flights.carrier
from flights, path
where path.airportid = flights.originairportid
and flights.carrier = path.carrier
)
select distinct airports.city as name
from path, airports
where path.airportid = airports.airportid
order by airports.city;

