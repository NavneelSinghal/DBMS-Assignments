SELECT match.match_id, player.player_name, team.team_name, COUNT(*) AS num_wickets, season.season_year
FROM match, player_match, ball_by_ball, team, season, player, wicket_taken
WHERE match.match_id = player_match.match_id
AND ball_by_ball.match_id = match.match_id
AND wicket_taken.match_id = ball_by_ball.match_id
AND wicket_taken.kind_out IN (1, 2, 4, 6, 7, 8)
AND player.player_id = player_match.player_id
AND ball_by_ball.bowler = player.player_id
AND team.team_id = ball_by_ball.team_bowling
AND player_match.team_id = team.team_id
AND wicket_taken.over_id = ball_by_ball.over_id
AND wicket_taken.ball_id = ball_by_ball.ball_id
AND wicket_taken.innings_no = ball_by_ball.innings_no
AND ball_by_ball.innings_no IN (1, 2) -- as per piazza
AND match.season_id = season.season_id
GROUP BY match.match_id, player.player_id, player.player_name, team.team_name, season_year
ORDER BY num_wickets DESC, player.player_name, match.match_id
LIMIT 1;
