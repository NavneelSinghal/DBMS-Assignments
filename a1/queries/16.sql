SELECT team_name
FROM (
    SELECT team.team_name, COUNT(team.team_name) AS wins
    FROM match, team
    WHERE match.match_winner IS NOT NULL
    AND match.match_winner = team.team_id
    AND match.season_id = (SELECT season_id FROM season WHERE season_year = 2008)
    AND (
        (match.team_1 = team.team_id AND match.team_2 = (SELECT team_id FROM team WHERE team_name = 'Royal Challengers Bangalore'))
        OR
        (match.team_2 = team.team_id AND match.team_1 = (SELECT team_id FROM team WHERE team_name = 'Royal Challengers Bangalore'))
    )
    GROUP BY team.team_name
) AS teams
ORDER BY wins DESC, team_name;
