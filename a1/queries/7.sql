SELECT team_name
FROM (
    SELECT team.team_name, COUNT(team.team_name) as wins
    FROM season, match, team
    WHERE season.season_id = match.season_id
    AND season.season_year = 2009
    AND match.match_winner IS NOT NULL
    AND match.match_winner = team.team_id
    GROUP BY team_id
    ORDER BY wins DESC, team.team_name ASC
) as tbl;

