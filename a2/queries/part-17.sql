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

