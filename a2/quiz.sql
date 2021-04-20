--1--
with recursive authorgraph as (
select distinct a1.authorid as author1, a2.authorid as author2, a1.paperid
from authorpaperlist as a1, authorpaperlist as a2
where a1.paperid = a2.paperid
and a1.authorid <> a2.authorid
),
authorpath(author1, author2, visited, visitedpapers) as (
    select distinct author1, author2, array[author1, author2], array[paperid]
    from authorgraph
    union
    select distinct authorpath.author1, authorgraph.author2, (authorpath.visited || authorgraph.author2), (authorpath.visitedpapers || authorgraph.paperid)
    from authorgraph, authorpath
    where (authorgraph.author1 = authorpath.author2)
    and (authorgraph.author2 <> all(authorpath.visited))
),
citationpath(paper1, paper2, visited, iscycle) as (
    select distinct paperid1 as paper1, paperid2 as paper2, array[paperid1, paperid2], false
    from citationlist
    union
    select distinct citationpath.paper1, citationlist.paperid2, citationpath.visited || citationlist.paperid2, (citationpath.visited[1] = citationlist.paperid2)
    from citationlist, citationpath
    where not citationpath.iscycle
    and (citationlist.paperid1 = citationpath.paper2)
    and (citationlist.paperid2 <> all(citationpath.visited[2:array_length(citationpath.visited, 1)]))
),
citationcount as (
    select paper2, count(*) from (
        select distinct paper1, paper2
        from citationpath
        where not citationpath.iscycle
    ) as tbl
    group by paper2
)
select distinct citationcount.paper2 as paperid
from citationcount, authorpath
where paper2 = any(authorpath.visitedpapers)
and authorpath.author1 = 1
and authorpath.author2 = 5
and citationcount.count > 4;

--2--
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
select max(array_length(visited, 1)) as length
from path
where not iscycle;

--3--
with recursive
authorgraph
as
(
select distinct a1.authorid as author1, a2.authorid as author2
from authorpaperlist as a1, authorpaperlist as a2
where a1.paperid = a2.paperid
and a1.authorid <> a2.authorid
),
citationpath(paper1, paper2, visited, iscycle) as (
    select distinct paperid1 as paper1, paperid2 as paper2, array[paperid1, paperid2], false
    from citationlist
    union
    select distinct citationpath.paper1, citationlist.paperid2, citationpath.visited || citationlist.paperid2, (citationpath.visited[1] = citationlist.paperid2)
    from citationlist, citationpath
    where not citationpath.iscycle
    and (citationlist.paperid1 = citationpath.paper2)
    and (citationlist.paperid2 <> all(citationpath.visited[2:array_length(citationpath.visited, 1)]))
),
authordirectcited as (
select distinct a1.authorid as author1, a2.authorid as author2
from citationlist, authorpaperlist as a1, authorpaperlist as a2
where a1.paperid = citationlist.paperid1
and a2.paperid = citationlist.paperid2
and a1.authorid <> a2.authorid
),
citationgraph as (
select distinct paper1, paper2
from citationpath
where not citationpath.iscycle
),
authorcitationgraph as (
select distinct a1.authorid as author1, a2.authorid as author2
from citationgraph, authorpaperlist as a1, authorpaperlist as a2
where a1.paperid = citationgraph.paper1
and a2.paperid = citationgraph.paper2
and a1.authorid <> a2.authorid
)
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
        where authorpath.author1 = 2 and authorpath.author2 = 6
    )
    (
        select abpaths.visited
        from abpaths
    )
    except
    (
        select distinct abpaths.visited
        from abpaths, (
            select distinct author1
            from authorcitationgraph
            except
            select distinct author1
            from authorcitationgraph
            where author2 = 2
            or author2 = 6
        ) as tbl
        where tbl.author1 = any(abpaths.visited)
    )
) as tbl;

