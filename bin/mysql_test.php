<?php
# Taken from https://gist.github.com/M165437/421cd2d23e53a111541a483971f7368b
# Fill our vars and run on cli
# $ php -f db-connect-test.php
$dbname = 'name';
$dbuser = 'user';
$dbpass = 'pass';
$dbhost = 'host';
$link = mysqli_connect($dbhost, $dbuser, $dbpass) or die("Unable to Connect to '$dbhost'");
mysqli_select_db($link, $dbname) or die("Could not open the db '$dbname'");
$test_query = "SHOW TABLES FROM $dbname";
$result = mysqli_query($link, $test_query);
$tblCnt = 0;
while($tbl = mysqli_fetch_array($result)) {
  $tblCnt++;
  #echo $tbl[0]."<br />\n";
}
if (!$tblCnt) {
  echo "There are no tables<br />\n";
} else {
  echo "There are $tblCnt tables<br />\n";
}

?>