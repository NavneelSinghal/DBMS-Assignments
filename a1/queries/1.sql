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

