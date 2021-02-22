SELECT team_name, player_name, runs FROM (
    SELECT * 
    FROM (
        SELECT player_name, team_batting, runs, ROW_NUMBER() OVER (PARTITION BY team_batting ORDER BY runs DESC) AS rank
        FROM (
            SELECT player.player_name, ball_by_ball.team_batting, SUM(batsman_scored.runs_scored) AS runs
            FROM season, match, batsman_scored, ball_by_ball, player
            WHERE season.season_id = match.season_id
            AND season.season_year = 2010
            AND match.match_id = ball_by_ball.match_id
            AND match.match_id = batsman_scored.match_id
            AND ball_by_ball.innings_no = batsman_scored.innings_no
            AND ball_by_ball.innings_no IN (1, 2) -- as per piazza
            AND ball_by_ball.over_id = batsman_scored.over_id
            AND ball_by_ball.ball_id = batsman_scored.ball_id
            AND player.player_id = ball_by_ball.striker
            GROUP BY player.player_name, ball_by_ball.team_batting
            ORDER BY runs DESC, player_name ASC, team_batting ASC
        ) as tbl
    ) as tbl
    WHERE rank <= 1
) as tbl, team
WHERE team.team_id = team_batting
ORDER BY team_name, player_name;

