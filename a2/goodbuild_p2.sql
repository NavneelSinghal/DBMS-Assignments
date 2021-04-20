drop table authordetails;
drop table paperdetails;
drop table authorpaperlist;
drop table citationlist;

create table authordetails (
    authorid integer,
    authorname text,
    city text,
    gender text,
    age integer,
    constraint authordetails_key primary key (authorid)
);

create table paperdetails (
    paperid integer,
    papername text,
    conferencename text,
    score integer,
    constraint paperdetails_key primary key (paperid)
);

create table authorpaperlist (
    authorid integer,
    paperid integer,
    constraint authorpaperlist_key primary key (authorid, paperid)
);

create table citationlist (
    paperid1 integer,
    paperid2 integer,
    constraint citationlist_key primary key (paperid1, paperid2)
);

---------------------------

insert into authordetails values(3552,'A1','C1','male',21);
insert into authordetails values(1745,'A2','C2','male',38);
insert into authordetails values(921,'A3','C3','female',233);
insert into authordetails values(562,'A4','C1','male',36);
insert into authordetails values(456,'A5','C1','male',36);
insert into authordetails values(322,'A6','C1','male',36);
insert into authordetails values(1235,'A7','C1','male',36);
insert into authordetails values(1558,'A8','C1','male',36);
insert into authordetails values(2826,'A9','C1','male',36);

insert into paperdetails values(126,'P1','Co1',20);
insert into paperdetails values(127,'P2','Co1',20);
insert into paperdetails values(128,'P3','Co2',20);
insert into paperdetails values(129,'P4','Co1',20);
insert into paperdetails values(130,'P5','Co1',20);
-- insert into paperdetails values(131,'P6','Co2',20);

insert into authorpaperlist values(3552,126);
insert into authorpaperlist values(3552,130);
insert into authorpaperlist values(1745,126);
insert into authorpaperlist values(1745,127);
insert into authorpaperlist values(921,127);
insert into authorpaperlist values(921,128);
insert into authorpaperlist values(562,128);
insert into authorpaperlist values(562,129);
insert into authorpaperlist values(562,130);
insert into authorpaperlist values(456,129);

insert into citationlist values(126,127);
insert into citationlist values(127,128);
insert into citationlist values(128,129);
insert into citationlist values(127,129);
insert into citationlist values(130,126);
