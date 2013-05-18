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
    echo '<tr><td><b>Description</b></td> <td>',$hunt['desc'],'</td></tr>';
    echo '<tr><td><b>Start Time</b></td> <td>',$hunt['start'],'</td></tr>';
    echo '<tr><td><b>Distance</b></td> <td>',$hunt['distance'],'</td></tr>';
    echo '<tr><td><b>Teams</b></td> <td>',$hunt['nteams'],'</td></tr>';
    echo '<tr><td><b>Waypoints</b></td> <td>',$hunt['n_wp'],'</td></tr>';
    echo '</table>'
    // echo '<h2>Name</h2>',$hunt['name'];
    // echo '<h2>Description</h2> ',$hunt['desc'];
    // echo '<h2>Start Time</h2> ',$hunt['start'];
    // echo '<h2>Distance</h2> ',$hunt['distance'];
    // echo '<h2>Teams</h2> ',$hunt['nteams'];
    // echo '<h2>Waypoints</h2> ',$hunt['n_wp'];
    // TODO: Maybe show a map of the bounding box of all the waypoints
} catch (Exception $e) {
    echo 'Cannot get hunt details';
}
htmlFoot();
?>
