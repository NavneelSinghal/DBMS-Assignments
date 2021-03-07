with recursive path(originairportid, destairportid, visited, iscycle) as (
select distinct flights.originairportid, flights.destairportid, array[flights.originairportid, flights.destairportid], false
from flights, airports as a1, airports as a2
where flights.originairportid = a1.airportid
and flights.destairportid = a2.airportid
and a1.state <> a2.state
union
select distinct path.originairportid, flights.destairportid, path.visited || flights.destairportid, (flights.destairportid = path.visited[1] is true)
from flights, path, airports as a1, airports as a2
where not path.iscycle
and (flights.destairportid <> all(path.visited[2:array_length(path.visited, 1)]))
and path.destairportid = flights.originairportid
and flights.originairportid = a1.airportid
and flights.destairportid = a2.airportid
and a1.state <> a2.state
)
select count(*)
from path, airports as a1, airports as a2
where path.originairportid = a1.airportid
and path.destairportid = a2.airportid
and a1.city = 'Albuquerque'
and a2.city = 'Chicago';

