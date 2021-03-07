select airports.city as name
from path, airports
where path.originairportid = 10140
and path.destairportid = airports.airportid
group by airports.city
having count(*) = 1
order by airports.city;

