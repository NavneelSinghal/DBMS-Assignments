SELECT player_name
FROM player, (
    SELECT fielders, COUNT(fielders) AS catches
    FROM wicket_taken, match, season
    WHERE match.match_id = wicket_taken.match_id
    AND wicket_taken.kind_out = 1
    AND match.season_id = season.season_id
    AND season.season_year = 2012
    GROUP BY fielders
) AS fldr
WHERE fielders = player.player_id
ORDER by catches DESC, player_name ASC
LIMIT 1;

