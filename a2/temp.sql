--PREAMBLE--

CREATE VIEW path AS WITH RECURSIVE path(originairportid, destairportid, visited, iscycle) AS
    ( SELECT DISTINCT flights.originairportid,
                      flights.destairportid, array[flights.originairportid,
                                                   flights.destairportid], FALSE
     FROM flights
     UNION SELECT DISTINCT path.originairportid,
                           flights.destairportid,
                           path.visited || flights.destairportid, (flights.destairportid = path.visited[1] IS TRUE)
     FROM flights,
          path
     WHERE NOT path.iscycle
         AND (flights.destairportid <> all(path.visited[2:array_length(path.visited, 1)]))
         AND path.destairportid = flights.originairportid )
SELECT *
FROM path;


CREATE VIEW authorgraph AS
SELECT DISTINCT a1.authorid AS author1,
                a2.authorid AS author2
FROM authorpaperlist AS a1,
     authorpaperlist AS a2
WHERE a1.paperid = a2.paperid
    AND a1.authorid <> a2.authorid;


CREATE VIEW authorpath AS WITH RECURSIVE authorpath(author1, author2, visited) AS
    ( SELECT DISTINCT author1,
                      author2, array[author1,
                                     author2]
     FROM authorgraph
     UNION SELECT DISTINCT authorpath.author1,
                           authorgraph.author2,
                           authorpath.visited || authorgraph.author2
     FROM authorgraph,
          authorpath
     WHERE (authorgraph.author1 = authorpath.author2)
         AND (authorgraph.author2 <> all(authorpath.visited)) )
SELECT *
FROM authorpath;


CREATE VIEW citationpath AS WITH RECURSIVE citationpath(paper1, paper2, visited, iscycle) AS
    ( SELECT DISTINCT paperid1 AS paper1,
                      paperid2 AS paper2, array[paperid1,
                                                paperid2], FALSE
     FROM citationlist
     UNION SELECT DISTINCT citationpath.paper1,
                           citationlist.paperid2,
                           citationpath.visited || citationlist.paperid2, (citationpath.visited[1] = citationlist.paperid2)
     FROM citationlist,
          citationpath
     WHERE NOT citationpath.iscycle
         AND (citationlist.paperid1 = citationpath.paper2)
         AND (citationlist.paperid2 <> all(citationpath.visited[2:array_length(citationpath.visited, 1)])) )
SELECT *
FROM citationpath;


CREATE VIEW authordirectcited AS
SELECT DISTINCT a1.authorid AS author1,
                a2.authorid AS author2
FROM citationlist,
     authorpaperlist AS a1,
     authorpaperlist AS a2
WHERE a1.paperid = citationlist.paperid1
    AND a2.paperid = citationlist.paperid2
    AND a1.authorid <> a2.authorid;


CREATE VIEW citationgraph AS
SELECT DISTINCT paper1,
                paper2
FROM citationpath
WHERE NOT citationpath.iscycle;


CREATE VIEW authorcitationgraph AS
SELECT DISTINCT a1.authorid AS author1,
                a2.authorid AS author2
FROM citationgraph,
     authorpaperlist AS a1,
     authorpaperlist AS a2
WHERE a1.paperid = citationgraph.paper1
    AND a2.paperid = citationgraph.paper2
    AND a1.authorid <> a2.authorid;


CREATE VIEW countcitations AS
SELECT authordetails.authorid,
       coalesce(COUNT, 0) AS COUNT
FROM authordetails
LEFT JOIN
    ( SELECT authorid,
             count(*)
     FROM citationgraph,
          authorpaperlist
     WHERE authorpaperlist.paperid = citationgraph.paper2
     GROUP BY authorid) AS tbl ON authordetails.authorid = tbl.authorid
GROUP BY authordetails.authorid,
         tbl.count;

--1--
WITH RECURSIVE path(airportid, carrier) AS
    ( SELECT DISTINCT flights.destairportid,
                      flights.carrier
     FROM flights
     WHERE flights.originairportid = 10140
     UNION SELECT DISTINCT flights.destairportid,
                           flights.carrier
     FROM flights,
          path
     WHERE path.airportid = flights.originairportid
         AND flights.carrier = path.carrier )
SELECT DISTINCT airports.city AS name
FROM path,
     airports
WHERE path.airportid = airports.airportid
ORDER BY airports.city;

--2--
WITH RECURSIVE path(airportid, dayofweek) AS
    ( SELECT DISTINCT flights.destairportid,
                      flights.dayofweek
     FROM flights
     WHERE flights.originairportid = 10140
     UNION SELECT DISTINCT flights.destairportid,
                           flights.dayofweek
     FROM flights,
          path
     WHERE path.airportid = flights.originairportid
         AND flights.dayofweek = path.dayofweek )
SELECT DISTINCT airports.city AS name
FROM path,
     airports
WHERE path.airportid = airports.airportid
ORDER BY airports.city;

--3--

SELECT airports.city AS name
FROM path,
     airports
WHERE path.originairportid = 10140
    AND path.destairportid = airports.airportid
GROUP BY airports.city
HAVING count(*) = 1
ORDER BY airports.city;

--4--

SELECT coalesce(max(array_length(path.visited, 1) - 1), 0) AS LENGTH
FROM path
WHERE path.originairportid = 10140
    AND path.iscycle = TRUE;

--5--

SELECT coalesce(max(array_length(path.visited, 1) - 1), 0) AS LENGTH
FROM path
WHERE path.iscycle = TRUE;

--6--
WITH RECURSIVE path(originairportid, destairportid, visited, iscycle) AS
    ( SELECT DISTINCT flights.originairportid,
                      flights.destairportid, array[flights.originairportid,
                                                   flights.destairportid], FALSE
     FROM flights,
          airports AS a1,
          airports AS a2
     WHERE flights.originairportid = a1.airportid
         AND flights.destairportid = a2.airportid
         AND a1.state <> a2.state
     UNION SELECT DISTINCT path.originairportid,
                           flights.destairportid,
                           path.visited || flights.destairportid, (flights.destairportid = path.visited[1] IS TRUE)
     FROM flights,
          path,
          airports AS a1,
          airports AS a2
     WHERE NOT path.iscycle
         AND (flights.destairportid <> all(path.visited[2:array_length(path.visited, 1)]))
         AND path.destairportid = flights.originairportid
         AND flights.originairportid = a1.airportid
         AND flights.destairportid = a2.airportid
         AND a1.state <> a2.state )
SELECT count(*)
FROM path,
     airports AS a1,
     airports AS a2
WHERE path.originairportid = a1.airportid
    AND path.destairportid = a2.airportid
    AND a1.city = 'Albuquerque'
    AND a2.city = 'Chicago';

--7--

SELECT count(*)
FROM path,
     airports AS a1,
     airports AS a2
WHERE path.originairportid = a1.airportid
    AND path.destairportid = a2.airportid
    AND a1.city = 'Albuquerque'
    AND a2.city = 'Chicago'
    AND
        (SELECT airports.airportid
         FROM airports
         WHERE airports.city = 'Washington') = any(path.visited);

--8--

SELECT *
FROM
    ( SELECT a1.city AS name1,
             a2.city AS name2
     FROM airports AS a1,
          airports AS a2
     WHERE a1.city <> a2.city
     EXCEPT SELECT a1.city AS name1,
                   a2.city AS name2
     FROM airports AS a1,
          airports AS a2,
          path
     WHERE a1.airportid = path.originairportid
         AND a2.airportid = path.destairportid ) AS tbl
ORDER BY name1 ASC,
         name2 ASC;

--9--

SELECT DAY
FROM
    ( WITH getalldays AS
         ( SELECT dayofmonth
          FROM (
                VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15), (16), (17), (18), (19), (20), (21), (22), (23), (24), (25), (26), (27), (28), (29), (30), (31)) AS days(dayofmonth) ) SELECT getalldays.dayofmonth AS DAY,
                                                                                                                                                                                                                                     coalesce(SUM, 0) AS delay
     FROM getalldays
     LEFT JOIN
         ( SELECT flights.dayofmonth,
                  sum(flights.arrivaldelay + flights.departuredelay)
          FROM flights,
               airports
          WHERE flights.originairportid = airports.airportid
              AND airports.city = 'Albuquerque'
          GROUP BY flights.dayofmonth ) AS tbl ON getalldays.dayofmonth = tbl.dayofmonth) AS tbl
ORDER BY delay ASC,
         DAY ASC;

--10--
WITH tbl AS
    ( SELECT city,
             count(*)
     FROM
         ( SELECT DISTINCT a1.city AS city,
                           a2.city AS c2
          FROM airports AS a1,
               airports AS a2,
               flights
          WHERE flights.originairportid = a1.airportid
              AND flights.destairportid = a2.airportid
              AND a1.state = 'New York'
              AND a2.state = 'New York' ) AS tbl
     GROUP BY city),
     citytbl AS
    ( SELECT DISTINCT city
     FROM airports
     WHERE airports.state = 'New York' )
SELECT city AS name
FROM tbl
WHERE COUNT =
        (SELECT count(*) - 1
         FROM citytbl)
ORDER BY city;

--11--
WITH RECURSIVE path(originairportid, destairportid, visited, iscycle, delay) AS
    ( SELECT DISTINCT flights.originairportid,
                      flights.destairportid, array[flights.originairportid,
                                                   flights.destairportid], FALSE,
                                                                           flights.arrivaldelay + flights.departuredelay
     FROM flights
     UNION SELECT DISTINCT path.originairportid,
                           flights.destairportid,
                           path.visited || flights.destairportid, (flights.destairportid = path.visited[1] IS TRUE), flights.arrivaldelay + flights.departuredelay
     FROM flights,
          path
     WHERE NOT path.iscycle
         AND (flights.destairportid <> all(path.visited[2:array_length(path.visited, 1)]))
         AND path.destairportid = flights.originairportid
         AND flights.arrivaldelay + flights.departuredelay >= path.delay )
SELECT DISTINCT a1.city AS name1,
                a2.city AS name2
FROM path,
     airports AS a1,
     airports AS a2
WHERE a1.airportid = path.originairportid
    AND a2.airportid = path.destairportid
ORDER BY a1.city,
         a2.city;

--12--

SELECT *
FROM
    ( SELECT authordetails.authorid,
             coalesce(tbl.length, -1) AS LENGTH
     FROM authordetails
     LEFT JOIN
         ( SELECT authorpath.author2,
                  min(array_length(authorpath.visited, 1) - 1) AS LENGTH
          FROM authorpath
          WHERE authorpath.author1 <> authorpath.author2
              AND authorpath.author1 = 1235
          GROUP BY authorpath.author1,
                   authorpath.author2 ) AS tbl ON authordetails.authorid = tbl.author2) AS tbl
WHERE authorid <> 1235
ORDER BY LENGTH DESC, authorid ASC;

--13--

SELECT COUNT
FROM
    ( SELECT DISTINCT authorpath.author1,
                      authorpath.author2,
                      COUNT
     FROM
         ( SELECT coalesce(count(*), 0) AS COUNT
          FROM
              ( WITH RECURSIVE authorpath13(author2, visited) AS
                   ( SELECT DISTINCT author2, array[author1,
                                                    author2]
                    FROM authorgraph,
                         authordetails
                    WHERE author1 = 1558
                        AND author2 = authorid
                        AND age > 35
                    UNION SELECT DISTINCT authorgraph.author2,
                                          authorpath13.visited || authorgraph.author2
                    FROM authorgraph,
                         authorpath13,
                         authordetails AS a1,
                         authordetails AS a2
                    WHERE authorgraph.author2 <> all(authorpath13.visited)
                        AND (authorgraph.author1 = authorpath13.author2)
                        AND a1.authorid = authorgraph.author1
                        AND a2.authorid = authorgraph.author2
                        AND a1.age > 35
                        AND a2.age > 35
                        AND a1.gender <> a2.gender ) SELECT DISTINCT visited
               FROM authorpath13,
                    authorgraph
               WHERE authorpath13.author2 = authorgraph.author1
                   AND authorgraph.author2 = 2826
                   AND 2826 <> all(visited)
               UNION SELECT array[1558] AS visited
               FROM authorgraph
               WHERE author1 = 1558
                   AND author2 = 2826 ) AS tbl ) AS tbl,
          authorpath
     WHERE authorpath.author1 = 1558
         AND authorpath.author2 = 2826
     UNION SELECT 1558 AS author1,
                  2826 AS author2,
                  -1 AS COUNT
     ORDER BY COUNT DESC
     LIMIT 1) AS tbl;

--14--

SELECT COUNT
FROM
    ( SELECT DISTINCT author1,
                      author2,
                      COUNT
     FROM
         ( SELECT count(*)
          FROM
              ( SELECT authorpath.visited,
                       coalesce(count(1), 0) AS COUNT
               FROM authorpath,
                    authorpaperlist,
                    citationpath
               WHERE authorpath.author1 = 704
                   AND authorpath.author2 = 102
                   AND array_length(authorpath.visited, 1) > 2
                   AND authorpaperlist.authorid = any(authorpath.visited[2:array_length(authorpath.visited, 1) - 1])
                   AND citationpath.paper1 = authorpaperlist.paperid
                   AND citationpath.paper2 = 126
               GROUP BY authorpath.visited ) AS tbl ) AS tbl,
          authorpath
     WHERE authorpath.author1 = 704
         AND authorpath.author2 = 102
     UNION SELECT 704 AS author1,
                  102 AS author2,
                  -1 AS COUNT
     ORDER BY COUNT DESC
     LIMIT 1) AS tbl;

--15--

SELECT COUNT
FROM
    ( SELECT DISTINCT author1,
                      author2,
                      COUNT
     FROM
         ( SELECT count(*)
          FROM
              ( WITH RECURSIVE authorpath13(author2, visited) AS
                   ( SELECT DISTINCT author2, array[author1,
                                                    author2]
                    FROM authorgraph
                    WHERE author1 = 1745
                    UNION SELECT DISTINCT authorgraph.author2,
                                          authorpath13.visited || authorgraph.author2
                    FROM authorgraph,
                         authorpath13,
                         countcitations AS c1,
                         countcitations AS c2
                    WHERE authorgraph.author2 <> all(authorpath13.visited)
                        AND (authorgraph.author1 = authorpath13.author2)
                        AND c1.authorid = authorgraph.author1
                        AND c2.authorid = authorgraph.author2
                        AND c1.count < c2.count ),
                               authorpath14(author2, visited) AS
                   ( SELECT DISTINCT author2, array[author1,
                                                    author2]
                    FROM authorgraph
                    WHERE author1 = 1745
                    UNION SELECT DISTINCT authorgraph.author2,
                                          authorpath14.visited || authorgraph.author2
                    FROM authorgraph,
                         authorpath14,
                         countcitations AS c1,
                         countcitations AS c2
                    WHERE authorgraph.author2 <> all(authorpath14.visited)
                        AND (authorgraph.author1 = authorpath14.author2)
                        AND c1.authorid = authorgraph.author1
                        AND c2.authorid = authorgraph.author2
                        AND c1.count > c2.count ) SELECT DISTINCT visited || 456 AS visited
               FROM
                   ( SELECT *
                    FROM authorpath13
                    UNION SELECT *
                    FROM authorpath14 ) AS finalpaths,
                    authorgraph
               WHERE finalpaths.author2 = authorgraph.author1
                   AND authorgraph.author2 = 456
                   AND 456 <> all(finalpaths.visited)
               UNION SELECT array[1745,
                                  456] AS visited
               FROM authorgraph
               WHERE author1 = 1745
                   AND author2 = 456 ) AS tbl ) AS tbl,
          authorpath
     WHERE authorpath.author1 = 1745
         AND authorpath.author2 = 456
     UNION SELECT 1745 AS author1,
                  456 AS author2,
                  -1 AS COUNT
     ORDER BY COUNT DESC
     LIMIT 1) AS tbl;

--16--

SELECT authorid
FROM
    ( SELECT authordetails.authorid,
             coalesce(COUNT, 0) AS COUNT
     FROM authordetails
     LEFT JOIN
         ( SELECT author1 AS authorid,
                  COUNT
          FROM
              ( SELECT author1,
                       count(*)
               FROM
                   ( SELECT *
                    FROM authorcitationgraph
                    EXCEPT SELECT *
                    FROM authorgraph
                    ORDER BY author1,
                             author2 ) AS tbl
               GROUP BY author1 ) AS tbl ) AS tbl ON authordetails.authorid = tbl.authorid) AS tbl
ORDER BY COUNT DESC, authorid ASC
LIMIT 10;

--17--

SELECT authorid
FROM
    ( SELECT authordetails.authorid,
             coalesce(threedcitations, 0) AS COUNT
     FROM authordetails
     LEFT JOIN
         ( SELECT author1 AS authorid,
                  threedcitations
          FROM
              ( WITH threed AS
                   ( SELECT DISTINCT author1,
                                     author2
                    FROM authorpath
                    WHERE array_length(authorpath.visited, 1) <= 4
                    EXCEPT SELECT DISTINCT author1,
                                           author2
                    FROM authorpath
                    WHERE array_length(authorpath.visited, 1) <= 3 ) SELECT threed.author1,
                                                                            sum(countcitations.count) AS threedcitations
               FROM threed,
                    countcitations
               WHERE countcitations.authorid = threed.author2
               GROUP BY threed.author1 ) AS tbl ) AS tbl ON authordetails.authorid = tbl.authorid
     ORDER BY COUNT DESC, authordetails.authorid ASC
     LIMIT 10) AS tbl;

--18--

SELECT count(*)
FROM authorpath
WHERE author1 = 3552
    AND author2 = 321
    AND ( 1436 = any(visited)
         OR 562 = any(visited)
         OR 921 = any(visited));

--19--

SELECT count(*)
FROM ( WITH RECURSIVE authorpath(author1, author2, visited) AS
          ( SELECT DISTINCT author1,
                            author2, array[author1,
                                           author2]
           FROM authorgraph
           UNION SELECT DISTINCT authorpath.author1,
                                 authorgraph.author2,
                                 authorpath.visited || authorgraph.author2
           FROM authorgraph,
                authorpath
           WHERE (authorgraph.author1 = authorpath.author2)
               AND (authorgraph.author2 <> all(authorpath.visited)) ),
                      abpaths AS
          ( SELECT visited[2:array_length(visited, 1) - 1] AS visited
           FROM authorpath
           WHERE author1 = 3552
               AND author2 = 321 )
          ( SELECT visited
           FROM abpaths )
      EXCEPT
          ( SELECT DISTINCT visited
           FROM abpaths,
                authordetails AS a1,
                authordetails AS a2
           WHERE a1.authorid = any(visited)
               AND a2.authorid = any(visited)
               AND a1.city = a2.city
               AND a1.authorid <> a2.authorid
           UNION SELECT DISTINCT visited
           FROM abpaths,
                authordirectcited AS a1,
                authordirectcited AS a2
           WHERE a1.author1 = any(visited)
               AND a1.author2 = any(visited)
               AND a2.author2 = a1.author1
               AND a2.author1 = a1.author2
               AND a1.author1 <> a1.author2 )) AS tbl
UNION
SELECT -1 AS COUNT
ORDER BY COUNT DESC
LIMIT 1;

--20--

SELECT count(*)
FROM ( WITH RECURSIVE authorpath(author1, author2, visited) AS
          ( SELECT DISTINCT author1,
                            author2, array[author1,
                                           author2]
           FROM authorgraph
           UNION SELECT DISTINCT authorpath.author1,
                                 authorgraph.author2,
                                 authorpath.visited || authorgraph.author2
           FROM authorgraph,
                authorpath
           WHERE (authorgraph.author1 = authorpath.author2)
               AND (authorgraph.author2 <> all(authorpath.visited)) ),
                      abpaths AS
          ( SELECT authorpath.visited[2:array_length(authorpath.visited, 1) - 1] AS visited
           FROM authorpath
           WHERE authorpath.author1 = 3552
               AND authorpath.author2 = 321 )
          ( SELECT abpaths.visited
           FROM abpaths )
      EXCEPT
          ( SELECT DISTINCT abpaths.visited
           FROM abpaths,
                authorcitationgraph
           WHERE authorcitationgraph.author1 = any(abpaths.visited)
               AND authorcitationgraph.author2 = any(abpaths.visited)
               AND authorcitationgraph.author1 <> authorcitationgraph.author2 )) AS tbl
UNION
SELECT -1 AS COUNT
ORDER BY COUNT DESC
LIMIT 1;

--21--

SELECT *
FROM
    ( WITH tbl AS
         ( SELECT DISTINCT component,
                           conference AS conferencename
          FROM
              ( WITH RECURSIVE reachable(author1, author2, conference) AS
                   ( SELECT DISTINCT authorid,
                                     authorid,
                                     conferencename
                    FROM authorpaperlist,
                         paperdetails
                    WHERE authorpaperlist.paperid = paperdetails.paperid
                    UNION SELECT DISTINCT reachable.author1,
                                          a2.authorid,
                                          conferencename
                    FROM reachable,
                         authorpaperlist AS a1,
                         authorpaperlist AS a2,
                         paperdetails
                    WHERE reachable.author2 = a1.authorid
                        AND a1.paperid = a2.paperid
                        AND a1.paperid = paperdetails.paperid
                        AND reachable.conference = paperdetails.conferencename ) SELECT author1,
                                                                                        conference,
                                                                                        array_agg(author2
                                                                                                  ORDER BY author2) AS component
               FROM reachable
               GROUP BY author1,
                        conference ) AS tbl ) SELECT conferencename,
                                                     count(*)
     FROM tbl
     GROUP BY conferencename) AS tbl
ORDER BY COUNT DESC, conferencename ASC;

--22--

SELECT *
FROM
    ( WITH tbl AS
         ( SELECT DISTINCT component,
                           conference AS conferencename
          FROM
              ( WITH RECURSIVE reachable(author1, author2, conference) AS
                   ( SELECT DISTINCT authorid,
                                     authorid,
                                     conferencename
                    FROM authorpaperlist,
                         paperdetails
                    WHERE authorpaperlist.paperid = paperdetails.paperid
                    UNION SELECT DISTINCT reachable.author1,
                                          a2.authorid,
                                          conferencename
                    FROM reachable,
                         authorpaperlist AS a1,
                         authorpaperlist AS a2,
                         paperdetails
                    WHERE reachable.author2 = a1.authorid
                        AND a1.paperid = a2.paperid
                        AND a1.paperid = paperdetails.paperid
                        AND reachable.conference = paperdetails.conferencename ) SELECT author1,
                                                                                        conference,
                                                                                        array_agg(author2
                                                                                                  ORDER BY author2) AS component
               FROM reachable
               GROUP BY author1,
                        conference ) AS tbl ) SELECT conferencename,
                                                     array_length(component, 1) AS COUNT
     FROM tbl) AS tbl
ORDER BY COUNT ASC, conferencename ASC;

--CLEANUP--

DROP VIEW countcitations;


DROP VIEW authorcitationgraph;


DROP VIEW citationgraph;


DROP VIEW authordirectcited;


DROP VIEW citationpath;


DROP VIEW authorpath;


DROP VIEW authorgraph;


DROP VIEW path;
