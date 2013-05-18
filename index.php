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
    echo '<h2>Name</h2> ',$details['name'];
    echo '<h2>Address</h2>',$details['address'];
    echo '<h2>Current team</h2>',$details['team'];
    echo '<h2>Hunts played</h2> ',$details['nhunts'];
    echo '<h2>Badges</h2>';
    foreach($details['badges'] as $badge) {
        echo '<span class="badge" title="',$badge['desc'],'">',$badge['name'],'</span><br />';
    }
} catch (Exception $e) {
    echo 'Cannot get user details';
}
htmlFoot();
?>