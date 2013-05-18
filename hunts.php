<?php
/**
 * Web page to display available hunts
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();
?>
<h1>Browse Hunts</h1>
<?php
try {
    $hunts = getAvailableHunts();
    echo '<table>';
    echo '<thead>';
    echo '<tr><th>Name</th><th>Starts</th><th>Distance</th><th>Waypoints</th></tr>';
    echo '</thead>';
    echo '<tbody>';
    foreach($hunts as $hunt) {
        echo '<tr><td><a href="huntdetails.php?hunt=',$hunt['id'],'">',$hunt['name'],'</a></td>',
                '<td>',$hunt['start'],'</td><td>',$hunt['distance'],'</td>',
                '<td>',$hunt['nwaypoints'],'</td></tr>';
    }
    echo '</tbody>';
    echo '</table>';
} catch (Exception $e) {
        echo 'Cannot get available hunts';
}
htmlFoot();
?>
