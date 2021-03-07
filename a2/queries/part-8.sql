select * from (
select a1.city as name1, a2.city as name2
from airports as a1, airports as a2
where a1.city <> a2.city
except
select a1.city as name1, a2.city as name2
from airports as a1, airports as a2, path
where a1.airportid = path.originairportid
and a2.airportid = path.destairportid
) as tbl
order by name1 asc, name2 asc;

