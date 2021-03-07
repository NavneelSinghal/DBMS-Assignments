select count(*)
from path, airports as a1, airports as a2
where path.originairportid = a1.airportid
and path.destairportid = a2.airportid
and a1.city = 'Albuquerque'
and a2.city = 'Chicago'
and (select airports.airportid from airports where airports.city = 'Washington') = any(path.visited);

