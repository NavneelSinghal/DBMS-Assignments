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

