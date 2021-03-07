select coalesce(max(array_length(path.visited, 1) - 1), 0) as length
from path
where path.originairportid = 10140
and path.iscycle = true;

