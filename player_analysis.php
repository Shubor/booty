<?php
/**
 * 'Player Analysis' page giving a report about various player statistics
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();

echo '<h1>Quintile Statistics for ',$_SESSION['player'],'</h1>';
try {
    $details = getUserFratFrequency($_SESSION['player']);
    echo '<table class="table table-hover">';
    foreach($details as $stat) {
        $plode = explode("_", $stat['stat_name']);
        $plode = implode(" ", $plode);
        echo '<tr><td><b>',ucwords($plode),'</b></td> <td style="text-align:right">',$stat['stat_value'],'</td></tr>';
    }
    echo '</td></tr>';
    echo '</table>';

} catch (Exception $e) {
    echo 'Cannot get user statistics';
    echo $e;
}

try {
    $details = getUserFratRecency($_SESSION['player']);
    echo '<table class="table table-hover">';
    foreach($details as $stat) {
        $plode = explode("_", $stat['stat_name']);
        $plode = implode(" ", $plode);
        echo '<tr><td><b>',ucwords($plode),'</b></td> <td style="text-align:right">',$stat['stat_value'],'</td></tr>';
    }
    echo '</td></tr>';
    echo '</table>';

} catch (Exception $e) {
    echo 'Cannot get user statistics';
    echo $e;
}

try {
    $details = getUserFratAmount($_SESSION['player']);
    echo '<table class="table table-hover">';
    foreach($details as $stat) {
        $plode = explode("_", $stat['stat_name']);
        $plode = implode(" ", $plode);
        echo '<tr><td><b>',ucwords($plode),'</b></td> <td style="text-align:right">',$stat['stat_value'],'</td></tr>';
    }
    echo '</td></tr>';
    echo '</table>';

} catch (Exception $e) {
    echo 'Cannot get user statistics';
    echo $e;
}

try {
    $details = getUserFratType($_SESSION['player']);
    echo '<table class="table table-hover">';
    foreach($details as $stat) {
        $plode = explode("_", $stat['stat_name']);
        $plode = implode(" ", $plode);
        echo '<tr><td><b>',ucwords($plode),'</b></td> <td style="text-align:right">',$stat['stat_value'],'</td></tr>';
    }
    echo '</td></tr>';
    echo '</table>';

} catch (Exception $e) {
    echo 'Cannot get user statistics';
    echo $e;
}

htmlFoot();
?>