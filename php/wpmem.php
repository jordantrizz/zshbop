<?php
// Load WordPress environment
require_once __DIR__ . '/wp-load.php';

// Send HTML header so <pre> tags render correctly
header('Content-Type: text/html; charset=UTF-8');

// Begin <pre> for nice formatting in browser
echo "<pre>\n";

// Helper to print an ini setting
function print_setting($name) {
    $value = ini_get($name);
    printf("%-25s: %s\n",
        $name,
        ($value === false ? '(not set)' : $value)
    );
}

// 1) PHP ini settings for uploads
echo "=== PHP ini settings for file uploads ===\n";
print_setting('file_uploads');
print_setting('upload_max_filesize');
print_setting('post_max_size');
print_setting('memory_limit');
print_setting('max_execution_time');
print_setting('max_input_time');

echo "\n=== WordPress Memory Settings ===\n";
// 2) Raw values
printf("%-25s: %s\n",
    'WP_MEMORY_LIMIT',
    defined('WP_MEMORY_LIMIT') ? WP_MEMORY_LIMIT : '(not defined)'
);
printf("%-25s: %s\n",
    'WP_MAX_MEMORY_LIMIT',
    defined('WP_MAX_MEMORY_LIMIT') ? WP_MAX_MEMORY_LIMIT : '(not defined)'
);

// 3) Explanations
echo "\n=== What these WordPress settings do ===\n";
echo "WP_MEMORY_LIMIT:\n";
echo "  The max amount of PHP memory WordPress will try to use for front-end operations\n";
echo "  (themes, plugins, media processing). It's a soft target—it cannot exceed PHP's\n";
echo "  own memory_limit in php.ini.\n\n";

echo "WP_MAX_MEMORY_LIMIT:\n";
echo "  A higher memory ceiling for admin tasks: dashboard, cron jobs, updates,\n";
echo "  and other background processes. Again, bounded by php.ini's memory_limit.\n";

echo "\n=== Current memory usage ===\n";
echo sprintf("  %.2f MB\n", memory_get_usage(true) / 1024 / 1024);

// End </pre>
echo "</pre>\n";
?>