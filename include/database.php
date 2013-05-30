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

        $query = $STH->prepare("SELECT * FROM TreasureHunt.checkLogin(?,?);");
        $query->bindValue(1, $name, PDO::PARAM_INT);
        $query->bindValue(2, $pass, PDO::PARAM_STR);
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
    /*All attempted connections, if they fail are error
    handled by the connect function*/
    $STH = connect();

    $query = $STH->prepare("SELECT * FROM treasurehunt.getAvailableHunts();");
    $query->execute();
    $results = $query->fetchAll();

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

    // $query = "SELECT count(title) FROM Hunt WHERE id = $hunt";

    $query_one = $STH->prepare("SELECT * FROM TreasureHunt.getHuntDetails(?);");
    $query_two = $STH->prepare("SELECT * FROM TreasureHunt.getParticipateCount(?);");

    $query_one->bindParam(1, $hunt, PDO::PARAM_STR);
    $query_two->bindParam(1, $hunt, PDO::PARAM_STR);

    $query_one->execute();
    $query_two->execute();

    $query_one->setFetchMode(PDO::FETCH_ASSOC);
    $query_two->setFetchMode(PDO::FETCH_ASSOC);

    $results_one = $query_one->fetch();
    $results_two = $query_two->fetch();

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

    $query =  $STH->prepare("SELECT * FROM treasurehunt.getHuntStatus(?);");
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

    $query = $STH->prepare("SELECT * FROM TreasureHunt.Participates P
      RIGHT OUTER JOIN TreasureHunt.MemberOf M USING (team)
      RIGHT OUTER JOIN TreasureHunt.Hunt H ON (P.Hunt = H.id)
      WHERE P.currentwp IS NOT NULL AND player = ? and current = true");
    $query->bindParam(1, $user, PDO::PARAM_STR);
    $query->execute();
    $query->setFetchMode(PDO::FETCH_ASSOC);
    $result = $query->fetch();

    $hunt_id = $result['hunt']; // hunt id
    $currentwp = $result['currentwp'];
    $team = $result['team'];
    $score = $result['score'];
    $num_waypts = $result['numwaypoints'];
    $curr_timestamp = NOW();

    $results = array();

    // Fetch required verification code and then compare it with given verification code
    $ver_code = $STH->prepare("SELECT * FROM TreasureHunt.Waypoint WHERE hunt = ? AND num = ?");
    $ver_code->bindParam(1, $hunt_id, PDO::PARAM_STR);
    $ver_code->bindParam(2, $currentwp, PDO::PARAM_STR);
    $ver_code->execute();
    $ver_code->setFetchMode(PDO::FETCH_ASSOC);
    $ver_code_result = $ver_code->fetch();

    if ($code == $ver_code['verification_code'])
    {
        // Last waypoint
        //   update team's hunt status, (currentwp = null, duration, score, rank)
        if ($currentwp == $num_waypts)
        {
            $results['status'] = 'complete';

            $update_query = $STH->prepare("UPDATE TreasureHunt.Participates P
              RIGHT OUTER JOIN TreasureHunt.Hunt H ON (P.Hunt = H.id)
              SET P.currentwp = NULL, P.score = ($score + 1), P.duration = (extract (epoch from now() - starttime)/60)::integer
              WHERE P.hunt = $hunt_id, P.team = $team"); // TODO: Set rank
              // duration set in minutes
            $update_query->execute();

        // Not last way point -- give next clue
        else
        {
            $results['status'] = 'correct';

            $update_query = $STH->prepare("UPDATE TreasureHunt.Participates
              SET currentwp = ($currentwp + 1), score = ($score + 1)
              WHERE hunt = $hunt_id, team = $team");
            $update_query->execute();

            $next_clue = $STH->prepare("SELECT clue FROM TreasureHunt.Waypoint WHERE hunt = $hunt_id");
            $next_clue->execute();
            $next_clue->setFetchMode(PDO::FETCH_ASSOC);
            $clue = $next_clue->fetch();

            $results['clue'] = $clue;
        }
    }

    else
    {
        $results['status'] = 'incorrect';

        // code given is incorrect
        // still attempt to store a visit attempt, but marked as incorrect, give appropriate feedback
    }

    // In both cases (fail and completed waypoint) visit should be saved with current timestamp

    // See if the entire hunt is finished
    // $update_hunt_status = $STH=>prepare("UPDATE TreasureHunt.Hunt /**/")

    return $results;

/* ----------------------------------------------------------------------------------------------------- */



  //   if ($code != $query_three) {
  //       // Wrong code - could also check whether the code is for another waypoint)
  //       return array (
  //           'status'=>'invalid'
  //       );
  //   } else { //test if last waypoint, test rank

		// if ($currentWP_num = $num_waypoints) { // Tests if last waypoint, no clue returned
		// 	return array(
  //           'status'=>'correct',
  //           'rank'=>$rank,
  //           'score'=>$score,
  //       );

		// }
		// $query = "SELECT clue FROM TreasureHunt.Waypoint WHERE hunt = $hunt AND num = ($currentWP_num + 1)"; //Gets next clue
		// $clue = pg_query($conn, $query);
		// return array(
  //           'status'=>'correct',
  //           'rank'=>$rank,
  //           'score'=>$score,
  //           'clue'=>$clue
  //       );
  // }
}

function getUserStatistics($user)
{
    $STH = connect();

    $queryStats = $STH->prepare("SELECT * FROM TreasureHunt.getUserStatistics(?);");
    $queryStats->bindParam(1, $user, PDO::PARAM_STR);
    $queryStats->execute();
    $queryStats->setFetchMode(PDO::FETCH_ASSOC);
    $results = $queryStats->fetchAll();
    return $results;
}

function resetDatabase()
{

  $schema = file_get_contents('./TreasureHuntSchema.sql');
  $procedures = file_get_contents('./TreasureHuntProcedures.sql');
  $data = file_get_contents('./TreasureHuntExampleData.sql');

  $STH = connect();

  $STH->beginTransaction();

  $STH->exec("$schema");
  $STH->exec("$procedures");
  $STH->exec("$data");

  $STH->commit();

  // $query = $STH->prepare("SELECT treasurehunt.resetDatabase();");

  // $query->execute;

}
?>