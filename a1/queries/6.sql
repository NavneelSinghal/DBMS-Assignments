SELECT *
FROM (
    SELECT season_year, team_name, ROW_NUMBER() OVER (PARTITION BY season_year) AS rank
    FROM (
        SELECT season_year, team_name, COUNT(player_id) AS lh
        FROM (
            SELECT DISTINCT season.season_year, player_match.team_id, player_match.player_id
            FROM player, season, player_match, match
            WHERE season.season_id = match.season_id
            AND match.match_id = player_match.match_id
            AND player_match.player_id = player.player_id
            AND player.batting_hand = 1
            AND player.country_id > 1
        ) AS tbl, team
        WHERE team.team_id = tbl.team_id
        GROUP BY season_year, team_name
        ORDER BY season_year, lh DESC, team_name
    ) AS tbl
) AS tbl
WHERE rank <= 5
ORDER BY season_year ASC;

