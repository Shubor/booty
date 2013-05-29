<?php
/**
 * Web page to get details of a specific hunt
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();
?>
<h1>Hunt Status</h1>
<?php
try {
    $hunt = getHuntStatus($_SESSION['player']);
    if($hunt['status']=='active') {
        echo '<table class="table">';
        echo '<tr><td><b>Hunt Name</b></td> <td>',$hunt['name'],'</td></tr>';
        echo '<tr><td><b>Playing in Team</b></td> <td>',$hunt['team'],'</td></tr>';
        echo '<tr><td><b>Started</b></td> <td>',$hunt['start_time'],'</td></tr>';
        echo '<tr><td><b>Time Elapsed</b></td> <td>',$hunt['elapsed'],'</td></tr>';
        echo '<tr><td><b>Current Score</b></td> <td>',$hunt['score'],'</td></tr>';
        echo '<tr><td><b>Completed Waypoints</b></td> <td>',$hunt['waypoint_count'],'</td></tr>';
        echo '<tr><td><b>Next Waypoint\'s clue</b></td> <td><p>',$hunt['clue'],'</p></ br>';
        echo '<form class="form-inline" action="validate.php" id="verify" method="post">
                <input type=text name="vcode" class="input" placeholder="Verification Code">
                <button type="submit" class="btn">Verify</button>
        </form></td>';
        echo '</tr>';
        echo '</table>';
    } else if ($hunt['status']=='complete') {
        echo '<table class="table">';
        echo '<tr><td><b>Hunt Name</b></td> <td>',$hunt['name'],'</td></tr>';
        echo '<tr><td><b>Playing in Team</b></td> <td>',$hunt['team'],'</td></tr>';
        echo '<tr><td><b>Started</b></td> <td>',$hunt['start_time'],'</td></tr>';
        echo '<tr><td><b>Final Score</b></td> <td>',$hunt['score'],'</td></tr>';
        echo '</table>';
    } else {
        print_r($hunt);
        echo 'No hunt history.';
    }
} catch (Exception $e) {
    echo 'Cannot get current hunt status';
}
htmlFoot();
?>
