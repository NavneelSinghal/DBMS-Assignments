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

