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