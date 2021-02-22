SELECT country_name
FROM (
    WITH bowler_table AS (
        SELECT ball_by_ball.bowler, SUM(batsman_scored.runs_scored) AS runs_conceded
        FROM ball_by_ball, batsman_scored
        WHERE ball_by_ball.innings_no IN (1, 2) -- as per piazza
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
        AND ball_by_ball.innings_no IN (1, 2) -- as per piazza
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

