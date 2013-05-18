<?php
/**
 * Login page
 * Users visiting the site via index.php are redirected to this login page, where
 * they must enter their username and password. Successful login starts a new session and
 * redirection to main content in index.php. Query parameters are preserved so that a user
 * can use QR codes to go to confirmation page after logging in.
 */
require_once('include/database.php');
/**
 * Clean up after user logs out
 */
function log_out() {
    $_SESSION['player'] = '';
    $_SESSION['logged_in'] = false;
}

/**
 * Process a user's login details
 * @param string $name username
 * @param string $pass password
 * @return boolean true if login details are correct, else false
 */
function log_in($name, $pass) {
    $is_valid = checkLogin($name,$pass);
    if ($is_valid) {
        $_SESSION['logged_in'] = true;
        $_SESSION['player'] = $name;
    }
    return $is_valid;
}

// Start session from scratch
session_start();
log_out();

// Messages to display to user if returning to page
$message = '';

// Query string parameters to preserve across login process
$qstring = http_build_query($_GET);
if (!empty($qstring)) {
    $qstring = '?'.$qstring;
}

//
// Process login details (must be POST data) and redirect to main site if correct
//
if(!isset($_POST['user']) || !isset($_POST['pass'])) {
    // Invalid data supplied, so don't return any message (maybe log the event though)
} else if (log_in($_POST['user'], $_POST['pass'])) {
    // Success so redirect to desired page
    $target = 'index.php'.$qstring; // Pass on query parameters
    header('Location:'.$target);
    exit;
} else {
    $message='<div class="alert alert-error">Login details incorrect. Please try again.</div>';
}

//
// If user hasn't submitted login details, or if they are incorrect, they will see
// the following page.
//

?>
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>Treasure Hunt Login</title>
    <link rel="stylesheet" type="text/css" href="css/main.css" />
    <style type="text/css">
      body {
        padding-top: 60px;
        padding-bottom: 40px;
      }
    </style>
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body>
    <div class="navbar navbar-inverse navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container">
          <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="brand" href="index.php">booty</a>
        </div>
      </div>
    </div>
    <div id="wrapper">
    <div id="login">
        <?php echo $message; ?>
        <form class="form-inline" action="<?php echo 'login.php',$qstring; ?>" id="loginform" method="post">
            <input type=text name="user" class="input-small" placeholder="Name">
            <input type=password name="pass" class="input-small" placeholder="Password">
            <button type="submit" class="btn">Sign in</button>
        </form>
    </div>
    </div>
    </div>
    <div id="footer">
</div>
</body>
</html>