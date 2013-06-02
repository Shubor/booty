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
  DROP FUNCTION IF EXISTS TreasureHunt.updateScore(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.updateFinishedHunts(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.updateRank(integer, varchar, varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.getData(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.getUserFratFrequency(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.getUserFratRecency(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.getUserFratAmount(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.getUserFratType(varchar);
  DROP FUNCTION IF EXISTS TreasureHunt.upVerify(integer, varchar, varchar, integer, integer, timestamp without time zone);
  DROP FUNCTION IF EXISTS TreasureHunt.getCompletedHunts(varchar);
COMMIT;


CREATE OR REPLACE FUNCTION
TreasureHunt.upVerify(codeArg integer, playerNameArg varchar, teamidArg varchar, huntidArg integer,
         currentwpArg integer, starttimeArg timestamp without time zone)
RETURNS TABLE(status varchar, name varchar, team varchar,
              start_time timestamp without time zone, elapsed text,
              score integer, waypoint_count smallint, clue text, rank integer) AS
$body$
DECLARE
  vercodVar integer;
  scoreVar integer;
  numwaypointsVar smallint;
  rankVar integer;
  finishedHuntsVar integer;
  cluetextVar text;
  statusVar varchar;
  countVar integer;
  elapsedVar timestamp without time zone;

BEGIN
  vercodVar := (SELECT W.verification_code
                FROM TreasureHunt.Waypoint W
                WHERE hunt = huntidArg AND num = currentwpArg);

  IF vercodVar = codeArg THEN

    scoreVar := (SELECT TreasureHunt.updateScore(playerNameArg));
    numwaypointsVar := (SELECT H.numwaypoints
                        FROM Treasurehunt.hunt H
                        WHERE id = huntidArg);

    IF currentwpArg::integer = numwaypointsVar::integer THEN
      statusVar := 'complete';
      UPDATE TreasureHunt.Participates P
      SET currentwp = NULL, score = (P.score + 1),
          duration = (extract (epoch from NOW() - starttimeArg)/60)::integer -- duration set in minutes
      WHERE P.hunt = huntidArg AND P.team = teamidArg;

      finishedHuntsVar := (SELECT updateFinishedHunts(playerNameArg));
      rankVar := (SELECT updateRank(huntidArg, playerNameArg, teamidArg));

    ELSE
      statusVar := 'correct';

      UPDATE TreasureHunt.Participates P
      SET currentwp = (P.currentwp + 1), score = (P.score + 1)
      WHERE P.hunt = huntidArg AND P.team = teamidArg;

      cluetextVar := (SELECT W.clue FROM TreasureHunt.Waypoint W
                   WHERE W.hunt = huntidArg AND W.num = currentwpArg + 1);
    END IF;
  ELSE
     statusVar := 'incorrect';

    IF vercodVar::integer = codeArg::integer THEN
      INSERT INTO TreasureHunt.Visit(team, num, submitted_code, time,
                                      is_correct, visited_hunt, visited_wp)
      VALUES (teamidArg, (SELECT CASE WHEN MAX(num) IS NULL THEN 0 ELSE MAX(num) END
                          FROM TreasureHunt.Visit
                          WHERE team = teamidArg)+1,
              codeArg, date_trunc('seconds', current_timestamp)::timestamp,
              't', huntidArg, currentwpArg);

      GET DIAGNOSTICS countVar = ROW_COUNT;
    ELSE
      INSERT INTO TreasureHunt.Visit(team, num, submitted_code, time,
                                    is_correct, visited_hunt, visited_wp)
      VALUES (teamidArg, (SELECT CASE WHEN MAX(num) IS NULL THEN 0 ELSE MAX(num) END
                          FROM TreasureHunt.Visit V
                          WHERE V.team = teamidArg)+1,
              codeArg, date_trunc('seconds', current_timestamp)::timestamp,
              'f', NULL, NULL);

      GET DIAGNOSTICS countVar = ROW_COUNT;
     END IF;
  END IF;

  IF countVar = 0 THEN
    UPDATE TreasureHunt.Hunt
    SET statusVar = 'finished'
    WHERE hunt = huntid;
  END IF;

IF statusVar = 'complete' THEN
  scoreVar := (SELECT P.score
               FROM treasurehunt.participates P
               WHERE P.team = teamidArg AND P.hunt = huntidArg);
  RETURN QUERY SELECT statusVar, 'a'::varchar, 'a'::varchar, NOW()::timestamp without time zone,
                      'a'::text, scoreVar, 0::smallint, 'a'::text, rankVar;
ELSE
  RETURN QUERY SELECT statusVar, HS.name, HS.team, HS.start_time,
                    HS.elapsed, HS.score, HS.waypoint_count, HS.clue, 0
              FROM TreasureHunt.getHuntStatus(playerNameArg) HS;
END IF;

END;
$body$ LANGUAGE plpgsql VOLATILE EXTERNAL SECURITY DEFINER;


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
$body$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;


CREATE OR REPLACE FUNCTION treasureHunt.huntCount(varchar)
RETURNS TABLE(stat varchar) AS $body$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT PS.stat_value as stat
  FROM treasurehunt.playerStats PS
  WHERE PS.player = playerName AND PS.stat_name = 'finished_hunts';
END;
$body$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;


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
$body$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;


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
$body$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;


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
$BODY$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;


CREATE OR REPLACE FUNCTION treasureHunt.getAvailableHunts()
RETURNS TABLE(identi integer, name varchar, start timestamp without time zone, distance integer, nwaypoints integer)
AS $body$
BEGIN
  RETURN QUERY SELECT H.id as identi, H.title AS name, H.startTime as start, H.distance, H.numWayPoints AS nwaypoints
  FROM TreasureHunt.Hunt H
  WHERE status = 'open'
  ORDER BY H.title ASC;
END;
$body$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;


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
$body$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;


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
$body$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;


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
$body$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;

CREATE OR REPLACE FUNCTION updateScore(varchar)
RETURNS integer AS
$body$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  UPDATE treasurehunt.playerstats as P
  SET stat_value = P.stat_value::integer + 1
  FROM treasurehunt.memberof MO
  WHERE MO.player = P.player
    AND MO.team = (SELECT mem.team
      FROM treasurehunt.memberof mem
      WHERE mem.player = playerName
      AND current = 'true')
    AND P.stat_name = 'point_score' AND current = 'true';

    RETURN P.stat_value
    FROM treasurehunt.playerstats P
    WHERE player = playerName AND stat_name = 'point_score';
END;
$body$ LANGUAGE plpgsql VOLATILE EXTERNAL SECURITY DEFINER;


CREATE OR REPLACE FUNCTION updateFinishedHunts(varchar)
RETURNS integer AS
$body$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  UPDATE treasurehunt.playerstats as P
  SET stat_value = P.stat_value::integer + 1
  FROM treasurehunt.memberof MO
  WHERE MO.player = P.player
    AND MO.team = (SELECT mem.team
      FROM treasurehunt.memberof mem
      WHERE mem.player = playerName
      AND current = 'true')
    AND P.stat_name = 'finished_hunts' AND current = 'true';

    RETURN P.stat_value
    FROM treasurehunt.playerstats P
    WHERE player = playerName AND stat_name = 'finished_hunts';
END;
$body$ LANGUAGE plpgsql VOLATILE EXTERNAL SECURITY DEFINER;


CREATE OR REPLACE FUNCTION updateRank(integer, varchar, varchar)
RETURNS integer AS
$body$
DECLARE
  huntId ALIAS FOR $1;
  playerName ALIAS FOR $2;
  teamName ALIAS FOR $3;
BEGIN
  UPDATE treasurehunt.participates as P
  SET rank = (SELECT CASE WHEN max(rank) IS NULL
    THEN 1
    ELSE MAX(rank) + 1
    END
    FROM TreasureHunt.participates as PS
  WHERE PS.hunt = huntId)
  WHERE P.hunt = huntId AND P.team = teamName;

  RETURN P.rank
  FROM treasurehunt.participates P INNER JOIN memberof MO on (P.team = MO.team)
  WHERE MO.player = playerName AND P.hunt = huntId AND MO.current = 'true';
END;
$body$ LANGUAGE plpgsql VOLATILE EXTERNAL SECURITY DEFINER;


CREATE OR REPLACE FUNCTION getData(varchar)
RETURNS TABLE(team varchar, hunt integer, currentwp smallint,
              score integer, numwaypoints integer,
              starttime timestamp without time zone) AS
$body$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
      RETURN QUERY SELECT P.team, P.hunt, P.currentwp, P.score, H.numwaypoints, H.starttime
      FROM TreasureHunt.Participates P
      RIGHT OUTER JOIN TreasureHunt.MemberOf M USING (team)
      RIGHT OUTER JOIN TreasureHunt.Hunt H ON (P.Hunt = H.id)
      WHERE P.currentwp IS NOT NULL AND player = playerName and current = true;
END;
$body$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;


CREATE OR REPLACE FUNCTION TreasureHunt.getUserFratFrequency(varchar)
RETURNS TABLE(stat_name text, stat_value float8) AS $BODY$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY  SELECT FR.stat_name AS stat_name, CEIL((FR.base * 5)/(PC.num_players) + 1) AS stat_value
  FROM (
  SELECT DISTINCT RANK() OVER (ORDER BY (COUNT(P.hunt)/((EXTRACT(EPOCH FROM D.divisor))/(3600*24))) ASC, PL.name ASC) AS base , 
    'Frequency' AS stat_name, PL.name
    FROM TreasureHunt.Player PL 
    RIGHT OUTER JOIN TreasureHunt.MemberOf MO ON (PL.name = MO.player) 
    RIGHT OUTER JOIN TreasureHunt.Participates P ON (MO.team = P.team) 
    RIGHT OUTER JOIN (
      SELECT DISTINCT PL_N.name AS name, MAX(age(H_N.starttime)) AS divisor
      FROM TreasureHunt.Player PL_N 
      RIGHT OUTER JOIN TreasureHunt.MemberOf MO_N ON (PL_N.name = MO_N.player) 
      RIGHT OUTER JOIN TreasureHunt.Participates P_N ON (MO_N.team = P_N.team) 
      RIGHT OUTER JOIN TreasureHunt.Hunt H_N ON (P_N.hunt = H_N.id)
      GROUP BY PL_N.name
    )D ON (D.name = PL.name)
    GROUP BY PL.name, D.divisor) FR, 
  (SELECT COUNT(P_C.name) AS num_players
    FROM TreasureHunt.Player P_C
    ) PC
  WHERE FR.name = playerName;
END;
$BODY$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;



CREATE OR REPLACE FUNCTION TreasureHunt.getUserFratRecency(varchar)
RETURNS TABLE(stat_name text, stat_value float8) AS $BODY$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT FR.stat_name AS stat_name, CEIL((FR.base * 5)/(PC.num_players)) AS stat_value
  FROM (
	SELECT DISTINCT RANK() OVER (ORDER BY (MIN(age(H.starttime))) DESC, PL.name ASC) AS base , 'Recency' AS stat_name, PL.name AS name
		FROM TreasureHunt.Player PL 
		RIGHT OUTER JOIN TreasureHunt.MemberOf MO ON (PL.name = MO.player) 
		RIGHT OUTER JOIN TreasureHunt.Participates P ON (MO.team = P.team) 
		RIGHT OUTER JOIN TreasureHunt.Hunt H ON (P.hunt = H.id)
		WHERE H.status = 'finished'
		GROUP BY PL.name) FR,
		(SELECT COUNT(PL.name) AS num_players
		FROM TreasureHunt.Player PL
		RIGHT OUTER JOIN TreasureHunt.MemberOf MO ON (PL.name = MO.player) 
		RIGHT OUTER JOIN TreasureHunt.Participates P ON (MO.team = P.team) 
		RIGHT OUTER JOIN TreasureHunt.Hunt H ON (P.hunt = H.id)
		WHERE H.status = 'finished'
		) PC
  WHERE FR.name = playerName;
END;
$BODY$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;



CREATE OR REPLACE FUNCTION TreasureHunt.getUserFratAmount(varchar)
RETURNS TABLE(stat_name text, stat_value float8) AS $BODY$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT FR.stat_name AS stat_name, CEIL((FR.base * 5)/(PC.num_players)) + 1 AS stat_value
  FROM (
	SELECT DISTINCT RANK() OVER (ORDER BY (SUM(P.score)/((EXTRACT(EPOCH FROM D.divisor))/(3600*24*7*4))) ASC) AS base , 'Amount' AS stat_name, PL.name AS name
		FROM TreasureHunt.Player PL 
		RIGHT OUTER JOIN TreasureHunt.MemberOf MO ON (PL.name = MO.player) 
		RIGHT OUTER JOIN TreasureHunt.Participates P ON (MO.team = P.team) 
		RIGHT OUTER JOIN (
			SELECT DISTINCT PL_N.name AS name, MAX( age(H_N.starttime)) AS divisor
			FROM TreasureHunt.Player PL_N 
			RIGHT OUTER JOIN TreasureHunt.MemberOf MO_N ON (PL_N.name = MO_N.player) 
			RIGHT OUTER JOIN TreasureHunt.Participates P_N ON (MO_N.team = P_N.team) 
			RIGHT OUTER JOIN TreasureHunt.Hunt H_N ON (P_N.hunt = H_N.id)
			GROUP BY PL_N.name
		)D ON (D.name = PL.name)
		GROUP BY PL.name, D.divisor) FR,
		(SELECT COUNT(P_C.name) AS num_players
		FROM TreasureHunt.Player P_C
		) PC
  WHERE FR.name = playerName;
END;
$BODY$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;



CREATE OR REPLACE FUNCTION TreasureHunt.getUserFratType(varchar)
RETURNS TABLE(stat_name text, stat_value text) AS $BODY$
DECLARE
  playerName ALIAS FOR $1;
BEGIN
  RETURN QUERY SELECT F.stat_name, F.stat_value
FROM (
SELECT DISTINCT FR.stat_name AS stat_name, SUM(FR.stat_value) AS stat, FR.name,
	CASE WHEN FR.stat_value < 0 THEN 'Weekend'
	     WHEN FR.stat_value > 0 THEN 'Weekday'
	ELSE 'Both or neither'
	END AS stat_value
  FROM (
	SELECT FR_N.stat_name AS stat_name, FR_N.base AS stat, FR_N.name AS name,
		   CASE  WHEN FR_N.base = 0 THEN -1
			 WHEN FR_N.base = 6 THEN -1
			 ELSE 1
			 END AS stat_value
		FROM (SELECT DISTINCT 'Player Type' AS stat_name, PL.name AS name, EXTRACT(DOW FROM H.starttime) AS base
			FROM TreasureHunt.Player PL 
			RIGHT OUTER JOIN TreasureHunt.MemberOf MO ON (PL.name = MO.player) 
			RIGHT OUTER JOIN TreasureHunt.Participates P ON (MO.team = P.team) 
			RIGHT OUTER JOIN TreasureHunt.Hunt H ON (P.hunt = H.id)
			WHERE PL.name = playerName 
			) FR_N
	) FR
	GROUP BY FR.stat_name, FR.stat_value, FR.name
	) F;
END;
$BODY$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;


CREATE OR REPLACE FUNCTION getCompletedHunts(playerName varchar)
RETURNS TABLE(huntname varchar, score integer, rank integer, duration durationdomain) AS
$body$
BEGIN
  RETURN QUERY SELECT CT.title AS huntname, CT.score, CT.rank, CT.duration
  from (SELECT * FROM hunt H 
     inner join participates P on (H.id = P.hunt)
     inner join memberof MO on (P.team  = MO.team)) AS CT
  WHERE CT.player = playerName AND CT.rank IS NOT NULL;
END;
$body$ LANGUAGE plpgsql STABLE EXTERNAL SECURITY DEFINER;