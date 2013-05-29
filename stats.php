<?php
/**
 * Home page giving details of a specific user
 */
require_once('include/common.php');
require_once('include/database.php');
startValidSession();
htmlHead();
?>
<h1>Home</h1>
<?php
try {
    $details = getUserDetails($_SESSION['player']);
    echo '<table class="table">';
    echo '<tr><td><b>Name</b></td> <td>',$details['name'],'</td></tr>';
    echo '<tr><td><b>Address</b></td> <td>',$details['address'],'</td></tr>';
    echo '<tr><td><b>Current Team</b></td> <td>',$details['team'],'</td></tr>';
    echo '<tr><td><b>Hunts Played</b></td> <td>',$details['nhunts'],'</td></tr>';
    echo '<tr><td><b>Badges</b></td> <td>';
    foreach($details['badges'] as $badge) {
        echo '<span class="badge" title="',$badge['descrip'],'">',$badge['name'],'</span><br />';
    }
    echo '</td></tr>';
    echo '</table>';

    // echo '<h2>Name</h2>',$details['name'];
    // echo '<h2>Address</h2>',$details['address'];
    // echo '<h2>Current team</h2>',$details['team'];
    // echo '<h2>Hunts played</h2> ',$details['nhunts'];
    // echo '<h2>Badges</h2>';
    // foreach($details['badges'] as $badge) {
    //     echo '<span class="badge" title="',$badge['desc'],'">',$badge['name'],'</span><br />';
    // }

} catch (Exception $e) {
    echo 'Cannot get user details';
    echo $e;
}
htmlFoot();
?>