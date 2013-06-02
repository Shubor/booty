/*
 * INFO2120 / INFO2820
 * Database Systems I
 *
 * Reference Schema for INFO2120/2820 Assignment - Treasure Hunt Database
 * version 1.2
 *
 * PostgreSQL version
 *
 * IMPORTANT!
 * You need to replace 'your_login' with your PostgreSQL user name in line 240
 * of this file (the ALTER USER  command)
 */
-- delete eventually already existing tables
-- ignore the errors if you execute this script the first time
BEGIN TRANSACTION;
   DROP SCHEMA IF EXISTS TreasureHunt CASCADE;
   DROP DOMAIN IF EXISTS RatingDomain;
   DROP DOMAIN IF EXISTS DurationDomain;
   DROP USER IF EXISTS info2120public;
COMMIT;

CREATE SCHEMA TreasureHunt;

/* a user domain can be defined inside the CREATE SCHEMA block as used below */
CREATE DOMAIN TreasureHunt.RatingDomain   AS SMALLINT CHECK ( VALUE BETWEEN 1 AND 5 );
CREATE DOMAIN TreasureHunt.DurationDomain AS INT      CHECK ( VALUE >= 0 );
COMMENT ON DOMAIN TreasureHunt.RatingDomain   IS 'A rating between 1 and 5';
COMMENT ON DOMAIN TreasureHunt.DurationDomain IS 'Duration in full minutes';

/* all tables and views are part of one 'TreasureHunt' schema */

CREATE TABLE TreasureHunt.Hunt (
    id           SERIAL,                      -- surrogate key (INT) with auto-increment
    title        VARCHAR(40) UNIQUE NOT NULL, -- title is a candidate key, hence UNIQUE
    description  TEXT,                        -- this is new here, helpful for GUI
    distance     INT,
    numWayPoints INT,
    startTime    TIMESTAMP,                   -- just DATE would be not precise enough
    status       VARCHAR(20) NOT NULL DEFAULT 'under construction',
    CONSTRAINT Hunt_PK     PRIMARY KEY (id),
    CONSTRAINT Hunt_Status CHECK ( status IN ('under construction','open','active','finished','cancelled') )
);
-- advanced part
CREATE TABLE TreasureHunt.Location (
    name   VARCHAR(40),
    parent VARCHAR(40) NULL,
    type   VARCHAR(10) NOT NULL,
    CONSTRAINT Location_PK        PRIMARY KEY (name),
    CONSTRAINT Location_Parent_FK FOREIGN KEY (parent) REFERENCES TreasureHunt.Location ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT Location_CHK CHECK (type IN ('suburb','area','region','city','state','country'))
);
--
-- WayPoint ISA mapped to 2 distinct tables plus a view on top
--
CREATE TABLE TreasureHunt.PhysicalWayPoint (
    hunt   INT,
    num    SMALLINT,
    name   VARCHAR(40) NOT NULL,
    verification_code   INT,
    clue   TEXT,
    gpsLat FLOAT,
    gpsLon FLOAT,
    isAt   VARCHAR(40),   -- advanced part
    CONSTRAINT PhysicalWayPoint_PK      PRIMARY KEY (hunt, num),
    CONSTRAINT PhysicalWayPoint_Name_UN UNIQUE      (hunt, name),
    CONSTRAINT PhysicalWayPoint_Hunt_FK FOREIGN KEY (hunt) REFERENCES TreasureHunt.Hunt ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT PhysicalWayPoint_Loc_FK  FOREIGN KEY (isAt) REFERENCES TreasureHunt.Location ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE TABLE TreasureHunt.VirtualWayPoint (
    hunt   INT,
    num    SMALLINT,
    name   VARCHAR(40) NOT NULL,
    verification_code   INT,
    clue   TEXT,
    url    VARCHAR(200),
    CONSTRAINT VirtualWayPoint_PK      PRIMARY KEY (hunt, num),
    CONSTRAINT VirtualWayPoint_Name_UN UNIQUE      (hunt, name),
    CONSTRAINT VirtualWayPoint_Hunt_FK FOREIGN KEY (hunt) REFERENCES TreasureHunt.Hunt ON DELETE CASCADE ON UPDATE RESTRICT
);
CREATE VIEW TreasureHunt.WayPoint AS
    SELECT hunt, num, name, verification_code, clue, 'LOC'
      FROM TreasureHunt.PhysicalWayPoint
     UNION
    SELECT hunt, num, name, verification_code, clue, 'WWW'
      FROM TreasureHunt.VirtualWayPoint;
--
-- example for an assertion to ensure that each hunt has at least two waypoints
-- and at the same time also checking that num_way_points matches the atual number of WPs
-- CREATE ASSERTION HuntsMinTwoWaypoints CHECK (
--   NOT EXISTS ( SELECT hunt
--                  FROM WayPoint JOIN Hunt ON (hunt=id)
--                 GROUP BY hunt
--                HAVING COUNT(num) < 2 OR COUNT(num) != numWayPoints )
-- )
--
CREATE TABLE TreasureHunt.Player (
   name     VARCHAR(40),
   password VARCHAR(20) NOT NULL,
   pw_salt  VARCHAR(10) NOT NULL,
   gender   CHAR,
   addr     VARCHAR(100),
   active BOOLEAN NOT NULL DEFAULT TRUE,
   CONSTRAINT Player_PK     PRIMARY KEY (name),
   CONSTRAINT Player_Gender CHECK ( gender IN ('m','f','o') )
);
CREATE TABLE TreasureHunt.PlayerStats (
   player     VARCHAR(40),
   stat_name  VARCHAR(20),
   stat_value VARCHAR(20) NOT NULL,
   CONSTRAINT PlayerStats_PK PRIMARY KEY (player, stat_name),
   CONSTRAINT PlayerStats_FK FOREIGN KEY (player) REFERENCES TreasureHunt.Player
);
CREATE TABLE TreasureHunt.Team (
    name    VARCHAR(40),
    created DATE NOT NULL DEFAULT CURRENT_DATE,
  till DATE,
  active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT Team_PK PRIMARY KEY (name)
);
CREATE TABLE TreasureHunt.MemberOf (
    player VARCHAR(40),
    team   VARCHAR(40),
    since  DATE NOT NULL DEFAULT CURRENT_DATE,
    till DATE DEFAULT NULL,
    current BOOLEAN NOT NULL DEFAULT TRUE, -- ADDED: identifies current team of a player
    CONSTRAINT TeamMembers_PK        PRIMARY KEY (team,player),
    CONSTRAINT TeamMembers_Player_FK FOREIGN KEY (player) REFERENCES TreasureHunt.Player,
    CONSTRAINT TeamMembers_Team_FK   FOREIGN KEY (team)   REFERENCES TreasureHunt.Team ON DELETE CASCADE ON UPDATE CASCADE
);
--
-- Example for an assertion to ensure that each team has 2-3 members:
-- CREATE ASSERTION TeamSizeBetween2and3 CHECK (
--   NOT EXISTS ( SELECT team
--                  FROM MemberOf
--                 GROUP BY team
--                HAVING COUNT(player) < 2 OR COUNT(player) > 3 )
-- )
-- Another, perhaps more elegant option is to check for this at the point in time
-- when a team tries to enrol for a hunt using a trigger...
-- For the latter approach, see the two triggers at the end of this file
--
CREATE TABLE TreasureHunt.Participates (
    team      VARCHAR(40),
    hunt      INT,
    currentWP SMALLINT NULL, -- ADDED: identifies current waypoint of team during active hunt
                             --        doubles as a flag for a team's current hunt, as otherwise it is NULL
    score     INT NULL,      -- progressively increases during a hunt
    rank      INT NULL,
    duration TreasureHunt.DurationDomain NULL, -- in minutes
    CONSTRAINT Participates_PK PRIMARY KEY (team,hunt),
    CONSTRAINT Participates_Hunt_FK FOREIGN KEY (hunt) REFERENCES TreasureHunt.Hunt ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Participates_Team_FK FOREIGN KEY (team) REFERENCES TreasureHunt.Team ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Participates_Rank    CHECK ( rank > 0 ),
    CONSTRAINT Participates_Score   CHECK ( score >= 0 )
);
-- Example for an assertion to ensure that teams participate in at most one active hunt
-- CREATE ASSERTION TeamsMaxOneActiveHunt CHECK (
--   NOT EXISTS ( SELECT team
--                  FROM Participates JOIN Hunt ON (hunt=id)
--                 WHERE status = 'active'
--                 GROUP BY team
--                HAVING COUNT(hunt) > 1 )
-- )
CREATE TABLE TreasureHunt.Visit (
    team           VARCHAR(40),
    num            SMALLINT,
    submitted_code INT       NOT NULL,
    time           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_correct     BOOLEAN   NOT NULL,
    visited_hunt   INT       NULL,
    visited_wp     SMALLINT  NULL,
    CONSTRAINT Visit_PK PRIMARY KEY (team,num),
    CONSTRAINT Visit_Team_FK     FOREIGN KEY (team) REFERENCES TreasureHunt.Team ON DELETE CASCADE ON UPDATE CASCADE
-- one big disadvantage of having WayPoints as a view is that we cannot use foreign key here...
--    CONSTRAINT Visit_WayPoint_FK FOREIGN KEY (visited_hunt,visited_wp) REFERENCES WayPoint ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE TABLE TreasureHunt.Badge (
    name        VARCHAR(40),
    description TEXT          NOT NULL,
    condition   VARCHAR(200)  NOT NULL,
    CONSTRAINT Badge_PK PRIMARY KEY (name)
);
CREATE TABLE TreasureHunt.Achievements (
    player  VARCHAR(40),
    badge   VARCHAR(40),
    whenReceived DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT Wins_PK        PRIMARY KEY (player, badge),
    CONSTRAINT Wins_Player_FK FOREIGN KEY (player) REFERENCES TreasureHunt.Player ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Wins_Badge_FK  FOREIGN KEY (badge)  REFERENCES TreasureHunt.Badge  ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE TreasureHunt.Review (
    id          SERIAL,       -- surrogate ID (INT) with auto-increment
    hunt        INT           NOT NULL,
    player      VARCHAR(40)   NOT NULL,
    whenDone    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rating      TreasureHunt.RatingDomain  NOT NULL,
    description TEXT          NULL,
    CONSTRAINT Review_PK PRIMARY KEY (id),
    CONSTRAINT Review_CK UNIQUE (hunt,player),
    CONSTRAINT Review_Hunt_FK   FOREIGN KEY (hunt)   REFERENCES TreasureHunt.Hunt ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Review_Player_FK FOREIGN KEY (player) REFERENCES TreasureHunt.Player ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE TreasureHunt.Likes (
    review     INT,
    player     VARCHAR(40),
    whenDone   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usefulness TreasureHunt.RatingDomain,
    CONSTRAINT Likes_PK PRIMARY KEY (review,player),
    CONSTRAINT Likes_Review_FK FOREIGN KEY (review) REFERENCES TreasureHunt.Review ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT Likes_Player_FK FOREIGN KEY (player) REFERENCES TreasureHunt.Player ON DELETE CASCADE ON UPDATE CASCADE
);


/* some utility functions for the CHECK clause of the following triggers */
CREATE OR REPLACE FUNCTION TreasureHunt.getTeamSize( team VARCHAR ) RETURNS BIGINT AS
       'SELECT COUNT(*) FROM TreasureHunt.MemberOf WHERE team = $1'
       LANGUAGE sql;

/* generic trigger function that just stops the execution of the current statement      */
/* note that this gives a silent stop without error message; result is '0 row affected' */
/* if you want an explicit error message, include a  RAISE EXCEPTION 'error msg'        */
CREATE OR REPLACE FUNCTION TreasureHunt.Noop() RETURNS trigger AS
$body$
BEGIN
   RETURN NULL; -- a return value of NULL silently stops the current statement
END
$body$ LANGUAGE plpgsql;

/* trigger to ensure that a team can have a maximum of 3 members */
DROP TRIGGER IF EXISTS TeamMaxThreeMembers_Trigger ON TreasureHunt.MemberOf;
CREATE TRIGGER TeamMaxThreeMembers_Trigger
       BEFORE UPDATE OR INSERT ON TreasureHunt.MemberOf
       FOR EACH ROW
       WHEN ( TreasureHunt.getTeamSize(NEW.team) = 3 )
       EXECUTE PROCEDURE TreasureHunt.Noop();

/* trigger to ensure that a team must have at least 2 member when signing up to a hunt */
DROP TRIGGER IF EXISTS TeamMin2Members_Trigger ON TreasureHunt.Participates;
CREATE TRIGGER TeamMin2Members_Trigger
       BEFORE UPDATE OR INSERT ON TreasureHunt.Participates
       FOR EACH ROW
       WHEN ( TreasureHunt.getTeamSize(NEW.team) < 2 )
       EXECUTE PROCEDURE TreasureHunt.Noop();


/*public user definition here*/
CREATE USER info2120public WITH PASSWORD '123456789';
ALTER USER info2120public SET search_path TO 'TreasureHunt';
GRANT USAGE ON SCHEMA TreasureHunt TO info2120public;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA TreasureHunt TO info2120public;



/* dummy system, remove for final
INSERT INTO treasurehunt.player VALUES ('Greg', 'abc123', 'abc123', 'm', 'Sydney');
INSERT INTO treasurehunt.player VALUES ('Charlotte', 'swordfish', 'swordfish', 'f', 'New York');
INSERT INTO treasurehunt.player VALUES ('Table', 'chair', 'chair', 'o', 'Alice Springs');*/


/* IMPORTANT TODO: */
/* please replace 'your_login' with the name of your PostgreSQL login */
/* in the following ALTER USER username SET search_path ... command   */
/* this ensures that the carsharing schema is automatically used when you query one of its tables */
ALTER USER postgres SET search_Path = TreasureHunt, '$user', public, unidb;