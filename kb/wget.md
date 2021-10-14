# Archive a Site
```
wget -w 10 -P mirror --cut-dirs=2 \
        --page-requisites \
        --adjust-extension \
        --span-hosts \
        --convert-links \
        --restrict-file-names=windows \
        --no-parent \
        https://google.com
# -nH \ # No host
# -w 10 \ # Wait 10 seconds between requests.
# -P mirror \ # Destination directory
#--page-requisites \ # Get all assets/elements (CSS/JS/images).
#     --adjust-extension \ # Save files with .html on the end.
#     --span-hosts \ # Include necessary assets from offsite as well.
#     --convert-links \ # Update links to still work in the static version.
#     --restrict-file-names=windows \ # Modify filenames to work in Windows as well.
#     --domains yoursite.com \ # Do not follow links outside this domain.
#     --no-parent \ # Don't follow links outside the directory you pass in.
#     https://www.google.com
```