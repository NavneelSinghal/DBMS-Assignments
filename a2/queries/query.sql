--PREAMBLE--
create view path 
as
with recursive path(originairportid, destairportid, visited, iscycle) as (
    select distinct flights.originairportid, flights.destairportid, array[flights.originairportid, flights.destairportid], false
    from flights
    union
    select distinct path.originairportid, flights.destairportid, path.visited || flights.destairportid, (flights.destairportid = path.visited[1] is true)
    from flights, path
    where not path.iscycle
    and (flights.destairportid <> all(path.visited[2:array_length(path.visited, 1)]))
    and path.destairportid = flights.originairportid
)
select * from path;

create view authorgraph
as
select distinct a1.authorid as author1, a2.authorid as author2
from authorpaperlist as a1, authorpaperlist as a2
where a1.paperid = a2.paperid
and a1.authorid <> a2.authorid;

create view authorpath
as
with recursive authorpath(author1, author2, visited) as (
    select distinct author1, author2, array[author1, author2]
    from authorgraph
    union
    select distinct authorpath.author1, authorgraph.author2, authorpath.visited || authorgraph.author2
    from authorgraph, authorpath
    where (authorgraph.author1 = authorpath.author2)
    and (authorgraph.author2 <> all(authorpath.visited))
)
select * from authorpath;

create view citationpath
as
with recursive citationpath(paper1, paper2, visited, iscycle) as (
    select distinct paperid1 as paper1, paperid2 as paper2, array[paperid1, paperid2], false
    from citationlist
    union
    select distinct citationpath.paper1, citationlist.paperid2, citationpath.visited || citationlist.paperid2, (citationpath.visited[1] = citationlist.paperid2)
    from citationlist, citationpath
    where not citationpath.iscycle
    and (citationlist.paperid1 = citationpath.paper2)
    and (citationlist.paperid2 <> all(citationpath.visited[2:array_length(citationpath.visited, 1)]))
)
select * from citationpath;

create view authordirectcited
as
select distinct a1.authorid as author1, a2.authorid as author2
from citationlist, authorpaperlist as a1, authorpaperlist as a2
where a1.paperid = citationlist.paperid1
and a2.paperid = citationlist.paperid2
and a1.authorid <> a2.authorid;

create view citationgraph
as
select distinct paper1, paper2
from citationpath
where not citationpath.iscycle;

create view authorcitationgraph
as
select distinct a1.authorid as author1, a2.authorid as author2
from citationgraph, authorpaperlist as a1, authorpaperlist as a2
where a1.paperid = citationgraph.paper1
and a2.paperid = citationgraph.paper2
and a1.authorid <> a2.authorid;

create view countcitations
as
select authordetails.authorid, coalesce(count, 0) as count
from authordetails left join (
    select authorid, count(*)
    from citationgraph, authorpaperlist
    where authorpaperlist.paperid = citationgraph.paper2
    group by authorid
) as tbl
on authordetails.authorid = tbl.authorid
group by authordetails.authorid, tbl.count;

--1--
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

--2--
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

--3--
select airports.city as name
from path, airports
where path.originairportid = 10140
and path.destairportid = airports.airportid
group by airports.city
having count(*) = 1
order by airports.city;

--4--
select coalesce(max(array_length(path.visited, 1) - 1), 0) as length
from path
where path.originairportid = 10140
and path.iscycle = true;

--5--
select coalesce(max(array_length(path.visited, 1) - 1), 0) as length
from path
where path.iscycle = true;

--6--
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

--7--
select count(*)
from path, airports as a1, airports as a2
where path.originairportid = a1.airportid
and path.destairportid = a2.airportid
and a1.city = 'Albuquerque'
and a2.city = 'Chicago'
and (select airports.airportid from airports where airports.city = 'Washington') = any(path.visited);

--8--
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

--9--
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

--10--
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

--11--
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

--12--
select * from (
    select authordetails.authorid, coalesce(tbl.length, -1) as length
    from authordetails left join (
        select authorpath.author2, min(array_length(authorpath.visited, 1) - 1) as length
        from authorpath
        where authorpath.author1 <> authorpath.author2
        and authorpath.author1 = 1235
        group by authorpath.author1, authorpath.author2
    ) as tbl
    on authordetails.authorid = tbl.author2
) as tbl where authorid <> 1235
order by length desc, authorid asc;

--13--
select count from (
    select distinct authorpath.author1, authorpath.author2, count 
    from (
        select coalesce(count(*), 0) as count from (
            with recursive authorpath13(author2, visited) as (
                select distinct author2, array[author1, author2]
                from authorgraph, authordetails
                where author1 = 1558
                and author2 = authorid
                and age > 35
                union
                select distinct authorgraph.author2, authorpath13.visited || authorgraph.author2
                from authorgraph, authorpath13, authordetails as a1, authordetails as a2
                where authorgraph.author2 <> all(authorpath13.visited)
                and (authorgraph.author1 = authorpath13.author2)
                and a1.authorid = authorgraph.author1
                and a2.authorid = authorgraph.author2
                and a1.age > 35
                and a2.age > 35
                and a1.gender <> a2.gender
            )
            select distinct visited
            from authorpath13, authorgraph
            where authorpath13.author2 = authorgraph.author1
            and authorgraph.author2 = 2826
            and 2826 <> all(visited)
            union
            select array[1558] as visited
            from authorgraph
            where author1 = 1558
            and author2 = 2826
        ) as tbl
    ) as tbl, authorpath
    where authorpath.author1 = 1558
    and authorpath.author2 = 2826
    union
    select 1558 as author1, 2826 as author2, -1 as count
    order by count desc
    LIMIT 1
) as tbl;

--14--
select count from (
    select distinct author1, author2, count from (
        select count(*) from (
            select authorpath.visited, coalesce(count(1), 0) as count
            from authorpath, authorpaperlist, citationpath
            where authorpath.author1 = 704
            and authorpath.author2 = 102
            and array_length(authorpath.visited, 1) > 2
            and authorpaperlist.authorid = any(authorpath.visited[2:array_length(authorpath.visited, 1) - 1])
            and citationpath.paper1 = authorpaperlist.paperid
            and citationpath.paper2 = 126
            group by authorpath.visited
        ) as tbl
    ) as tbl, authorpath
    where authorpath.author1 = 704
    and authorpath.author2 = 102
    union
    select 704 as author1, 102 as author2, -1 as count
    order by count desc
    limit 1
) as tbl;

--15--
select count from (
    select distinct author1, author2, count from (
        select count(*) from (
            with recursive
            authorpath13(author2, visited) as (
                select distinct author2, array[author1, author2]
                from authorgraph
                where author1 = 1745
                union
                select distinct authorgraph.author2, authorpath13.visited || authorgraph.author2
                from authorgraph, authorpath13, countcitations as c1, countcitations as c2
                where authorgraph.author2 <> all(authorpath13.visited)
                and (authorgraph.author1 = authorpath13.author2)
                and c1.authorid = authorgraph.author1
                and c2.authorid = authorgraph.author2
                and c1.count < c2.count
            ),
            authorpath14(author2, visited) as (
                select distinct author2, array[author1, author2]
                from authorgraph
                where author1 = 1745
                union
                select distinct authorgraph.author2, authorpath14.visited || authorgraph.author2
                from authorgraph, authorpath14, countcitations as c1, countcitations as c2
                where authorgraph.author2 <> all(authorpath14.visited)
                and (authorgraph.author1 = authorpath14.author2)
                and c1.authorid = authorgraph.author1
                and c2.authorid = authorgraph.author2
                and c1.count > c2.count
            )
            select distinct visited || 456 as visited
            from (
                select * from authorpath13 union select * from authorpath14
            ) as finalpaths, authorgraph
            where finalpaths.author2 = authorgraph.author1
            and authorgraph.author2 = 456
            and 456 <> all(finalpaths.visited)
            union
            select array[1745, 456] as visited
            from authorgraph
            where author1 = 1745
            and author2 = 456
        ) as tbl
    ) as tbl, authorpath
    where authorpath.author1 = 1745
    and authorpath.author2 = 456
    union
    select 1745 as author1, 456 as author2, -1 as count
    order by count desc
    limit 1
) as tbl;

--16--
select authorid from (
    select authordetails.authorid, coalesce(count, 0) as count
    from authordetails left join (
        select author1 as authorid, count from (
            select author1, count(*)
            from (
                select * from authorcitationgraph
                except
                select * from authorgraph
                order by author1, author2
            ) as tbl
            group by author1
        ) as tbl
    ) as tbl
    on authordetails.authorid = tbl.authorid
) as tbl
order by count desc, authorid asc
LIMIT 10;

--17--
select authorid from (
    select authordetails.authorid, coalesce(threedcitations, 0) as count from 
    authordetails left join (
        select author1 as authorid, threedcitations from (
            with threed as (
                select distinct author1, author2 from authorpath
                where array_length(authorpath.visited, 1) <= 4
                except
                select distinct author1, author2 from authorpath
                where array_length(authorpath.visited, 1) <= 3
            )
            select threed.author1, sum(countcitations.count) as threedcitations
            from threed, countcitations
            where countcitations.authorid = threed.author2
            group by threed.author1
        ) as tbl
    ) as tbl
    on authordetails.authorid = tbl.authorid
    order by count desc, authordetails.authorid asc
    LIMIT 10
) as tbl;

--18--
select count(*)
from authorpath
where author1 = 3552
and author2 = 321
and (
    1436 = any(visited)
    or  562 = any(visited)
    or  921 = any(visited)
);

--19--
select count(*) from (
    with recursive authorpath(author1, author2, visited) as (
        select distinct author1, author2, array[author1, author2]
        from authorgraph
        union
        select distinct authorpath.author1, authorgraph.author2, authorpath.visited || authorgraph.author2
        from authorgraph, authorpath
        where (authorgraph.author1 = authorpath.author2)
        and (authorgraph.author2 <> all(authorpath.visited))
    ),
    abpaths as (
        select visited[2:array_length(visited, 1) - 1] as visited from authorpath
        where author1 = 3552 and author2 = 321
    )
    (
        select visited
        from abpaths
    )
    except
    (
        select distinct visited
        from abpaths, authordetails as a1, authordetails as a2
        where a1.authorid = any(visited)
        and a2.authorid = any(visited)
        and a1.city = a2.city
        and a1.authorid <> a2.authorid
        union
        select distinct visited
        from abpaths, authordirectcited as a1, authordirectcited as a2
        where a1.author1 = any(visited)
        and a1.author2 = any(visited)
        and a2.author2 = a1.author1
        and a2.author1 = a1.author2
        and a1.author1 <> a1.author2
    )
) as tbl
union
select -1 as count
order by count desc
limit 1;

--20--
select count(*) from (
    with recursive authorpath(author1, author2, visited) as (
        select distinct author1, author2, array[author1, author2]
        from authorgraph
        union
        select distinct authorpath.author1, authorgraph.author2, authorpath.visited || authorgraph.author2
        from authorgraph, authorpath
        where (authorgraph.author1 = authorpath.author2)
        and (authorgraph.author2 <> all(authorpath.visited))
    ),
    abpaths as (
        select authorpath.visited[2:array_length(authorpath.visited, 1) - 1] as visited from authorpath
        where authorpath.author1 = 3552 and authorpath.author2 = 321
    )
    (
        select abpaths.visited
        from abpaths
    )
    except
    (
        select distinct abpaths.visited
        from abpaths, authorcitationgraph
        where authorcitationgraph.author1 = any(abpaths.visited)
        and authorcitationgraph.author2 = any(abpaths.visited)
        and authorcitationgraph.author1 <> authorcitationgraph.author2
    )
) as tbl
union
select -1 as count
order by count desc
limit 1;

--21--
select * from (
    with tbl as (
        select distinct component, conference as conferencename from (
            with recursive reachable(author1, author2, conference) as (
                select distinct authorid, authorid, conferencename
                from authorpaperlist, paperdetails
                where authorpaperlist.paperid = paperdetails.paperid
                union
                select distinct reachable.author1, a2.authorid, conferencename
                from reachable, authorpaperlist as a1, authorpaperlist as a2, paperdetails
                where reachable.author2 = a1.authorid
                and a1.paperid = a2.paperid
                and a1.paperid = paperdetails.paperid
                and reachable.conference = paperdetails.conferencename
            )
            select author1, conference, array_agg(author2 order by author2) as component
            from reachable
            group by author1, conference
        ) as tbl
    )
    select conferencename, count(*)
    from tbl
    group by conferencename
) as tbl
order by count desc, conferencename asc;

--22--
select * from (
    with tbl as (
        select distinct component, conference as conferencename from (
            with recursive reachable(author1, author2, conference) as (
                select distinct authorid, authorid, conferencename
                from authorpaperlist, paperdetails
                where authorpaperlist.paperid = paperdetails.paperid
                union
                select distinct reachable.author1, a2.authorid, conferencename
                from reachable, authorpaperlist as a1, authorpaperlist as a2, paperdetails
                where reachable.author2 = a1.authorid
                and a1.paperid = a2.paperid
                and a1.paperid = paperdetails.paperid
                and reachable.conference = paperdetails.conferencename
            )
            select author1, conference, array_agg(author2 order by author2) as component
            from reachable
            group by author1, conference
        ) as tbl
    )
    select conferencename, array_length(component, 1) as count
    from tbl
) as tbl
order by count asc, conferencename asc;

--CLEANUP--
drop view countcitations;
drop view authorcitationgraph;
drop view citationgraph;
drop view authordirectcited;
drop view citationpath;
drop view authorpath;
drop view authorgraph;
drop view path;
