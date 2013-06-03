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

The specifying of `TreasureHunt.` before each domain was also critical. The current schema, as obtained from piazza, creates all of the domains for the project in the public schema.  This has the effect of producing an error if the public schema does not exist before running the sql schema file. Thus the `TreasureHunt.` prefix was required for the appropriate creation of the schema.

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

##Extension - Option 3: Database Abstraction Layer and Security

###Stored Procedures
The project was initially undertaken without using stored procedures.  It was however still in the early stages of the project when the decision to migrate to using stored procedures was made.  Most of the problems encountered were transforming `IF - ELSE IF - ELSE` statements into sql functions.  This was overcome through using postgres variable assignment, and internal control structures.

###Limited User Implementation
A limited user access account was also required for the project extension.  It was identified that this could be implemented through two way.  Either allowing access to individual tables, views, and functions in the database schema, or though the utilisation of `EXTERNAL SECURITY DEFINER` prefaced with either `STABLE` or `VOLATILE` depending on the nature of the function. The latter option was selected for ease of implementation and maintenance. The sql code for the creation of the user account was stored in the `TreasureHunt.sql` file so that the user account would be created on every instance of the schema creation.

##Extension - Option 2: FRAT Player Analysis

###FRAT statistics
A feature to provide relative statistics to a user when compared to the rest of the userbase, as opposed to the absolute statistics in the original schema

###FRAT Quintile Analysis Method
Users were ranked on Frequency, Recency and Amount separately. These ranks were then multiplied by 5 and divided by the number of users, giving a result ranging from 1 to 5 where 5 represents the top quintile of players and 1 represents the bottom quintile. Ranking ensures that even users who have no completed a hunt still get a score and thus avoids potential null cases.

###FRAT Player Type Method
After casting the start dates (of each hunt the user participates in) to days of the week, a case statement catches the weekends and sets them to -1 while the weekdays are +1, the sum of all such days is then either negative (more weekends than weekdays) or positive (more weekdays than weekends) or 0 (no hunts or even distribution number).

