<?php
/**
 * debug-permissions.php
 *
 * Walks each directory, prints owner/group/perm/writability,
 * then prints PHP‐INI restrictions (open_basedir, disabled fns),
 * then attempts to write a test file.
 */
// Get the current working directory
$cwd = getcwd();

 // Arrays of paths to check
$targets = [
    'current' => $cwd,
    'oneback' => dirname($cwd),
    'home'    => getenv('HOME') ?: getenv('USERPROFILE'),
    'tmp'     => sys_get_temp_dir(),
];

// Check if we have wp-content/uploads exists
if ( is_dir($cwd . '/wp-content/uploads') ) {
    $targets['uploads'] = $cwd . '/wp-content/uploads';
}

echo "<pre>";

echo "==== PHP Permissions ====\n";
echo "Current working directory: $cwd\n";
echo "PHP version: " . PHP_VERSION . "\n";
echo "PHP SAPI: " . PHP_SAPI . "\n";
echo "User: " . get_current_user() . "\n";
echo "Group: " . (function_exists('posix_getgrgid') ? posix_getgrgid(posix_getegid())['name'] : 'N/A') . "\n";
echo "PHP user: " . (function_exists('posix_getpwuid') ? posix_getpwuid(posix_geteuid())['name'] : 'N/A') . "\n";
echo "PHP group: " . (function_exists('posix_getgrgid') ? posix_getgrgid(posix_getegid())['name'] : 'N/A') . "\n";
echo "PHP temp dir: " . sys_get_temp_dir() . "\n";
echo "PHP upload dir: " . ini_get('upload_tmp_dir') . "\n";
echo "=========================\n";
echo "Testing paths:\n";
foreach ($targets as $key => $target) {
    echo "  $key: $target\n";
}
echo "\n";

foreach ($targets as $key => $target) {
    // Check if the target is a directory
    echo "==== $key ====\n";
    if (!is_dir($target)) {
        echo "⛔ Target is not a directory or does not exist: $target\n";
        continue;
    } else {
        echo "✅ Target is a directory: $target\n";
    }

    echo "----\nChecking if $target is writable\n";
    if (!is_writable($target)) {
        echo "⛔ Target directory is not writable by PHP (file perms or open_basedir).\n";
    }

    $testFile = $target . '/perm_test_' . time() . '.txt';
    echo "----\nAttempting to write test file in $testFile\n";
    $written  = @file_put_contents($testFile, "Permission test\n");

    if ($written === false) {
        echo "⛔ Failed to write file. Last PHP error:\n";
        // Use print_r to show the last error but make it look different and nice
        $error = error_get_last();
        if ($error) {
            echo "  " . print_r($error, true);
        } else {
            echo "  No error reported.\n";
        }
    } else {
        echo "✅ Successfully wrote to $testFile\n";
        unlink($testFile);
        echo "🗑️  Test file removed.\n";
    }

    $info     = @stat($target);
    $perms    = substr(sprintf('%o', $info['mode']), -4);
    $owner    = posix_getpwuid($info['uid'])['name'] ?? $info['uid'];
    $group    = posix_getgrgid($info['gid'])['name'] ?? $info['gid'];
    $writable = is_writable($target) ? 'yes' : 'no';

    echo "----\nCheck if directory is a symlink\n";
    if (is_link($target)) {
        echo "✅ Target is a symlink\n";
        $target = readlink($target);
        echo "  Symlink target: $target\n";
    } else {
        echo "⛔ Target is not a symlink\n";
    }

    echo "Path:      $target\n";
    echo "  Owner:     $owner\n";
    echo "  Group:     $group\n";
    echo "  Perms:     $perms\n";
    echo "  Writable:  $writable\n\n";
    echo "========================================================\n";
    echo "========================================================\n";
    echo "\n";
}

// ──────────────────────────────────────────────────────────────────────────────
// 2. PHP‑INI restrictions section
echo "==== PHP INI Restrictions ====\n";

// 2a. open_basedir
$ob = ini_get('open_basedir');
echo "open_basedir = " . ($ob ?: '[none]') . "\n";
if ($ob) {
    $allowed = explode(PATH_SEPARATOR, $ob);
    // resolve realpath of target
    $real   = realpath($target) ?: $target;
    $inside = false;
    foreach ($allowed as $dir) {
        // trim trailing slash from allowed path for matching
        $dir = rtrim($dir, DIRECTORY_SEPARATOR);
        if (strpos($real, $dir) === 0) {
            $inside = true;
            break;
        }
    }
    echo "Target inside open_basedir? " . ($inside ? 'yes' : 'NO — writes will be blocked') . "\n";
}

// 2b. disabled functions
$disabled = ini_get('disable_functions');
echo "disable_functions = " . ($disabled ?: '[none]') . "\n";

// 2c. (optional) show disable_classes
if ($dc = ini_get('disable_classes')) {
    echo "disable_classes   = $dc\n";
}

// 2d. (optional) legacy safe_mode
if (version_compare(PHP_VERSION, '5.4.0', '<')) {
    echo "safe_mode         = " . ini_get('safe_mode') . "\n";
}

echo "\n";

echo "</pre>";