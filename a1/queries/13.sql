SELECT player_name
FROM (
    SELECT *
    FROM (
        SELECT player_id, ROW_NUMBER() OVER (PARTITION BY player_id) as row_num
        FROM (
            SELECT DISTINCT player.player_id, season.season_id
            FROM player, season, player_match, match
            WHERE player.player_id = player_match.player_id
            AND match.match_id = player_match.match_id
            AND match.season_id = season.season_id
        ) AS tbl
    ) AS tbl
    WHERE row_num >= (
        SELECT COUNT(*) FROM season
    )
) as tbl, player
WHERE player.player_id = tbl.player_id
ORDER BY player_name;
