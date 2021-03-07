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

