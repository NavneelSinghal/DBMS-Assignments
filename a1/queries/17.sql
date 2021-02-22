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
