--SELECT player_name, season_year FROM (
--SELECT player.player_name, season.season_year, COUNT(batsman_scored.runs_scored), ROW_NUMBER() OVER (PARTITION BY season_year ORDER BY COUNT(batsman_scored.runs_scored) DESC, player_name) as rank
--FROM ball_by_ball, batsman_scored, match, player, season
--WHERE batsman_scored.runs_scored = 6
--AND batsman_scored.match_id = ball_by_ball.match_id
--AND batsman_scored.over_id = ball_by_ball.over_id
--AND batsman_scored.ball_id = ball_by_ball.ball_id
--AND batsman_scored.innings_no = ball_by_ball.innings_no
--AND match.match_id = ball_by_ball.match_id
--AND player.player_id = ball_by_ball.striker
--AND season.season_id = match.season_id
--GROUP BY player.player_name, season.season_year
--) AS tbl
--WHERE rank <= 3;

--WITH bowler_table AS (
--    SELECT ball_by_ball.bowler, SUM(batsman_scored.runs_scored) AS runs_conceded
--    FROM ball_by_ball, batsman_scored
--    WHERE ball_by_ball.innings_no IN (1, 2)
--    AND ball_by_ball.match_id = batsman_scored.match_id
--    AND ball_by_ball.over_id = batsman_scored.over_id
--    AND ball_by_ball.ball_id = batsman_scored.ball_id
--    AND ball_by_ball.innings_no = batsman_scored.innings_no
--    GROUP BY ball_by_ball.bowler
--),
--wicket_table AS (
--    SELECT ball_by_ball.bowler AS player_id, COUNT(*) as wickets
--    FROM match, wicket_taken, season, ball_by_ball
--    WHERE match.match_id = wicket_taken.match_id
--    AND match.season_id = season.season_id
--    AND wicket_taken.match_id = match.match_id
--    AND wicket_taken.match_id = ball_by_ball.match_id
--    AND wicket_taken.over_id = ball_by_ball.over_id
--    AND wicket_taken.ball_id = ball_by_ball.ball_id
--    AND wicket_taken.innings_no = ball_by_ball.innings_no
--    AND ball_by_ball.innings_no IN (1, 2)
--    AND wicket_taken.kind_out IN (1, 2, 4, 6, 7, 8)
--    GROUP BY player_id
--    ORDER BY wickets DESC, player_id
--)
--SELECT country_name, player_name, wickets as num_wickets, runs_conceded
--FROM bowler_table, wicket_table, country, player
--WHERE wicket_table.player_id = bowler_table.bowler
--AND player.player_id = wicket_table.player_id
--AND player.country_id = country.country_id
--ORDER BY wickets DESC, runs_conceded ASC, player_name ASC
--LIMIT 1;

SELECT player.player_name, batting_sum, wickets from (
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
    GROUP BY ball_by_ball.striker
),
average_runs AS (
    SELECT ROUND(AVG(batting_sum), 2) AS average_runs
    FROM total_run_table
)

SELECT player_id, wickets, batting_sum, average_runs.average_runs, average_wickets.average_wickets FROM (
SELECT total_run_table.player_id, COALESCE(wicket_table.wickets, 0) as wickets, total_run_table.batting_sum, average_wickets.average_wickets, average_runs.average_runs
FROM (total_run_table left outer join wicket_table
on total_run_table.player_id = wicket_table.player_id), average_wickets, average_runs
) as tbl1
UNION
SELECT player_id, wickets, batting_sum, average_runs.average_runs, average_wickets.average_wickets FROM (
SELECT wicket_table.player_id, wicket_table.wickets, COALESCE(total_run_table.batting_sum, 0) as batting_sum, average_wickets, average_runs
FROM (wicket_table left outer join total_run_table 
on total_run_table.player_id = wicket_table.player_id), average_runs, average_wickets
) as tbl2
) as tbl, player
WHERE player.player_id = tbl.player_id;

--
--SELECT * from (
--WITH wicket_table AS (
--    SELECT ball_by_ball.bowler AS player_id, COUNT(*) as wickets
--    FROM match, wicket_taken, season, ball_by_ball
--    WHERE match.match_id = wicket_taken.match_id
--    AND match.season_id = season.season_id
--    AND wicket_taken.match_id = match.match_id
--    AND wicket_taken.match_id = ball_by_ball.match_id
--    AND wicket_taken.over_id = ball_by_ball.over_id
--    AND wicket_taken.ball_id = ball_by_ball.ball_id
--    AND wicket_taken.innings_no = ball_by_ball.innings_no
--    AND ball_by_ball.innings_no IN (1, 2)
--    AND wicket_taken.kind_out IN (1, 2, 4, 6, 7, 8)
--    GROUP BY player_id
--    ORDER BY wickets DESC, player_id
--),
--average_wickets AS (
--    SELECT ROUND(AVG(wickets), 2) AS average_wickets
--    FROM wicket_table
--),
--total_run_table AS (
--    SELECT ball_by_ball.striker AS player_id, SUM(batsman_scored.runs_scored) as batting_sum
--    FROM match, batsman_scored, season, ball_by_ball, wicket_table, average_wickets
--    WHERE match.match_id = batsman_scored.match_id
--    AND match.season_id = season.season_id
--    AND ball_by_ball.match_id = match.match_id
--    AND batsman_scored.match_id = ball_by_ball.match_id
--    AND batsman_scored.over_id = ball_by_ball.over_id
--    AND batsman_scored.ball_id = ball_by_ball.ball_id
--    AND batsman_scored.innings_no = ball_by_ball.innings_no
--    AND ball_by_ball.innings_no IN (1, 2)
--    AND wicket_table.player_id = ball_by_ball.striker
--    GROUP BY ball_by_ball.striker
--),
--average_runs AS (
--    SELECT ROUND(AVG(batting_sum), 2) AS average_runs
--    FROM total_run_table
--)
--
--SELECT * FROM (
--SELECT total_run_table.player_id, COALESCE(wicket_table.wickets, 0) as wickets, total_run_table.batting_sum
--FROM total_run_table left outer join wicket_table
--on total_run_table.player_id = wicket_table.player_id
--) as tbl1
--UNION
--SELECT * FROM (
--SELECT wicket_table.player_id, wicket_table.wickets, COALESCE(total_run_table.batting_sum, 0)
--FROM wicket_table left outer join total_run_table 
--on total_run_table.player_id = wicket_table.player_id
--) as tbl2
--) as tbl, player
--WHERE player.player_id = tbl.player_id;

--player, total_run_table, wicket_table
--WHERE player.country_id = 1
--AND ((player.player_id = total_run_table.player_id AND total_run_table.runs > average_runs.average_runs) OR )
--
--
--
--(player.player_id = wicket_table.player_id AND wicket_table.wickets > average_wickets.average_wickets)
