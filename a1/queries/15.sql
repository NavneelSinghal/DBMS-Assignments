SELECT season_year, top_batsman, max_runs, top_bowler, max_wickets
FROM (
    SELECT player_name AS top_batsman, season_id, runs AS max_runs
    FROM (
        SELECT player_id AS batsman_id, player_name, season_id, runs, ROW_NUMBER() OVER (PARTITION BY season_id ORDER BY runs DESC, player_name ASC) AS rank
        FROM ( --player_name order
            SELECT ball_by_ball.striker AS player_id, player_name, season.season_id, SUM(batsman_scored.runs_scored) as runs
            FROM match, batsman_scored, season, ball_by_ball, player
            WHERE match.match_id = batsman_scored.match_id
            AND match.season_id = season.season_id
            AND ball_by_ball.match_id = match.match_id
            AND batsman_scored.match_id = ball_by_ball.match_id
            AND batsman_scored.over_id = ball_by_ball.over_id
            AND batsman_scored.ball_id = ball_by_ball.ball_id
            AND batsman_scored.innings_no = ball_by_ball.innings_no
            AND ball_by_ball.innings_no IN (1, 2) -- as per piazza
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
            AND ball_by_ball.innings_no IN (1, 2) -- as per piazza
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
