with recursive path(originairportid, destairportid, visited, iscycle, delay) as (
select distinct flights.originairportid, flights.destairportid, array[flights.originairportid, flights.destairportid], false, flights.arrivaldelay + flights.departuredelay
from flights
union
select distinct path.originairportid, flights.destairportid, path.visited || flights.destairportid, (flights.destairportid = path.visited[1] is true), flights.arrivaldelay + flights.departuredelay
from flights, path
where not path.iscycle
and (flights.destairportid <> all(path.visited[2:array_length(path.visited, 1)]))
and path.destairportid = flights.originairportid
and flights.arrivaldelay + flights.departuredelay >= path.delay
)
select distinct a1.city as name1, a2.city as name2
from path, airports as a1, airports as a2
where a1.airportid = path.originairportid
and a2.airportid = path.destairportid
order by a1.city, a2.city;

