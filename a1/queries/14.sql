SELECT season_year, match_id, team_name
FROM (
    SELECT season_year, team_name, match_id, COUNT(player_id), ROW_NUMBER() OVER (PARTITION BY season_year ORDER BY COUNT(player_id) DESC, team_name, match_id) AS rank
    FROM (
        SELECT season.season_id, player_match.team_id, match.match_id, player_match.player_id--, SUM(batsman_scored.runs_scored)
        FROM season, player_match, match, batsman_scored, ball_by_ball
        WHERE match.match_id = player_match.match_id
        AND match.match_winner IS NOT NULL
        AND match.match_winner = player_match.team_id
        AND match.match_id = ball_by_ball.match_id
        AND ball_by_ball.innings_no IN (1, 2)
        AND ball_by_ball.innings_no = batsman_scored.innings_no
        AND ball_by_ball.match_id = batsman_scored.match_id
        AND ball_by_ball.over_id = batsman_scored.over_id
        AND ball_by_ball.ball_id = batsman_scored.ball_id
        AND ball_by_ball.striker = player_match.player_id
        AND season.season_id = match.season_id
        GROUP BY season.season_id, player_match.team_id, match.match_id, player_match.player_id
        HAVING SUM(batsman_scored.runs_scored) >= 50
    ) as tbl, season, team
    WHERE season.season_id = tbl.season_id
    AND team.team_id = tbl.team_id
    GROUP BY season_year, team_name, match_id
) AS tbl
WHERE rank <= 3;
