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

