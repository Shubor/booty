<?php
/**
 * Home page giving details of a specific user
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();

echo '<h1>Statistics for ',$_SESSION['player'],'</h1>';
try {
    $details = getUserStatistics($_SESSION['player']);
    echo '<table class="table table-hover">';
    foreach($details as $stat) {
        $plode = explode("_", $stat['stat_name']);
        $plode = implode(" ", $plode);
        echo '<tr><td><b>',ucwords($plode),'</b></td> <td style="text-align:right">',$stat['stat_value'],'</td></tr>';
    }
    echo '</td></tr>';
    echo '</table>';

    $deets = getCompletedHunts($_SESSION['player']);
    echo '<h3>Statistics for Hunt: ', $deets['huntname'], '</h3>';
    echo '<table class="table table-hover">';
    echo '<tr><td><b>Score</b></td> <td style="text-align:right">', $deets['score'], '</td></tr>';
    echo '<tr><td><b>Rank</b></td> <td style="text-align:right">', $deets['rank'], '</td></tr>';
    echo '<tr><td><b>Duration</b></td> <td style="text-align:right">', $deets['duration'], '</td></tr>';
    echo '</table>';

} catch (Exception $e) {
    echo 'Cannot get user statistics';
    echo $e;
}
htmlFoot();
?>