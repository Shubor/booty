/*
 * fixing the visits of the 'Pokemon' and 'Find one Piece' hunts
 *
 * This script assume the data set in your database to be at version 1.1 so far!
 * The script runs in both PostgreSQL and Oracle.
 */
UPDATE Visit SET time = time + INTERVAL '14' MONTH
           WHERE team='Fishmen' AND visited_hunt=16 AND extract(Year FROM time)=2007
             AND EXISTS (SELECT 1
                           FROM Hunt
                          WHERE title='Find One Piece'
                            AND starttime=TIMESTAMP '2008-10-20 08:00:00');

UPDATE Visit SET time = time + INTERVAL '1' YEAR
           WHERE team IN ('CatchEmAll', 'Rival')
             AND (visited_hunt=12 OR visited_hunt IS NULL)
             AND extract(Year FROM time)=2011
             AND EXISTS (SELECT 1
                           FROM Hunt
                          WHERE title='Kanto Pokemon Hunt'
                            AND starttime=TIMESTAMP '2012-07-18 13:05:00');
