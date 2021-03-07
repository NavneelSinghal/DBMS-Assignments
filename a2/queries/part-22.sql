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

