/*
 * fixing the Goonies hunt so that each player is only active in at most one team
 * we move both 'stef' and 'mikey' both to team 'Couple'
 * team 'GoonSelect' gets new player 'andy' as a second team member;
 * player statistics are adjusted.
 *
 * This script runs on PostgreSQL.
 */
BEGIN TRANSACTION;
INSERT INTO Player (name, password, pw_salt, gender, addr)
   VALUES ('andy',  'plank',  'h#o#h#u#', 'f', 'Goon Docks');
INSERT INTO PlayerStats VALUES ('andy',  'finished_hunts', '1');
INSERT INTO PlayerStats VALUES ('andy',  'point_score', '6');
INSERT INTO PlayerStats VALUES ('andy',  'wrong_visits', '1');
UPDATE PlayerStats SET  stat_value = '9' WHERE player='mikey' AND stat_name='point_score';
UPDATE PlayerStats SET  stat_value = '0' WHERE player='stef' AND stat_name='point_score';
UPDATE PlayerStats SET  stat_value = '0' WHERE player='stef' AND stat_name='finished_hunts';
DELETE FROM PlayerStats WHERE player='stef' AND stat_name='wrong_visits';
DELETE FROM PlayerStats WHERE player='mikey' AND stat_name='wrong_visits';
DELETE FROM MemberOf WHERE player = 'stef' AND team ='GoonSelect';
DELETE FROM MemberOf WHERE player = 'mikey' AND team ='GoonSelect';
INSERT INTO MemberOf VALUES ('stef',  'GoonSelect', DATE '1985-01-01', false);
INSERT INTO MemberOf VALUES ('andy',  'GoonSelect', DATE '1985-02-21', true);
INSERT INTO Achievements (player, badge, whenReceived) VALUES ('andy',  'Novice Player', DATE '1985-06-07');
COMMIT;


/*
 * Fixing one player stats which had some spaces in its value by mistake
 */
BEGIN TRANSACTION;
  UPDATE PlayerStats SET  stat_value = '16' WHERE player='Ash' AND stat_name='point_score';
COMMIT;


/*
 * 'Find one Piece' hunt (thanks to Blake)
 * missing hunt from the original example data script - sorry Blake.
 */
BEGIN TRANSACTION;

INSERT INTO Hunt (id,title,description,distance,numWayPoints,startTime,status)
VALUES (16, 'Find One Piece', 'This is the hunt you will always remember as the hunt in which you almost caught Captain Jack Sparrow!', 350000, 6, TIMESTAMP '2008-10-20 08:00:00', 'active');

INSERT INTO PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon)
VALUES (16, 1, 'Foosha Docks', 66371, 'There once was a man named Gold Roger, who was king of the pirates! He left everything he owned... in One Piece.', 41.15850,174.47210);
INSERT INTO PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon)
VALUES (16, 2, 'Kuro Bay', 66372, 'Further east you will find black waters and your next waypoint.', 41.17050,174.0010);
INSERT INTO PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon)
VALUES (16, 3, 'Krieg Caverns', 66373, 'Caves home to the infamous pirate Don Krieg.', 42.06050,175.00105);
INSERT INTO PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon)
VALUES (16, 4, 'Sun Temple', 66374, 'Rumour has it fishmen live at the next waypoint.', 44.06050,174.90101);
INSERT INTO PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon)
VALUES (16, 5, 'Drum Island', 66375, 'North leads to a snowy, percussion island.', 40.89520,152.88406);
INSERT INTO PhysicalWaypoint (hunt, num, name, verification_code, clue, gpsLat, gpsLon)
VALUES (16, 6, 'Alabasta Docks', 66376, 'Great white kingdom of legend.', 38.33210,150.0010);

INSERT INTO Player (name, password, pw_salt, gender, addr)
VALUES ('mdluffy', 'gumgum1', 'g#m#g#m#', 'm', 'Foosha Village');
INSERT INTO Player (name, password, pw_salt, gender, addr)
VALUES ('rzolo', 'tastysword3', 't#s#y#w#r#', 'm', 'Shimotsuki Village');
INSERT INTO Player (name, password, pw_salt, gender, addr)
VALUES ('nami', 'hunter2', 'h#n#e#2', 'f', 'Cocoyashi Village');
INSERT INTO Player (name, password, pw_salt, gender, addr)
VALUES ('arlong', 'sawnose2', 's#w#o#e#', 'm', 'Sun Temple');
INSERT INTO Player (name, password, pw_salt, gender, addr)
VALUES ('catfish', 'pieuman1', 'p#e#m#n#', 'm', 'Sun Temple');

INSERT INTO PlayerStats VALUES ('mdluffy', 'finished_hunts', '0');
INSERT INTO PlayerStats VALUES ('mdluffy', 'point_score',    '5');
INSERT INTO PlayerStats VALUES ('rzolo',   'finished_hunts', '0');
INSERT INTO PlayerStats VALUES ('rzolo',   'point_score',    '5');
INSERT INTO PlayerStats VALUES ('nami',    'finished_hunts', '0');
INSERT INTO PlayerStats VALUES ('nami',    'point_score',    '5');
INSERT INTO PlayerStats VALUES ('catfish', 'finished_hunts', '4');
INSERT INTO PlayerStats VALUES ('catfish', 'point_score',   '36');
INSERT INTO PlayerStats VALUES ('arlong',  'finished_hunts', '4');
INSERT INTO PlayerStats VALUES ('arlong',  'point_score',   '36');

INSERT INTO Team (name, created) VALUES ('StrawHats', DATE '2008-11-18');
INSERT INTO Team (name, created) VALUES ('Fishmen',   DATE '2007-08-09');

INSERT INTO MemberOf VALUES ('mdluffy', 'StrawHats', DATE '2008-11-18', true);
INSERT INTO MemberOf VALUES ('rzolo',   'StrawHats', DATE '2008-11-18', true);
INSERT INTO MemberOf VALUES ('nami',    'StrawHats', DATE '2008-11-26', true);
INSERT INTO MemberOf VALUES ('arlong',  'Fishmen',   DATE '2007-08-09', true);
INSERT INTO MemberOf VALUES ('catfish', 'Fishmen',   DATE '2007-08-09', true);

INSERT INTO Badge (name, description, condition)
VALUES ('Tide Hunter',   'Given to hunters who crossed an ocean to reach a waypoint.', 'boat_travel_count != 0');
INSERT INTO Badge (name, description, condition)
VALUES ('Night Stalker', 'Given to hunters who reach a waypoint between 12am and 6am on any day.', 'EXISTS discover_time_hour BETWEEN 0 AND 6');

INSERT INTO Achievements (player, badge, whenReceived) VALUES ('mdluffy', 'Novice Player',DATE '2008-12-17');
INSERT INTO Achievements (player, badge, whenReceived) VALUES ('mdluffy', 'Tide Hunter',  DATE '2008-12-17');
INSERT INTO Achievements (player, badge, whenReceived) VALUES ('rzolo',   'Novice Player',DATE '2008-12-17');
INSERT INTO Achievements (player, badge, whenReceived) VALUES ('rzolo',   'Tide Hunter',  DATE '2008-12-17');
INSERT INTO Achievements (player, badge, whenReceived) VALUES ('nami',    'Novice Player',DATE '2008-12-17');
INSERT INTO Achievements (player, badge, whenReceived) VALUES ('nami',    'Tide Hunter',  DATE '2008-12-17');
INSERT INTO Achievements (player, badge, whenReceived) VALUES ('arlong',  'Tide Hunter',  DATE '2007-09-13');
INSERT INTO Achievements (player, badge, whenReceived) VALUES ('catfish', 'Tide Hunter',  DATE '2007-09-13');
INSERT INTO Achievements (player, badge, whenReceived) VALUES ('arlong',  'Night Stalker',DATE '2009-02-14');
INSERT INTO Achievements (player, badge, whenReceived) VALUES ('catfish', 'Night Stalker',DATE '2009-02-14');

INSERT INTO Visit VALUES ('StrawHats', 1, 66371, TIMESTAMP '2008-12-17 12:00:01', true, 16, 1);
INSERT INTO Visit VALUES ('StrawHats', 2, 66372, TIMESTAMP '2008-12-18 12:00:02', true, 16, 2);
INSERT INTO Visit VALUES ('StrawHats', 3, 66373, TIMESTAMP '2008-12-21 12:00:03', true, 16, 2);
INSERT INTO Visit VALUES ('StrawHats', 4, 66374, TIMESTAMP '2008-12-23 12:00:04', true, 16, 3);
INSERT INTO Visit VALUES ('StrawHats', 5, 66375, TIMESTAMP '2009-01-01 12:00:05', true, 16, 4);
INSERT INTO Visit VALUES ('Fishmen',   1, 66371, TIMESTAMP '2007-09-13 12:00:01', true, 16, 1);
INSERT INTO Visit VALUES ('Fishmen',   2, 66372, TIMESTAMP '2007-09-15 12:00:01', true, 16, 2);
INSERT INTO Visit VALUES ('Fishmen',   3, 66993, TIMESTAMP '2007-09-16 12:00:03',false, 16, 3);

INSERT INTO Participates (hunt, team, currentWP, score, rank, duration)
VALUES (16, 'StrawHats', 6, 5, NULL, NULL);
INSERT INTO Participates (hunt, team, currentWP, score, rank, duration)
VALUES (16, 'Fishmen',   3, 2, NULL, NULL);

INSERT INTO Review (id, hunt, player, whenDone, rating, description)
VALUES (17, 16, 'mdluffy', TIMESTAMP '2008-12-23 10:00:00', 1, 'Got attacked by fishmen, 1/5 would not do again.');
INSERT INTO Review (id, hunt, player, whenDone, rating, description)
VALUES (18, 16, 'arlong',  TIMESTAMP '2009-09-16 11:12:34', 4, 'Sun Temple is a pretty nice place.');

INSERT INTO Likes (review, player, whenDone, usefulness)
VALUES (17, 'arlong', TIMESTAMP '2008-12-24 14:00:00', 5);

COMMIT;
