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
            -- WHERE ball_by_ball.innings_no IN (1, 2) -- as per piazza
            WHERE ball_by_ball.match_id = batsman_scored.match_id
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
