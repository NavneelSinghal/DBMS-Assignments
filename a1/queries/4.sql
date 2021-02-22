SELECT season_year, player_name, num_matches
FROM player, (
    SELECT player_id, season_year, COUNT(player_id) AS num_matches
    FROM season, player_match, match
    WHERE season.season_id = match.season_id
    AND match.match_id = player_match.match_id
    AND player_match.player_id = season.purple_cap
    GROUP BY player_id, season_year
) AS tbl
WHERE player.player_id = tbl.player_id
ORDER BY season_year;

