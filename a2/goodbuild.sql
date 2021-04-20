drop table flights;
drop table airports;

create table airports (
    airportid integer,
    city text,
    state text,
    name text,
    constraint airports_key primary key (airportid)
);

create table flights (
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

insert into airports values(10140, 'Albuquerque', 'New Mexico', 'Albuquerque International Airport');
insert into airports values(10141, 'Chicago', 'Illinois', 'Chicago International Airport');
insert into airports values(10142, 'Dallas', 'Mexico', 'Dallas International Airport');
insert into airports values(10143, 'Georgia', 'USA', 'Georgia International Airport');
insert into airports values(10144, 'Phoenix', 'Arizona', 'Phoenix International Airport');
insert into airports values(10145, 'Texas', 'New Mexico', 'Texas International Airport');
insert into airports values(10146, 'Houston', 'New Mexico', 'Houston International Airport');
insert into airports values(10147, 'LasVegas', 'Nevada', 'Las Vegas International Airport');
insert into airports values(10148, 'Washington', 'USA', 'Washington International Airport');
insert into airports values(10149, 'Boston', 'New York', 'Boston International Airport');
insert into airports values(10150, 'Amsterdam', 'New York', 'Amsterdam International Airport');
insert into airports values(10151, 'Geneva', 'New York', 'Geneva International Airport');
insert into airports values(10152, 'Denver', 'USA', 'Denver International Airport');
insert into airports values(10153, 'LA', 'USA', 'LA International Airport');

---------------------------

insert into flights values(1, 10140, 10141, 'AA', 1, NULL, 1, 2);
insert into flights values(2, 10141, 10142, 'AA', 2, NULL, 2, 4);
insert into flights values(3, 10142, 10143, 'AA', 3, NULL, 3, 7);
insert into flights values(4, 10143, 10140, 'AA', 4, NULL, 4, 9);
insert into flights values(5, 10140, 10144, 'AA', 1, NULL, 5, 10);
insert into flights values(6, 10144, 10145, 'AA', 6, NULL, 6, 15);
insert into flights values(7, 10145, 10146, 'AA', 7, NULL, 7, 13);
insert into flights values(8, 10146, 10147, 'AA', 8, NULL, 8, 23);
insert into flights values(9, 10147, 10148, 'AA', 9, NULL, 9, 4);
insert into flights values(10, 10148, 10140, 'AA', 10, NULL, 10, 2);
insert into flights values(11, 10143, 10144, 'AA', 11, NULL, 11, 6);
insert into flights values(12, 10143, 10146, 'AA', 12, NULL, 12, 8);
insert into flights values(13, 10142, 10141, 'AA', 13, NULL, 13, 9);
insert into flights values(14, 10148, 10142, 'AA', 14, NULL, 14, 10);
insert into flights values(15, 10143, 10142, 'AA', 15, NULL, 15, 7);
insert into flights values(16, 10148, 10143, 'AA', 16, NULL, 16, 1);
insert into flights values(17, 10140, 10141, 'BB', 2, NULL, -16, 1);

insert into flights values(18, 10149, 10150, 'BB', 2, NULL, -16, 1);
insert into flights values(19, 10150, 10151, 'BB', 2, NULL, -16, 1);
insert into flights values(20, 10151, 10149, 'BB', 2, NULL, -16, 1);
insert into flights values(21, 10150, 10151, 'BB', 3, NULL, -16, 1);
insert into flights values(22, 10149, 10151, 'BB', 4, NULL, -16, 1);
insert into flights values(23, 10150, 10149, 'BB', 4, NULL, -16, 1);

