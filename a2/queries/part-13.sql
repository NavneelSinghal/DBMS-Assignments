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

