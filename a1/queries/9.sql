SELECT team1.team_name, team2.team_name AS opponent_team_name, COUNT(batsman_scored.runs_scored) AS number_of_sixes
FROM season, match, ball_by_ball, batsman_scored, team AS team1, team AS team2
WHERE season.season_id = match.season_id
AND season.season_year = 2008
AND match.match_id = batsman_scored.match_id
AND ball_by_ball.match_id = match.match_id
AND ball_by_ball.over_id = batsman_scored.over_id
AND ball_by_ball.innings_no IN (1, 2) -- as per piazza
AND ball_by_ball.innings_no = batsman_scored.innings_no
AND ball_by_ball.ball_id = batsman_scored.ball_id
AND batsman_scored.runs_scored = 6
AND team1.team_id = ball_by_ball.team_batting
AND team2.team_id = ball_by_ball.team_bowling
GROUP BY match.match_id, ball_by_ball.innings_no, ball_by_ball.team_batting, team1.team_name, team2.team_name
ORDER BY number_of_sixes DESC, team1.team_name
LIMIT 3;

