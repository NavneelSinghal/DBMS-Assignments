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

