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

