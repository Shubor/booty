<?php
/**
 * Web page to confirm whether a valid waypoint has been visited
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();
?>
<h1>Checkpoint Visit</h1>
<?php
if (!isset($_REQUEST['vcode'])) {
    echo '<p> Enter a validation code to confirm your waypoint visit </p>';
    echo '<form class="form-inline" action="validate.php" id="verify" method="post">
                <input type=text name="vcode" class="input" placeholder="Verification Code">
                <button type="submit" class="btn">Verify</button>
        </form>';
} else {
    try {
        $visit = validateVisit($_SESSION['player'],$_REQUEST['vcode']);
        if($visit['status'] == 'complete')
        {
            echo '<h2>Congratulations!</h2> You\'ve validated a visit to your last waypoint!';
            echo '<p>Your team has finished with a final score of ',$visit['score'],'</p>';
        }
        else if($visit['status'] == 'correct')
        {
            echo '<h2>Congratulations!</h2> You\'ve validated a visit to your next waypoint!';
            echo '<p>Your team\'s score is now ',$visit['score'],'</p>';
            echo '<h2>Next Waypoint\'s clue</h2> <quote>',$visit['clue'],'</quote>';
            echo '<form class="form-inline" action="validate.php" id="verify" method="post">
                <input type=text name="vcode" class="input" placeholder="Verification Code">
                <button type="submit" class="btn">Verify</button>
            </form>';
        }
        else
        {
            echo '<h2>Wrong verification code!</h2> (Out of order, or not in this hunt)';
        }
    } catch (Exception $e) {
            echo 'Couldn\'t validate visit status';
    }
}
htmlFoot();
?>
