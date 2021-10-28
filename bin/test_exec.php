<?php
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "<h1>This is a test</h1>";
function exec_enabled() {
  $disabled = explode(',', ini_get('disable_functions'));
  return !in_array('exec', $disabled);
}
echo "<pre>exec_enabled?: ".exec_enabled()."</pre>";
echo "<pre>Date shell_exec: ".shell_exec('date')."</pre>";
echo "<pre>Date exec: ".exec('date')."</pre>";
?>
