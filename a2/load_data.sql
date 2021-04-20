DROP TABLE IF EXISTS airports;
DROP TABLE IF EXISTS flights;
DROP TABLE IF EXISTS authordetails;
DROP TABLE IF EXISTS paperdetails;
DROP TABLE IF EXISTS authorpaperlist;
DROP TABLE IF EXISTS citationlist;

CREATE TABLE airports (
    airportid integer,
    city text,
    state text,
    name text,
    constraint airports_key primary key (airportid)
);

CREATE TABLE flights (
    flightid integer,
    originairportid integer,
    destairportid integer,
    carrier text,
    dayofmonth integer,
    dayofweek integer,
    departuredelay integer,
    arrivaldelay integer,
    constraint flights_key primary key (flightid)
);

CREATE TABLE authordetails (
    authorid integer,
    authorname text,
    city text,
    gender text,
    age integer,
    constraint authordetails_key primary key (authorid)
);

CREATE TABLE paperdetails (
    paperid integer,
    papername text,
    conferencename text,
    score integer,
    constraint paperdetails_key primary key (paperid)
);

CREATE TABLE authorpaperlist (
    authorid integer,
    paperid integer,
    constraint authorpaperlist_key primary key (authorid, paperid)
);

CREATE TABLE citationlist (
    paperid1 integer,
    paperid2 integer,
    constraint citationlist_key primary key (paperid1, paperid2)
);

\copy airports from 'data/airports.csv' delimiter ',' csv header;
\copy flights from 'data/flights.csv' delimiter ',' csv header;
\copy authordetails from 'data/authordetails.csv' delimiter ',' csv header;
\copy paperdetails from 'data/paperdetails.csv' delimiter ',' csv header;
\copy authorpaperlist from 'data/authorpaperlist.csv' delimiter ',' csv header;
\copy citationlist from 'data/citationlist.csv' delimiter ',' csv header;
