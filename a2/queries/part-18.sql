select count(*)
from authorpath
where author1 = 3552
and author2 = 321
and (
1436 = any(visited)
or  562 = any(visited)
or  921 = any(visited)
);

