select authorid from (
select authordetails.authorid, coalesce(count, 0) as count
from authordetails left join (
select author1 as authorid, count from (
select author1, count(*)
from (
select * from authorcitationgraph
except
select * from authorgraph
order by author1, author2
) as tbl
group by author1
) as tbl
) as tbl
on authordetails.authorid = tbl.authorid
) as tbl
order by count desc, authorid asc
LIMIT 10;

