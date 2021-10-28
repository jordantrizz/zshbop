<?php
$ulimit=`ulimit -a`;
echo "<pre>$ulimit</pre>";

// phpmemory.php

$memlimit = 256;
print 'Expected memory limit ' . $memlimit . 'MB <br />';

$memory_mb = round(memory_get_usage() /1024/1024 , 2);
print 'Base  -> ' . memory_get_usage() . ' (' . $memory_mb . ' MB)' . ' <br /> &ensp; <br />';

$pattern = str_repeat("0123456789", 1000);
$fill = str_repeat($pattern, 1);
$counter = 1000;
while ( $counter <= 27000 ) {
    unset($fill);
    $memory_mb = round(memory_get_usage() /1024/1024 , 2);
    print 'Clear -> ' . memory_get_usage() . ' (' . $memory_mb . ' MB) <br />';

    print $counter . ' x 10000 chars -> ' ;
    $fill = str_repeat($pattern, $counter);
    $memory_mb = round(memory_get_usage() /1024/1024 , 2);
    print  memory_get_usage() . ' (' . $memory_mb . ' MB)'. ' [' . $memory_pct = round($memory_mb /
$memlimit *100 , 1) . ' percent]<br />';
    $counter = $counter + 500;
}
print '<br />If you can see this, the server can allocate something close to 256mb';
?>
