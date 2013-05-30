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
    echo '<table class="table table-hover">';
    echo '<tr><td><b>Name</b></td> <td style="text-align:right">',$hunt['name'],'</td></tr>';
    echo '<tr><td><b>Description</b></td> <td style="text-align:right">',$hunt['descrip'],'</td></tr>';
    echo '<tr><td><b>Start Time</b></td> <td style="text-align:right">',$hunt['start'],'</td></tr>';
    echo '<tr><td><b>Distance</b></td> <td style="text-align:right">',$hunt['distance'],'</td></tr>';
    echo '<tr><td><b>Teams</b></td> <td style="text-align:right">',$hunt['nteams'],'</td></tr>';
    echo '<tr><td><b>Waypoints</b></td> <td style="text-align:right">',$hunt['n_wp'],'</td></tr>';
    echo '</table>';
} catch (Exception $e) {
    echo 'Cannot get hunt details';
    echo $e;
}
htmlFoot();
?>
