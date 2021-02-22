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
    AND ball_by_ball.innings_no IN (1, 2) -- as per piazza
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
    AND ball_by_ball.innings_no IN (1, 2) -- as per piazza
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

