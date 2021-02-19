CREATE TABLE batting_style (
    batting_id bigint NOT NULL,
    batting_hand text,
    constraint batting_style_key primary key (batting_id)
);

CREATE TABLE bowling_style (
    bowling_id bigint NOT NULL,
    bowling_skill text,
    constraint bowling_style_key primary key (bowling_id)
);

CREATE TABLE out_type (
    out_id bigint NOT NULL,
    out_name text,
    constraint out_type_key primary key (out_id)
);

CREATE TABLE outcome (
    outcome_id bigint NOT NULL,
    outcome_type text,
    constraint outcome_key primary key (outcome_id)
);

CREATE TABLE country (
    country_id bigint NOT NULL,
    country_name text,
    constraint country_key primary key (country_id)
);

CREATE TABLE role (
    role_id bigint NOT NULL,
    role_desc text,
    constraint role_key primary key (role_id)
);

CREATE TABLE team (
    team_id bigint NOT NULL,
    team_name text,
    constraint team_key primary key (team_id)
);

CREATE TABLE win_by (
    win_id bigint NOT NULL,
    win_type text,
    constraint win_key primary key (win_id)
);


CREATE TABLE player (
    player_id bigint NOT NULL,
    player_name text,
    dob timestamp with time zone,
    batting_hand bigint,
    bowling_skill bigint,
    country_id bigint,
    constraint player_key primary key (player_id),
    constraint bat_ref foreign key (batting_hand) references batting_style(batting_id),
    constraint bowl_ref foreign key (bowling_skill) references bowling_style(bowling_id),
    constraint country_ref foreign key (country_id) references country(country_id)
);


CREATE TABLE season (
    season_id bigint NOT NULL,
    man_of_the_series bigint,
    orange_cap bigint,
    purple_cap bigint,
    season_year bigint,
    constraint season_key primary key (season_id),
    constraint mos_ref foreign key (man_of_the_series) references player(player_id),
    constraint orange_cap_ref foreign key (orange_cap) references player(player_id),
    constraint purple_cap_ref foreign key (purple_cap) references player(player_id)
);

CREATE TABLE match (
    match_id bigint NOT NULL,
    team_1 bigint,
    team_2 bigint,
    match_date timestamp with time zone,
    season_id bigint,
    win_id bigint,
    win_margin bigint,
    outcome_id bigint,
    match_winner bigint,
    man_of_the_match bigint,
    constraint match_key primary key (match_id),
    constraint team_1_ref foreign key (team_1) references team(team_id),
    constraint team_2_ref foreign key (team_2) references team(team_id),
    constraint season_ref foreign key (season_id) references season(season_id),
    constraint win_ref foreign key (win_id) references win_by(win_id),
    constraint outcome_ref foreign key (outcome_id) references outcome(outcome_id),
    constraint match_winner_ref foreign key (match_winner) references team(team_id),
    constraint man_of_the_match_ref foreign key (man_of_the_match) references player(player_id)
);

CREATE TABLE player_match (
    match_id bigint NOT NULL,
    player_id bigint NOT NULL,
    role_id bigint,
    team_id bigint,
    constraint player_match_key primary key (match_id, player_id),
    constraint role_ref foreign key (role_id) references role(role_id),
    constraint team_ref foreign key (team_id) references team(team_id)
);


CREATE TABLE ball_by_ball (
    match_id bigint NOT NULL,
    over_id bigint NOT NULL,
    ball_id bigint NOT NULL,
    innings_no bigint NOT NULL,
    team_batting bigint,
    team_bowling bigint,
    striker_batting_position bigint,
    striker bigint,
    non_striker bigint,
    bowler bigint,
    constraint ball_key primary key (match_id, over_id, ball_id, innings_no),
    constraint match_ref foreign key (match_id) references match(match_id),
    constraint team_bat_ref foreign key (team_batting) references team(team_id),
    constraint team_ball_ref foreign key (team_bowling) references team(team_id),
    constraint striker_ref foreign key (striker) references player(player_id),
    constraint non_striker_ref foreign key (non_striker) references player(player_id),
    constraint bowler_ref foreign key (bowler) references player(player_id)
);

CREATE TABLE batsman_scored (
    match_id bigint NOT NULL,
    over_id bigint NOT NULL,
    ball_id bigint NOT NULL,
    runs_scored bigint,
    innings_no bigint NOT NULL,
    constraint batsman_scored_key primary key (match_id, over_id, ball_id, innings_no),
    constraint ball_by_ball_ref foreign key (match_id, over_id, ball_id, innings_no) references ball_by_ball(match_id, over_id, ball_id, innings_no)
);

CREATE TABLE wicket_taken (
    match_id bigint NOT NULL,
    over_id bigint NOT NULL,
    ball_id bigint NOT NULL,
    player_out bigint,
    kind_out bigint,
    fielders bigint,
    innings_no bigint NOT NULL,
    constraint wickets_taken_key primary key (match_id, over_id, ball_id, innings_no),
    constraint out_ref foreign key (kind_out) references out_type(out_id),
    constraint player_out_ref foreign key (player_out) references player(player_id),
    constraint fielders_ref foreign key (fielders) references player(player_id),
    constraint ball_by_ball_ref foreign key (match_id, over_id, ball_id, innings_no) references ball_by_ball(match_id, over_id, ball_id, innings_no)
);

\copy batting_style from 'IPL DB/IPL DB/batting_style.csv' delimiter ',' csv header;
\copy bowling_style from 'IPL DB/IPL DB/bowling_style.csv' delimiter ',' csv header;
\copy out_type from 'IPL DB/IPL DB/out_type.csv' delimiter ',' csv header;
\copy outcome from 'IPL DB/IPL DB/outcome.csv' delimiter ',' csv header;
\copy country from 'IPL DB/IPL DB/country.csv' delimiter ',' csv header;
\copy role from 'IPL DB/IPL DB/role.csv' delimiter ',' csv header;
\copy team from 'IPL DB/IPL DB/team.csv' delimiter ',' csv header;
\copy win_by from 'IPL DB/IPL DB/win_by.csv' delimiter ',' csv header;
\copy player from 'IPL DB/IPL DB/player.csv' delimiter ',' csv header;
\copy season from 'IPL DB/IPL DB/season.csv' delimiter ',' csv header;
\copy match from 'IPL DB/IPL DB/match.csv' delimiter ',' csv header;
\copy player_match from 'IPL DB/IPL DB/player_match.csv' delimiter ',' csv header;
\copy ball_by_ball from 'IPL DB/IPL DB/ball_by_ball.csv' delimiter ',' csv header;
\copy batsman_scored from 'IPL DB/IPL DB/batsman_scored.csv' delimiter ',' csv header;
\copy wicket_taken from 'IPL DB/IPL DB/wicket_taken.csv' delimiter ',' csv header;
