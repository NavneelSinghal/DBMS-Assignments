SELECT match.match_id, team1.team_name AS team_1_name, team2.team_name AS team_2_name, team3.team_name AS match_winner_name, COUNT(batsman_scored.runs_scored) AS number_of_boundaries
FROM match, ball_by_ball, team AS team1, team AS team2, team AS team3, batsman_scored
WHERE match.match_id = ball_by_ball.match_id
AND match.match_winner = ball_by_ball.team_batting
AND batsman_scored.innings_no = 2
AND team1.team_id = match.team_1
AND team2.team_id = match.team_2
AND team3.team_id = match.match_winner
AND match.match_winner IS NOT NULL
AND batsman_scored.runs_scored IN (4, 6)
AND batsman_scored.match_id = ball_by_ball.match_id
AND batsman_scored.over_id = ball_by_ball.over_id
AND batsman_scored.ball_id = ball_by_ball.ball_id
AND batsman_scored.innings_no = ball_by_ball.innings_no
GROUP BY match.match_id, team1.team_name, team2.team_name, team3.team_name
ORDER BY number_of_boundaries, match_winner_name, team_1_name, team_2_name
LIMIT 3;
