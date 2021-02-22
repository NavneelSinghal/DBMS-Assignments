--1--
WITH raw_table AS (
    WITH wickets_summary AS (
        WITH bowler_wickets AS (
            SELECT match_id, ball_id, over_id, innings_no
            FROM wicket_taken
            WHERE kind_out IN (1, 2, 4, 6, 7, 8)
        ),
        ball_summary AS (
            SELECT match_id, ball_id, over_id, innings_no, bowler, team_bowling
            FROM ball_by_ball
        )
        SELECT ball_summary.match_id, ball_summary.bowler, ball_summary.team_bowling
        FROM bowler_wickets, ball_summary
        WHERE bowler_wickets.match_id = ball_summary.match_id
        AND bowler_wickets.ball_id = ball_summary.ball_id
        AND bowler_wickets.over_id = ball_summary.over_id
        AND bowler_wickets.innings_no = ball_summary.innings_no
        AND bowler_wickets.innings_no IN (1, 2)
    )
    SELECT match_id, bowler, team_bowling, COUNT(*) AS num_wickets
    FROM wickets_summary
    GROUP BY match_id, bowler, team_bowling
)
SELECT match_id, player_name, team_name, num_wickets
FROM raw_table, player, team
WHERE player.player_id = bowler
AND team.team_id = team_bowling
AND num_wickets >= 5
ORDER BY num_wickets DESC, player_name ASC, team_name ASC, match_id ASC;

--2--
WITH raw_table AS (
    WITH match_summary AS (
        SELECT man_of_the_match, team_1, team_2, match_id, match_winner
        FROM match
        WHERE win_id != 3
    )
    SELECT player_match.player_id
    FROM match_summary, player_match
    WHERE 
    ((match_winner = team_1 AND team_2 = team_id) OR (match_winner = team_2 AND team_1 = team_id))
    AND match_summary.match_id = player_match.match_id
    AND match_summary.man_of_the_match = player_match.player_id
)
SELECT player_name, COUNT(player.player_id) as num_matches
FROM raw_table, player
WHERE raw_table.player_id = player.player_id
GROUP BY player.player_id
ORDER BY num_matches DESC, player_name ASC
LIMIT 3;

--3--
SELECT player_name
FROM player, (
    SELECT fielders, COUNT(fielders) AS catches
    FROM wicket_taken, match, season
    WHERE match.match_id = wicket_taken.match_id
    AND wicket_taken.kind_out IN (1, 3, 6)
    AND match.season_id = season.season_id
    AND season.season_year = 2012
    GROUP BY fielders
) AS fldr
WHERE fielders = player.player_id
ORDER by catches DESC, player_name ASC
LIMIT 1;

--4--
SELECT season_year, player_name, num_matches
FROM player, (
    SELECT player_id, season_year, COUNT(player_id) AS num_matches
    FROM season, player_match, match
    WHERE season.season_id = match.season_id
    AND match.match_id = player_match.match_id
    AND player_match.player_id = season.purple_cap
    GROUP BY player_id, season_year
) AS tbl
WHERE player.player_id = tbl.player_id
ORDER BY season_year;

--5--
SELECT player_name
FROM (
    SELECT DISTINCT player_id
    FROM (
        SELECT player_match.player_id, SUM(batsman_scored.runs_scored) AS runs
        FROM ball_by_ball, match, batsman_scored, player_match
        WHERE ball_by_ball.match_id = batsman_scored.match_id
        AND ball_by_ball.over_id = batsman_scored.over_id
        AND ball_by_ball.ball_id = batsman_scored.ball_id
        AND ball_by_ball.innings_no = batsman_scored.innings_no
        AND ball_by_ball.innings_no IN (1, 2)
        AND match.match_id = ball_by_ball.match_id
        AND player_match.match_id = ball_by_ball.match_id
        AND player_match.player_id = ball_by_ball.striker
        AND match.match_winner IS NOT NULL
        AND match.match_winner != player_match.team_id
        GROUP BY player_match.player_id, player_match.match_id
        HAVING SUM(batsman_scored.runs_scored) > 50
    ) AS tbl
) AS tbl, player
WHERE tbl.player_id = player.player_id
ORDER BY player_name;

--6--
SELECT *
FROM (
    SELECT season_year, team_name, ROW_NUMBER() OVER (PARTITION BY season_year) AS rank
    FROM (
        SELECT season_year, team_name, COUNT(player_id) AS lh
        FROM (
            SELECT DISTINCT season.season_year, player_match.team_id, player_match.player_id
            FROM player, season, player_match, match
            WHERE season.season_id = match.season_id
            AND match.match_id = player_match.match_id
            AND player_match.player_id = player.player_id
            AND player.batting_hand = 1
            AND player.country_id > 1
        ) AS tbl, team
        WHERE team.team_id = tbl.team_id
        GROUP BY season_year, team_name
        ORDER BY season_year, lh DESC, team_name
    ) AS tbl
) AS tbl
WHERE rank <= 5
ORDER BY season_year ASC;

--7--
SELECT team_name
FROM (
    SELECT team.team_name, COUNT(team.team_name) as wins
    FROM season, match, team
    WHERE season.season_id = match.season_id
    AND season.season_year = 2009
    AND match.match_winner IS NOT NULL
    AND match.match_winner = team.team_id
    GROUP BY team_id
    ORDER BY wins DESC, team.team_name ASC
) as tbl;

--8--
SELECT team_name, player_name, runs FROM (
    SELECT * 
    FROM (
        SELECT player_name, team_batting, runs, ROW_NUMBER() OVER (PARTITION BY team_batting ORDER BY runs DESC) AS rank
        FROM (
            SELECT player.player_name, ball_by_ball.team_batting, SUM(batsman_scored.runs_scored) AS runs
            FROM season, match, batsman_scored, ball_by_ball, player
            WHERE season.season_id = match.season_id
            AND season.season_year = 2010
            AND match.match_id = ball_by_ball.match_id
            AND match.match_id = batsman_scored.match_id
            AND ball_by_ball.innings_no = batsman_scored.innings_no
            AND ball_by_ball.innings_no IN (1, 2)
            AND ball_by_ball.over_id = batsman_scored.over_id
            AND ball_by_ball.ball_id = batsman_scored.ball_id
            AND player.player_id = ball_by_ball.striker
            GROUP BY player.player_name, ball_by_ball.team_batting
            ORDER BY runs DESC, player_name ASC, team_batting ASC
        ) as tbl
    ) as tbl
    WHERE rank <= 1
) as tbl, team
WHERE team.team_id = team_batting
ORDER BY team_name, player_name;

--9--
SELECT team1.team_name, team2.team_name AS opponent_team_name, COUNT(batsman_scored.runs_scored) AS number_of_sixes
FROM season, match, ball_by_ball, batsman_scored, team AS team1, team AS team2
WHERE season.season_id = match.season_id
AND season.season_year = 2008
AND match.match_id = batsman_scored.match_id
AND ball_by_ball.match_id = match.match_id
AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.innings_no IN (1, 2)
AND ball_by_ball.innings_no = batsman_scored.innings_no
AND ball_by_ball.ball_id = batsman_scored.ball_id
AND batsman_scored.runs_scored = 6
AND team1.team_id = ball_by_ball.team_batting
AND team2.team_id = ball_by_ball.team_bowling
GROUP BY match.match_id, ball_by_ball.innings_no, ball_by_ball.team_batting, team1.team_name, team2.team_name
ORDER BY number_of_sixes DESC, team1.team_name
LIMIT 3;

--10--
WITH wicket_table AS (
    SELECT ball_by_ball.bowler AS player_id, COUNT(*) as wickets
    FROM match, wicket_taken, season, ball_by_ball
    WHERE match.match_id = wicket_taken.match_id
    AND match.season_id = season.season_id
    AND wicket_taken.match_id = match.match_id
    AND wicket_taken.match_id = ball_by_ball.match_id
    AND wicket_taken.over_id = ball_by_ball.over_id
    AND wicket_taken.ball_id = ball_by_ball.ball_id
    AND wicket_taken.innings_no = ball_by_ball.innings_no
    AND ball_by_ball.innings_no IN (1, 2)
    AND wicket_taken.kind_out IN (1, 2, 4, 6, 7, 8)
    GROUP BY player_id
    ORDER BY wickets DESC, player_id
),
average_wickets AS (
    SELECT ROUND(AVG(wickets), 2) AS average_wickets
    FROM wicket_table
),
total_run_table AS (
    SELECT ball_by_ball.striker AS player_id, SUM(batsman_scored.runs_scored) as batting_sum
    FROM match, batsman_scored, season, ball_by_ball, wicket_table, average_wickets
    WHERE match.match_id = batsman_scored.match_id
    AND match.season_id = season.season_id
    AND ball_by_ball.match_id = match.match_id
    AND batsman_scored.match_id = ball_by_ball.match_id
    AND batsman_scored.over_id = ball_by_ball.over_id
    AND batsman_scored.ball_id = ball_by_ball.ball_id
    AND batsman_scored.innings_no = ball_by_ball.innings_no
    AND ball_by_ball.innings_no IN (1, 2)
    AND wicket_table.player_id = ball_by_ball.striker
    AND wicket_table.wickets > average_wickets.average_wickets
    GROUP BY ball_by_ball.striker
),
total_matches_table AS (
    SELECT player_id, COUNT(match_id) AS num_matches
    FROM (
        SELECT DISTINCT player_match.player_id, match.match_id
        FROM player_match, match, ball_by_ball, wicket_table, average_wickets
        WHERE wicket_table.player_id = player_match.player_id
        AND wicket_table.wickets > average_wickets.average_wickets
        AND player_match.match_id = match.match_id
        AND ball_by_ball.innings_no IN (1, 2)
        AND ball_by_ball.striker = player_match.player_id
        AND ball_by_ball.match_id = match.match_id
    ) AS match_table
    GROUP BY player_id
),
run_table AS (
    SELECT total_matches_table.player_id, ROUND((total_run_table.batting_sum / total_matches_table.num_matches), 2) AS batting_average
    FROM total_matches_table, total_run_table
    WHERE total_matches_table.player_id = total_run_table.player_id
)
SELECT bowling_style.bowling_skill AS bowling_category, player_name, batting_average
FROM (
    SELECT player.bowling_skill AS bowling_category, player.player_name, batting_average, ROW_NUMBER() OVER (PARTITION BY bowling_skill ORDER BY batting_average DESC) as rank
    FROM player, wicket_table, run_table, average_wickets
    WHERE player.player_id = wicket_table.player_id
    AND player.player_id = run_table.player_id
    AND wicket_table.wickets > average_wickets.average_wickets) AS x, bowling_style
WHERE rank <= 1
AND bowling_style.bowling_id = x.bowling_category
ORDER BY bowling_style.bowling_skill;

--11--
SELECT season.season_year, player_name, wickets AS num_wickets, runs
FROM (
    SELECT ball_by_ball.striker AS player_id, season.season_id, SUM(batsman_scored.runs_scored) as runs
    FROM match, batsman_scored, season, ball_by_ball
    WHERE match.match_id = batsman_scored.match_id
    AND match.season_id = season.season_id
    AND ball_by_ball.match_id = match.match_id
    AND batsman_scored.match_id = ball_by_ball.match_id
    AND batsman_scored.over_id = ball_by_ball.over_id
    AND batsman_scored.ball_id = ball_by_ball.ball_id
    AND batsman_scored.innings_no = ball_by_ball.innings_no
    AND ball_by_ball.innings_no IN (1, 2)
    GROUP BY player_id, season.season_id
    ORDER BY season_id, runs DESC, player_id
    ) AS run_table, (
    SELECT ball_by_ball.bowler AS player_id, season.season_id, COUNT(*) as wickets
    FROM match, wicket_taken, season, ball_by_ball
    WHERE match.match_id = wicket_taken.match_id
    AND match.season_id = season.season_id
    AND wicket_taken.match_id = match.match_id
    AND wicket_taken.match_id = ball_by_ball.match_id
    AND wicket_taken.over_id = ball_by_ball.over_id
    AND wicket_taken.ball_id = ball_by_ball.ball_id
    AND wicket_taken.innings_no = ball_by_ball.innings_no
    AND ball_by_ball.innings_no IN (1, 2)
    AND wicket_taken.kind_out IN (1, 2, 4, 6, 7, 8)
    GROUP BY player_id, season.season_id
    ORDER BY season_id, wickets DESC, player_id
    ) AS wicket_table, (
    SELECT player_match.player_id, season.season_id, COUNT(*) as total_matches
    FROM match, season, player_match
    WHERE match.match_id = player_match.match_id
    AND match.season_id = season.season_id
    GROUP BY player_id, season.season_id
    ORDER BY season_id, total_matches DESC, player_id
) AS match_table, season, player
WHERE player.player_id = match_table.player_id
AND player.player_id = run_table.player_id
AND player.player_id = wicket_table.player_id
AND season.season_id = match_table.season_id
AND season.season_id = run_table.season_id
AND season.season_id = wicket_table.season_id
AND match_table.total_matches >= 10
AND run_table.runs >= 150
AND wicket_table.wickets >= 5
ORDER BY wickets DESC, runs DESC, player_name, season_year;

--12--
SELECT match.match_id, player.player_name, team.team_name, COUNT(*) AS num_wickets, season.season_year
FROM match, player_match, ball_by_ball, team, season, player, wicket_taken
WHERE match.match_id = player_match.match_id
AND ball_by_ball.match_id = match.match_id
AND wicket_taken.match_id = ball_by_ball.match_id
AND wicket_taken.kind_out IN (1, 2, 4, 6, 7, 8)
AND player.player_id = player_match.player_id
AND ball_by_ball.bowler = player.player_id
AND team.team_id = ball_by_ball.team_bowling
AND player_match.team_id = team.team_id
AND wicket_taken.over_id = ball_by_ball.over_id
AND wicket_taken.ball_id = ball_by_ball.ball_id
AND wicket_taken.innings_no = ball_by_ball.innings_no
AND ball_by_ball.innings_no IN (1, 2)
AND match.season_id = season.season_id
GROUP BY match.match_id, player.player_id, player.player_name, team.team_name, season_year
ORDER BY num_wickets DESC, player.player_name, match.match_id
LIMIT 1;

--13--
SELECT player_name
FROM (
    SELECT *
    FROM (
        SELECT player_id, ROW_NUMBER() OVER (PARTITION BY player_id) as row_num
        FROM (
            SELECT DISTINCT player.player_id, season.season_id
            FROM player, season, player_match, match
            WHERE player.player_id = player_match.player_id
            AND match.match_id = player_match.match_id
            AND match.season_id = season.season_id
        ) AS tbl
    ) AS tbl
    WHERE row_num >= (
        SELECT COUNT(*) FROM season
    )
) as tbl, player
WHERE player.player_id = tbl.player_id
ORDER BY player_name;

--14--
SELECT season_year, match_id, team_name
FROM (
    SELECT season_year, team_name, match_id, COUNT(player_id), ROW_NUMBER() OVER (PARTITION BY season_year ORDER BY COUNT(player_id) DESC, team_name, match_id) AS rank
    FROM (
        SELECT season.season_id, player_match.team_id, match.match_id, player_match.player_id
        FROM season, player_match, match, batsman_scored, ball_by_ball
        WHERE match.match_id = player_match.match_id
        AND match.match_winner IS NOT NULL
        AND match.match_winner = player_match.team_id
        AND match.match_id = ball_by_ball.match_id
        AND ball_by_ball.innings_no IN (1, 2)
        AND ball_by_ball.innings_no = batsman_scored.innings_no
        AND ball_by_ball.match_id = batsman_scored.match_id
        AND ball_by_ball.over_id = batsman_scored.over_id
        AND ball_by_ball.ball_id = batsman_scored.ball_id
        AND ball_by_ball.striker = player_match.player_id
        AND season.season_id = match.season_id
        GROUP BY season.season_id, player_match.team_id, match.match_id, player_match.player_id
        HAVING SUM(batsman_scored.runs_scored) >= 50
    ) as tbl, season, team
    WHERE season.season_id = tbl.season_id
    AND team.team_id = tbl.team_id
    GROUP BY season_year, team_name, match_id
) AS tbl
WHERE rank <= 3;

--15--
SELECT season_year, top_batsman, max_runs, top_bowler, max_wickets
FROM (
    SELECT player_name AS top_batsman, season_id, runs AS max_runs
    FROM (
        SELECT player_id AS batsman_id, player_name, season_id, runs, ROW_NUMBER() OVER (PARTITION BY season_id ORDER BY runs DESC, player_name ASC) AS rank
        FROM (
            SELECT ball_by_ball.striker AS player_id, player_name, season.season_id, SUM(batsman_scored.runs_scored) as runs
            FROM match, batsman_scored, season, ball_by_ball, player
            WHERE match.match_id = batsman_scored.match_id
            AND match.season_id = season.season_id
            AND ball_by_ball.match_id = match.match_id
            AND batsman_scored.match_id = ball_by_ball.match_id
            AND batsman_scored.over_id = ball_by_ball.over_id
            AND batsman_scored.ball_id = ball_by_ball.ball_id
            AND batsman_scored.innings_no = ball_by_ball.innings_no
            AND ball_by_ball.innings_no IN (1, 2)
            AND player.player_id = ball_by_ball.striker
            GROUP BY ball_by_ball.striker, season.season_id, player_name
            ORDER BY season_id, runs DESC, player_name
        ) AS batsman_table
    ) AS batsman_table
    WHERE rank = 2
) AS batsman_table, (
    SELECT player_name AS top_bowler, season_id, wickets AS max_wickets
    FROM (
        SELECT player_id AS bowler_id, player_name, season_id, wickets, ROW_NUMBER() OVER (PARTITION BY season_id ORDER BY wickets DESC, player_name) AS rank
        FROM (
            SELECT ball_by_ball.bowler AS player_id, player_name, season.season_id, COUNT(*) as wickets
            FROM match, wicket_taken, season, ball_by_ball, player
            WHERE match.match_id = wicket_taken.match_id
            AND match.season_id = season.season_id
            AND wicket_taken.match_id = match.match_id
            AND wicket_taken.match_id = ball_by_ball.match_id
            AND wicket_taken.over_id = ball_by_ball.over_id
            AND wicket_taken.ball_id = ball_by_ball.ball_id
            AND wicket_taken.innings_no = ball_by_ball.innings_no
            AND ball_by_ball.innings_no IN (1, 2)
            AND wicket_taken.kind_out IN (1, 2, 4, 6, 7, 8)
            AND player.player_id = ball_by_ball.bowler
            GROUP BY ball_by_ball.bowler, season.season_id, player_name
            ORDER BY season_id, wickets DESC, player_name
        ) AS bowler_table
    ) AS bowler_table
    WHERE rank = 2
) AS bowler_table, season
WHERE season.season_id = bowler_table.season_id
AND season.season_id = batsman_table.season_id;

--16--
SELECT team_name
FROM (
    SELECT team.team_name, COUNT(team.team_name) AS wins
    FROM match, team
    WHERE match.match_winner IS NOT NULL
    AND match.match_winner = team.team_id
    AND match.season_id = (SELECT season_id FROM season WHERE season_year = 2008)
    AND (
        (match.team_1 = team.team_id AND match.team_2 = (SELECT team_id FROM team WHERE team_name = 'Royal Challengers Bangalore'))
        OR
        (match.team_2 = team.team_id AND match.team_1 = (SELECT team_id FROM team WHERE team_name = 'Royal Challengers Bangalore'))
    )
    GROUP BY team.team_name
) AS teams
ORDER BY wins DESC, team_name;

--17--
SELECT team_name, player_name, count
FROM (
    SELECT team_name, player_name, count, ROW_NUMBER() OVER (PARTITION BY team_name ORDER BY count DESC, player_name) as rank
    FROM (
        SELECT team_name, player_name, COUNT(*) as count
        FROM match, player_match, team, player
        WHERE player_match.match_id = match.match_id
        AND player_match.player_id = match.man_of_the_match
        AND team.team_id = player_match.team_id
        AND player.player_id = match.man_of_the_match
        GROUP BY team_name, player_name
        ORDER BY count, team_name, player_name
    ) as tbl
) as tbl
WHERE rank <= 1;

--18--
SELECT player_name
FROM (
    WITH player_table AS (
        SELECT player_id
        FROM (
            SELECT player_id, COUNT(team_id) AS num_teams
            FROM (
                SELECT DISTINCT player_id, team_id
                FROM player_match
            ) AS player_table
            GROUP BY player_id
            HAVING COUNT(team_id) >= 3
        ) AS player_table
    ),
    bowler_table AS (
        SELECT bowler AS player_id, COUNT(bowler) AS occasions
        FROM (
            SELECT ball_by_ball.bowler, ball_by_ball.match_id, ball_by_ball.over_id, ball_by_ball.innings_no, SUM(batsman_scored.runs_scored) AS runs_conceded
            FROM ball_by_ball, batsman_scored
            WHERE ball_by_ball.innings_no IN (1, 2)
            AND ball_by_ball.match_id = batsman_scored.match_id
            AND ball_by_ball.over_id = batsman_scored.over_id
            AND ball_by_ball.ball_id = batsman_scored.ball_id
            AND ball_by_ball.innings_no = batsman_scored.innings_no
            GROUP BY ball_by_ball.match_id, ball_by_ball.over_id, ball_by_ball.innings_no, ball_by_ball.bowler
            HAVING SUM(batsman_scored.runs_scored) > 20
        ) AS bowler_table
        GROUP BY player_id
    )
    SELECT player_name, occasions
    FROM player_table, bowler_table, player
    WHERE player_table.player_id = bowler_table.player_id
    AND player_table.player_id = player.player_id
    ORDER BY occasions DESC, player_name
    LIMIT 5
) as tbl;

--19--
SELECT team_name, ROUND(AVG(runs), 2) AS avg_runs
FROM (
    SELECT team_name, SUM(batsman_scored.runs_scored) AS runs
    FROM match, ball_by_ball, team, batsman_scored
    WHERE match.season_id = (SELECT season_id FROM season WHERE season.season_year = 2010)
    AND ball_by_ball.innings_no IN (1, 2)
    AND ball_by_ball.match_id = match.match_id
    AND ball_by_ball.team_batting = team.team_id
    AND batsman_scored.match_id = ball_by_ball.match_id
    AND batsman_scored.over_id = ball_by_ball.over_id
    AND batsman_scored.ball_id = ball_by_ball.ball_id
    AND batsman_scored.innings_no = ball_by_ball.innings_no
    GROUP BY team_name, match.match_id
) AS tbl
GROUP BY team_name
ORDER BY team_name;

--20--
SELECT player_name
FROM player, wicket_taken
WHERE player.player_id = wicket_taken.player_out
AND wicket_taken.innings_no IN (1, 2)
AND wicket_taken.over_id = 1
GROUP BY player_name
ORDER BY COUNT(player_name) DESC, player_name
LIMIT 10;

--21--
SELECT match.match_id, team1.team_name AS team_1_name, team2.team_name AS team_2_name, team3.team_name AS match_winner_name, COUNT(batsman_scored.runs_scored) AS number_of_boundaries
FROM match, ball_by_ball, team AS team1, team AS team2, team AS team3, batsman_scored
WHERE match.match_id = ball_by_ball.match_id
AND match.match_winner IS NOT NULL
AND match.match_winner = ball_by_ball.team_batting
AND batsman_scored.innings_no = 2
AND team1.team_id = match.team_1
AND team2.team_id = match.team_2
AND team3.team_id = match.match_winner
AND batsman_scored.runs_scored IN (4, 6)
AND batsman_scored.match_id = ball_by_ball.match_id
AND batsman_scored.over_id = ball_by_ball.over_id
AND batsman_scored.ball_id = ball_by_ball.ball_id
AND batsman_scored.innings_no = ball_by_ball.innings_no
GROUP BY match.match_id, team1.team_name, team2.team_name, team3.team_name
ORDER BY number_of_boundaries, match_winner_name, team_1_name, team_2_name
LIMIT 3;

--22--
SELECT country_name
FROM (
    WITH bowler_table AS (
        SELECT ball_by_ball.bowler, SUM(batsman_scored.runs_scored) AS runs_conceded
        FROM ball_by_ball, batsman_scored
        WHERE ball_by_ball.innings_no IN (1, 2)
        AND ball_by_ball.match_id = batsman_scored.match_id
        AND ball_by_ball.over_id = batsman_scored.over_id
        AND ball_by_ball.ball_id = batsman_scored.ball_id
        AND ball_by_ball.innings_no = batsman_scored.innings_no
        GROUP BY ball_by_ball.bowler
    ),
    wicket_table AS (
        SELECT ball_by_ball.bowler AS player_id, COUNT(*) as wickets
        FROM match, wicket_taken, season, ball_by_ball
        WHERE match.match_id = wicket_taken.match_id
        AND match.season_id = season.season_id
        AND wicket_taken.match_id = match.match_id
        AND wicket_taken.match_id = ball_by_ball.match_id
        AND wicket_taken.over_id = ball_by_ball.over_id
        AND wicket_taken.ball_id = ball_by_ball.ball_id
        AND wicket_taken.innings_no = ball_by_ball.innings_no
        AND ball_by_ball.innings_no IN (1, 2)
        AND wicket_taken.kind_out IN (1, 2, 4, 6, 7, 8)
        GROUP BY player_id
        ORDER BY wickets DESC, player_id
    )
    SELECT wicket_table.player_id, (runs_conceded / wickets) AS ratio
    FROM bowler_table, wicket_table
    WHERE wicket_table.player_id = bowler_table.bowler
    ORDER BY ratio
    LIMIT 3
) AS tbl, player, country
WHERE player.player_id = tbl.player_id
AND player.country_id = country.country_id;

