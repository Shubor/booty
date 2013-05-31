Part 3: Database Programming
===================================

*Shu-Han Bor, James Phillips, Alan Robertson*

## PDO

The [PDO Manual](http://php.net/manual/en/book.pdo.php) proved to be an invaluable resource, while we attempted to find the different functions to match our needs.

## Date/time queries

Obtaining timestamps of the correct format proved to be fiddly, and the issue was only further complicated, when the difference between two timestamps needed to be obtained. In order to get rid of timezones we used:

    NOW()::timestamp without time zone

Queries requiring output in minutes or hours and minutes, was able to be obtained using extract.
e.g.

    (extract (epoch from (now() - starttime))/3600)::integer
          || ' hours and ' || (extract (epoch from (now() - starttime))/60)::integer%60
          || ' minute(s)'


## Protecting from SQL Injection

This was achieved by querying using only bound paramaters.

    $query = $STH->prepare("SELECT * FROM TreasureHunt.checkLogin(?,?);");
    $query->bindValue(1, $name, PDO::PARAM_INT);
    $query->bindValue(2, $pass, PDO::PARAM_STR);
    $query->execute();

## Stored Procedures

Using `BEGIN` in postgres is equivalent to transactions. Therefore, using these stored procedures, the validateVisit function in database.php is implicitly in a transaction.

## Managing Code

As a group, we decided to use GitHub to keep everyone's code up to date (as long as we remembered to `git pull` and `git push` - obviously. This made sure we had backups of our code, and that no one would accidentally write over someone else's changes. Thus, keeping our code up to date was very simple.

## Fixing SQL Schema

The downloaded SQL schema as not immediately compatible with our requirements, and also produced errors when sample data was introduced. Therefore, these problems needed to be fixed. Fortunately, most were simple fixes in table referencing and simply required `TreasureHunt.` specified before the name of the required table.

## Testing of Verification Code

In order to avoid having to reload the database everytime (since testing the verification code for a team's hunt, would permanently modify the database), we created a resetDatabase function that would do this for us.

    function resetDatabase()
	{
        $schema = file_get_contents('./TreasureHuntSchema.sql');
        $procedures = file_get_contents('./TreasureHuntProcedures.sql');
        $data = file_get_contents('./TreasureHuntExampleData.sql');

        $STH = connect();

        try
        {
            $STH->beginTransaction();

            $STH->exec("$schema");
            $STH->exec("$procedures");
            $STH->exec("$data");

            $STH->commit();
        }
        catch (Exception $e)
        {
            $STH->rollBack();
        }

	}

And included it as an extra button in the menu of our website, for easy access while testing.