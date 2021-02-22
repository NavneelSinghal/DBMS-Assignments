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
    AND ball_by_ball.innings_no IN (1, 2) -- as per piazza
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
    AND ball_by_ball.innings_no IN (1, 2) -- as per piazza
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

