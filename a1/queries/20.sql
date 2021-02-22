SELECT player_name
FROM player, wicket_taken
WHERE player.player_id = wicket_taken.player_out
AND wicket_taken.innings_no IN (1, 2)
AND wicket_taken.over_id = 1
GROUP BY player_name
ORDER BY COUNT(player_name) DESC, player_name
LIMIT 10;
