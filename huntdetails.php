<?php
/**
 * Web page to display information about a specific current hunt
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();
?>
<h1>Hunt Details</h1>
<?php
try {
    $hunt = getHuntDetails($_GET['hunt']);
    echo '<table class="table">';
    echo '<tr><td><b>Name</b></td> <td>',$hunt['name'],'</td></tr>';
    echo '<tr><td><b>Description</b></td> <td>',$hunt['descrip'],'</td></tr>';
    echo '<tr><td><b>Start Time</b></td> <td>',$hunt['start'],'</td></tr>';
    echo '<tr><td><b>Distance</b></td> <td>',$hunt['distance'],'</td></tr>';
    echo '<tr><td><b>Teams</b></td> <td>',$hunt['nteams'],'</td></tr>';
    echo '<tr><td><b>Waypoints</b></td> <td>',$hunt['n_wp'],'</td></tr>';
    echo '</table>';
} catch (Exception $e) {
    echo 'Cannot get hunt details';
}
htmlFoot();
?>
