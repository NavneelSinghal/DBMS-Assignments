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
        AND ball_by_ball.innings_no IN (1, 2) -- as per piazza
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

