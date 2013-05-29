CREATE OR REPLACE FUNCTION treasurehunt.dashboardName(varchar)
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

CREATE OR REPLACE FUNCTION treasurehunt.huntCount(varchar)
RETURNS TABLE(stat varchar) AS $body$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT PS.stat_value as stat
  FROM treasurehunt.playerStats PS 
  WHERE PS.player = playerName AND PS.stat_name = 'finished_hunts';
END;
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION treasurehunt.getBadges(varchar)
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

CREATE OR REPLACE FUNCTION treasurehunt.getHuntStatus(varchar)
RETURNS TABLE(status varchar, name varchar, team varchar, 
              start_time timestamp without time zone, elapsed text, 
              score integer, waypoint_count smallint, clue text) AS $body$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT H.status AS status, H.title AS name,
      M.team AS team, H.startTime as start_time,
      (extract (epoch from (now() - starttime))/60)::integer 
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