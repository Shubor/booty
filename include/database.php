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
function connect($file = 'config.ini')
{
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
        print "Error Connecting to Database: " . $e->getMessage() . "<br/>";
        die();
    }
    return $dbh;
}

/**
 * Check login details
 * @param string $name Login name
 * @param string $pass Password
 * @return boolean True is login details are correct
 */
function checkLogin($name,$pass)
{
    // STUDENT TODO:
    // Replace line below with code to validate details from the database

    //The status of the connection returns either PGSQL_CONNECTION_OK or PGSQL_CONNECTION_BAD//
    $STH = connect();

    if ($STH === PGSQL_CONNECTION_BAD)
    {
      return ($name == 'testuser' && $pass == 'testpass');
    }
    else
    {
        // $getsalt = "SELECT pw_salt FROM treasurehunt.Player AS p WHERE p.name = ?";

        // $salt = $STH->prepare($getsalt);
        // $salt->bindValue(1, $name);
        // $salt->execute();

        // $salt->fetch();
        // $hash_password = crypt($pass);

        $query = $STH->prepare("SELECT name FROM treasurehunt.Player AS p WHERE p.name = :name AND p.password = :passwd LIMIT 1");
        $query->bindValue(':name', $name, PDO::PARAM_INT);
        $query->bindValue('passwd', $pass, PDO::PARAM_STR);
        $query->execute();

        if ($query->fetch())
        {
           return true;
        }
        else
        {
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

  $STH = connect();

  $queryName =  $STH->prepare("SELECT * FROM treasurehunt.dashboardName(?);");
  $queryStat =  $STH->prepare("SELECT * FROM treasurehunt.huntCount(?);");
  $queryBadge = $STH->prepare("SELECT * FROM treasurehunt.getBadges(?);");

  $queryName->bindParam(1, $user, PDO::PARAM_STR);
  $queryStat->bindParam(1, $user, PDO::PARAM_STR);
  $queryBadge->bindParam(1, $user, PDO::PARAM_STR);

  $queryName->execute();
  $queryStat->execute();
  $queryBadge->execute();

  $queryName->setFetchMode(PDO::FETCH_ASSOC);
  $queryStat->setFetchMode(PDO::FETCH_ASSOC);
  $queryBadge->setFetchMode(PDO::FETCH_ASSOC);

  $resultName = $queryName->fetch();
  $resultStat = $queryStat->fetch();
  $resultBadge = $queryBadge->fetchAll();

  $results = array();

  $results['name'] = $resultName['name'];
  $results['address'] = $resultName['addr'];
  $results['team'] = $resultName['curr'];
  $results['nhunts'] =$resultStat['stat'];
  $results['badges'] = $resultBadge;

  return $results;
}


/**
 * List hunts that are currently available
 * @return array Various details of for available hunts - see hunts.php
 * @throws Exception
 */
function getAvailableHunts()
{
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
function getHuntDetails($hunt)
{
    // STUDENT TODO:
    // Replace lines below with code to get details of a hunt from the database

    $STH = connect();

    $query = "SELECT count(title) FROM Hunt WHERE id = $hunt";
    $exists = pg_query($conn, $query);
    if ($exists = 0) throw new Exception('Unknown hunt.');


    $query_one = $STH->prepare("SELECT title AS name, description AS descrip, distance, startTime AS start, numWayPoints AS n_wp FROM TreasureHunt.Hunt WHERE id = ?");
    $query_two = $STH->prepare("SELECT count(*) AS nteams FROM TreasureHunt.Participates WHERE hunt = ?");

    $query_one->bindParam(1, $hunt, PDO::PARAM_STR);
    $query_two->bindParam(1, $hunt, PDO::PARAM_STR);

    $query_one->execute();
    $query_two->execute();

    $query_one->setFetchMode(PDO::FETCH_ASSOC);
    $query_two->setFetchMode(PDO::FETCH_ASSOC);

    $results_one->fetch();
    $results_two->fetch();

    $results = array();

    $results['name'] = $results_one['name'];
    $results['descrip'] = $results_one['descrip'];
    $results['start'] = $results_one['start'];
    $results['distance'] = $results_one['distance'];
    $results['nteams'] = $results_two['nteams'];
    $results['n_wp'] = $results_one['n_wp'];

    return $results;
}

/**
 * Show status of user in their current hunt
 * @param string $user
 * @return array Various details of current hunt - see current.php
 * @throws Exception
 */
function getHuntStatus($user)
{

    // STUDENT TODO:
    // Replace lines below with code to obtain details from the database

    $STH = connect();

    $query =  $STH->prepare("SELECT H.status AS status, H.title AS name,
          M.team AS team, H.startTime as start_time,
          (P.duration/60) || ' hours and ' || (P.duration%60) || ' minutes' as elapsed,
          P.score as score, P.currentWP as waypoint_count, W.clue as clue
    FROM TreasureHunt.Hunt H
      RIGHT OUTER JOIN TreasureHunt.Participates P ON (H.id=P.hunt)
      RIGHT OUTER JOIN TreasureHunt.MemberOf M ON (M.team=P.team)
      RIGHT OUTER JOIN TreasureHunt.Waypoint W ON (H.id=W.hunt)
    WHERE M.player=? AND M.current='true' AND P.currentWP=W.num;");

    $query->bindParam(1, $user, PDO::PARAM_STR);

    $query->execute();

    $query->setFetchMode(PDO::FETCH_ASSOC);

    $resultHunt = $query->fetch();

    $results = array(
        'status'=>$resultHunt['status'],
        'name'=>$resultHunt['name'],
        'team'=>$resultHunt['team'],
        'start_time'=>$resultHunt['start_time'],
        'elapsed'=>$resultHunt['elapsed'],
        // Need separate conditional table, only included if hunt status == active
        'score'=>$resultHunt['score'],
        'waypoint_count'=>$resultHunt['waypoint_count'] ,
        'clue'=>$resultHunt['clue']
    );

    // Check $user exists in the database -- otherwise throw exception
    // $check_user_exists = pg_query("SELECT * FROM Player WHERE name='$user'");
    // if (pg_num_rows($check_user_exists) = 0)
    // {
    //     throw new Exception('Unknown user.');
    // }

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

    return $results;
}

/**
 * Check validation code is for user's next expected waypoint
 * @param string $user
 * @param integer $code Validation code (e.g. from QR)
 * @return array Various details of current visit - see validate.php
 * @throws Exception
 */
function validateVisit($user,$code)
{
  	$STH = connect();

    // STUDENT TODO:
    // Replace lines below with code to obtain status from the database
    // (You could extend this to

  	// Find Required Code
  	// Test required vs input code
  	// If wrong return invalid
  	// Else return 'correct' 'current_rank' 'current_score' and next clue


  	//IN PROGRESS TODO: Revise queries into one or two queries
  	// 		Implement rank checking
  	//		Increment Score on correct visit
  	//		Check if incorrect waypoint is in another hunt or in the wrong order

    $query_one = $STH->prepare("SELECT hunt, currentWP, rank, score
      FROM TreasureHunt.Participates WHERE team = ? AND currentWP IS NOT NULL");
    //Test if rank increases in later query, placeholder
    //Score increase
    $query_one->bindParam(1, $team, PDO::PARAM_STR);

    $query_two = $STH->prepare("SELECT curr FROM MemberOf WHERE player = ? LIMIT 1");
    $query_two->bindParam(1, $user, PDO::PARAM_STR);

    $query_three = $STH->prepare("SELECT verification_code FROM Waypoint WHERE hunt = ? AND num = ?");
    $query_three->bindParam(1, $hunt, PDO::PARAM_STR);
    $query_three->bindParam(2, $currentWP_num, PDO::PARAM_STR);

    $query_four = $STH->prepare("SELECT numWayPoints FROM Hunt WHERE id = ?");
    $query_four->bindParam(1, $hunt, PDO::PARAM_STR);

    $query_one->execute();
    $query_one->setFetchMode(PDO::FETCH_ASSOC);
    $query_two->execute();
    $query_two->setFetchMode(PDO::FETCH_ASSOC);
    $query_three->execute();
    $query_three->setFetchMode(PDO::FETCH_ASSOC);
    $query_four->execute();
    $query_four->setFetchMode(PDO::FETCH_ASSOC);

	 // $query = "SELECT hunt FROM Participates WHERE team = $team AND currentWP IS NOT NULL";
	 // $hunt = pg_query($conn, $query);

	 // $query = "SELECT currentWP FROM Participates WHERE team = $team AND currentWP IS NOT NULL";
	 // $currentWP_num = pg_query($conn, $query);

	 // $query = "SELECT rank FROM Participates WHERE team = $team AND currentWP IS NOT NULL";
	 // $rank = pg_query($conn, $query); //Test if rank increases in later query, placeholder

	 // $query = "SELECT score FROM Participates WHERE team = $team AND currentWP IS NOT NULL";
	 // $score = pg_query($conn, $query); //Score increase

	 // $query = "SELECT verification_code FROM Waypoint WHERE hunt = $hunt AND num = $currentWP_num";
	 // $ver_code = pg_query($conn, $query);

	 // $query = "SELECT numWayPoints FROM Hunt WHERE id = $hunt";
	 // $num_waypoints =  pg_query($conn, $query);

    if ($code != $query_three) {
        // Wrong code - could also check whether the code is for another waypoint)
        return array (
            'status'=>'invalid'
        );
    } else { //test if last waypoint, test rank

		if ($currentWP_num = $num_waypoints) { // Tests if last waypoint, no clue returned
			return array(
            'status'=>'correct',
            'rank'=>$rank,
            'score'=>$score,
        );

		}
		$query = "SELECT clue FROM Waypoint WHERE hunt = $hunt AND num = ($currentWP_num + 1)"; //Gets next clue
		$clue = pg_query($conn, $query);
		return array(
            'status'=>'correct',
            'rank'=>$rank,
            'score'=>$score,
            'clue'=>$clue
        );
	}
}
?>