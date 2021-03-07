select day from (
with getalldays as (
select dayofmonth from (values (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15), (16), (17), (18), (19), (20), (21), (22), (23), (24), (25), (26), (27), (28), (29), (30), (31)) as days(dayofmonth)
)
select getalldays.dayofmonth as day, coalesce(sum, 0) as delay
from getalldays left join (
select flights.dayofmonth, sum(flights.arrivaldelay + flights.departuredelay)
from flights, airports
where flights.originairportid = airports.airportid
and airports.city = 'Albuquerque'
group by flights.dayofmonth
) as tbl
on getalldays.dayofmonth = tbl.dayofmonth
) as tbl
order by delay asc, day asc;

