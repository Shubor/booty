BEGIN TRANSACTION;
  DROP FUNCTION IF EXISTS TreasureHunt.dashboardName(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.huntCount(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.getBadges(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.getHuntStatus(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.getUserStatistics(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.getAvailableHunts();
  DROP FUNCTION IF EXISTS TreasureHunt.getHuntDetails(integer);
  DROP FUNCTION IF EXISTS TreasureHunt.getParticipateCount(integer);
  DROP FUNCTION IF EXISTS TreasureHunt.checkLogin(varchar, varchar);
COMMIT;

CREATE OR REPLACE FUNCTION treasureHunt.dashboardName(varchar)
RETURNS TABLE(name varchar, addr varchar, curr varchar) AS $body$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT P.name as name, P.addr as addr, M.team as curr
  FROM treasurehunt.Player P
  LEFT OUTER JOIN treasurehunt.memberOf M ON (P.name = M.player)
  WHERE P.name = playerName;
END;
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION treasureHunt.huntCount(varchar)
RETURNS TABLE(stat varchar) AS $body$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT PS.stat_value as stat
  FROM treasurehunt.playerStats PS
  WHERE PS.player = playerName AND PS.stat_name = 'finished_hunts';
END;
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION treasureHunt.getBadges(varchar)
RETURNS TABLE(name varchar, descrip text) AS $body$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT A.badge as name, B.description as descrip
  FROM treasurehunt.achievements A
  INNER JOIN treasurehunt.badge B ON (A.badge = B.name)
  WHERE A.player = playerName;
END;
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION treasureHunt.getHuntStatus(varchar)
RETURNS TABLE(status varchar, name varchar, team varchar,
              start_time timestamp without time zone, elapsed text,
              score integer, waypoint_count smallint, clue text) AS $body$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT H.status AS status, H.title AS name,
      M.team AS team, H.startTime as start_time,
      (extract (epoch from (now() - starttime))/3600)::integer
      || ' hours and ' || (extract (epoch from (now() - starttime))/60)::integer%60
      || ' minute(s)' as elapsed,
      P.score as score, P.currentWP as waypoint_count, W.clue as clue
    FROM TreasureHunt.Hunt H
      RIGHT OUTER JOIN TreasureHunt.Participates P ON (H.id=P.hunt)
      RIGHT OUTER JOIN TreasureHunt.MemberOf M ON (M.team=P.team)
      RIGHT OUTER JOIN TreasureHunt.Waypoint W ON (H.id=W.hunt)
    WHERE M.player=playerName AND M.current='true' AND P.currentWP=W.num;
END;
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION treasureHunt.getUserStatistics(varchar)
RETURNS TABLE(stat_name varchar, stat_value varchar) AS $BODY$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT PS.stat_name, PS.stat_value
  FROM treasurehunt.playerStats PS
  WHERE PS.player = playerName
  ORDER BY stat_name ASC;
END;
$BODY$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION treasureHunt.getAvailableHunts()
RETURNS TABLE(identi integer, name varchar, start timestamp without time zone, distance integer, nwaypoints integer)
AS $body$
BEGIN
  RETURN QUERY SELECT H.id as identi, H.title AS name, H.startTime as start, H.distance, H.numWayPoints AS nwaypoints
  FROM TreasureHunt.Hunt H
  WHERE status = 'open'
  ORDER BY H.title ASC;
END;
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION treasureHunt.getHuntDetails(integer)
RETURNS TABLE(identi integer, name varchar, descrip text, distance integer, start timestamp without time zone, n_wp integer) AS
$body$
DECLARE
  huntId ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT H.id as identi, H.title AS name, H.description AS descrip, H.distance, H.startTime AS start, H.numWayPoints AS n_wp
  FROM TreasureHunt.Hunt H
  WHERE id = huntId;
END;
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION treasureHunt.getParticipateCount(integer)
RETURNS TABLE(nteams bigint) AS
$body$
DECLARE
  huntId ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT count(*) AS nteams
  FROM TreasureHunt.Participates
  WHERE hunt = huntId;
END;
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION checkLogin(varchar, varchar)
RETURNS TABLE(name varchar) AS
$body$
DECLARE
  playerName ALIAS FOR $1;
  passwd ALIAS FOR $2;
BEGIN
  RETURN QUERY SELECT playerName
  FROM treasurehunt.Player AS p
  WHERE p.name = playerName AND p.password = passwd LIMIT 1;
END;
$body$ LANGUAGE plpgsql;