SELECT team_name, ROUND(AVG(runs), 2) AS avg_runs
FROM (
    SELECT team_name, SUM(batsman_scored.runs_scored) AS runs
    FROM match, ball_by_ball, team, batsman_scored
    WHERE match.season_id = (SELECT season_id FROM season WHERE season.season_year = 2010)
    AND ball_by_ball.innings_no IN (1, 2)
    AND ball_by_ball.match_id = match.match_id
    AND ball_by_ball.team_batting = team.team_id
    AND batsman_scored.match_id = ball_by_ball.match_id
    AND batsman_scored.over_id = ball_by_ball.over_id
    AND batsman_scored.ball_id = ball_by_ball.ball_id
    AND batsman_scored.innings_no = ball_by_ball.innings_no
    GROUP BY team_name, match.match_id
) AS tbl
GROUP BY team_name
ORDER BY team_name;
