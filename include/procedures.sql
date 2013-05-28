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