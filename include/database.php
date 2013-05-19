<?php
/**
 * Database functions. You need to modify each of these to interact with the database and return appropriate results.
 */

/**
 * Connect to database
 * This function does not need to be edited - just update config.ini with your own
 * database connection details.
 * @param string $file Location of configuration data
 * @return PDO database object
 * @throws exception
 */


function connect($file = 'config.ini') {
	// read database seetings from config file
    if ( !$settings = parse_ini_file($file, TRUE) )
        throw new exception('Unable to open ' . $file);

    // parse contents of config.ini
    $dns = $settings['database']['driver'] . ':' .
            'host=' . $settings['database']['host'] .
            ((!empty($settings['database']['port'])) ? (';port=' . $settings['database']['port']) : '') .
            ';dbname=' . $settings['database']['schema'];
    $user= $settings['db_user']['username'];
    $pw  = $settings['db_user']['password'];

	// create new database connection
    try {
        $dbh=new PDO($dns, $user, $pw);
        $dbh->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch (PDOException $e) {
        //print "Error Connecting to Database: " . $e->getMessage() . "<br/>";
        //die();
        return PGSQL_CONNECTION_BAD;

    }
    return $dbh;
}

/**
 * Check login details
 * @param string $name Login name
 * @param string $pass Password
 * @return boolean True is login details are correct
 */
function checkLogin($name,$pass) {
    // STUDENT TODO:
    // Replace line below with code to validate details from the database
    //

    //The status of the connection returns either PGSQL_CONNECTION_OK or PGSQL_CONNECTION_BAD//
    $connection = connect();

    if ($connection === PGSQL_CONNECTION_BAD){
        return ($name == 'testuser' && $pass == 'testpass');
    } else {
        $hash_password = crypt($pass);
        $query = "SELECT name FROM Player WHERE name = ? AND password = ? LIMIT 1";
        $login = $connection->prepare($query);
        $login->bindValue(1, $name);
        $login->bindValue(2, crypt($pass, $hash_password));
        $login->execute();

        if ($login->fetch()) {
            return true;
        } else {
            return false;
        }
    }
}

/**
 * Get details of the current user
 * @param string $user login name user
 * @return array Details of user - see index.php
 */
function getUserDetails($user) {
    // STUDENT TODO:
    // Replace lines below with code to validate details from the database
    if ($user != 'testuser') throw new Exception('Unknown user');
    $results = array();
    // Example user data - this should come from a query
    $results['name'] = 'Pirate Bob';
    $results['address'] = 'Sydney, Australia';
    $results['team'] = 'Lily-livered landlubbers';
    $results['nhunts'] = 17;
    $results['badges'] = array(
        array('desc'=>'Completed more than 10 hunts', 'name'=>'Veteran Treasure Hunter'),
        array('desc'=>'1st visitor to 50% of locations in a hunt', 'name'=>'Yellow Jersey', 'quantity'=>3),
        array('desc'=>'Last player to complete a hunt', 'name'=>'Peg Leg', 'quantity'=>2),
        array('desc'=>'First player to complete a hunt', 'name'=>'Gold Medal'),
        array('desc'=>'Second player to complete a hunt', 'name'=>'Silver Medal'),
        array('desc'=>'Third player to complete a hunt', 'name'=>'Bronze Medal', 'quantity'=>3),
        array('desc'=>'Visited locations out of order in a hunt', 'name'=>'Broken Compass', 'quantity'=>2),
        array('desc'=>'Visited a location from the wrong hunt', 'name'=>'Crossed Paths')
    );

    return $results;
}

/**
 * List hunts that are currently available
 * @return array Various details of for available hunts - see hunts.php
 * @throws Exception
 */
function getAvailableHunts() {
    // STUDENT TODO:
    // Replace lines below with code to get list of available hunts from the database
    // Example hunt info - this should come from a query
    $results = array(
        array('id'=>1234,'name'=>'Harbour Havoc','start'=>'9am 10/2/13','distance'=>'10 km','nwaypoints'=>5),
        array('id'=>4563,'name'=>'Lost in Lane Cove','start'=>'5pm 1/3/13','distance'=>'2 km','nwaypoints'=>8),
        array('id'=>7789,'name'=>'Paramatta River Trail','start'=>'9am 4/3/13','distance'=>'8 km','nwaypoints'=>5)
    );

    return $results;
}

/**
 * Get details for a specific hunt
 * @param integer $hunt ID of hunt
 * @return array Various details of current hunt - see huntdetails.php
 * @throws Exception
 */
function getHuntDetails($hunt) {

	$conn = connect($file = 'config.ini');

    // STUDENT TODO:
    // Replace lines below with code to get details of a hunt from the database
	$query = "SELECT count(title) FROM Hunt WHERE id = $hunt";
		$exists = pg_query($conn, $query);


    if ($exists = 0) throw new Exception('Unknown hunt.');

    // Example hunt details - this should come from a query

	$query = "SELECT title FROM Hunt WHERE id = $hunt";
		$name = pg_query($conn, $query);
	$query = "SELECT description FROM Hunt WHERE id = $hunt";
		$desc = pg_query($conn, $query);
	$query = "SELECT count(*) FROM Participates WHERE hunt = $hunt";
		$nteams = pg_query($conn, $query);
	$query = "SELECT distance FROM Hunt WHERE id = $hunt";
		$dist = pg_query($conn, $query);
	$query = "SELECT startTime FROM Hunt WHERE id = $hunt";
		$desc = pg_query($conn, $query);
	$query = "SELECT startTime FROM Hunt WHERE id = $hunt";
		$start = pg_query($conn, $query);
	$query = "SELECT numWayPoints FROM Hunt WHERE id = $hunt";
		$n_wp = pg_query($conn, $query);

    $results = array(
        'name'=>$name,
        'desc'=>$desc,
        'nteams'=>$nteams,
        'distance'=>$dist,
        'start'=>$start,
        'n_wp'=>$n_wp,
    );

    return $results;
}

/**
 * Show status of user in their current hunt
 * @param string $user
 * @return array Various details of current hunt - see current.php
 * @throws Exception
 */
function getHuntStatus($user) {
    // STUDENT TODO:
    // Replace lines below with code to obtain details from the database
    //

    // Check $user exists in the database -- otherwise throw exception
    // $check_user_exists = pg_query("SELECT * FROM Player WHERE name='$user'");
    // if (pg_num_rows($check_user_exists) = 0)
    // {
    //     throw new Exception('Unknown user.');
    // }

    // $query = pg_query('SELECT H.status AS status, H.title AS name,
    // M.team AS team, H.startTime as start_time,
    //        (P.duration/60) || ' hours and ' || (P.duration%60) || ' minutes' as elapsed,
    //        P.score as score, P.currentWP as waypoint_count, W.clue as clue
    // FROM TreasureHunt.Hunt H
    //   RIGHT OUTER JOIN TreasureHunt.Participates P ON (H.id=P.hunt)
    //   RIGHT OUTER JOIN TreasureHunt.MemberOf M ON (M.team=P.team)
    //   RIGHT OUTER JOIN TreasureHunt.Waypoint W ON (H.id=W.hunt)
    // WHERE M.player='Yoda' AND M.current='true' AND P.currentWP=W.num;');

    // $results = array(
    //     'status'=>'in progress',
    //     'name'=>'Harbour Havoc',
    //     'team'=>'Lily-livered landlubbers',
    //     'start_time'=>'9am 10/2/13',
    //     'elapsed'=>'4 hours',
    //     'score'=>'3564',
    //     'waypoint_count'=>5,
    //     'clue'=>'Sit down and watch the ships go by with Mrs Macquarie'
    // );

    if ($user != 'testuser') throw new Exception('Unknown user');
    $results = array(
        'status'=>'in progress',
        'name'=>'Harbour Havoc',
        'team'=>'Lily-livered landlubbers',
        'start_time'=>'9am 10/2/13',
        'elapsed'=>'4 hours',
        'score'=>'3564',
        'waypoint_count'=>5,
        'clue'=>'Sit down and watch the ships go by with Mrs Macquarie'
    );

    return $results;
}

/**
 * Check validation code is for user's next expected waypoint
 * @param string $user
 * @param integer $code Validation code (e.g. from QR)
 * @return array Various details of current visit - see validate.php
 * @throws Exception
 */
function validateVisit($user,$code) {
    // STUDENT TODO:
    // Replace lines below with code to obtain status from the database
    // (You could extend this to
    if ($user != 'testuser') throw new Exception('Unknown user');
    if ($code != '1234') {
        // Wrong code - could also check whether the code is for another waypoint)
        return array (
            'status'=>'invalid'
        );
    } else return array(
            'status'=>'correct',
            'rank'=>2,
            'score'=>6348,
            'clue'=>'GPS 123.43, 1245.434'
        );
}
?>