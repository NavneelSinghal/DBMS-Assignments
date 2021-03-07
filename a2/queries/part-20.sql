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

