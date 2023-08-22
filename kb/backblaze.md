# Delete all files in B2 Bucket
1. Go into Lifecycle Custom Settings
2. Leave "fileNamePrefix" blank (or specify the sub folder you want to delete all the files in).
3. Specify "daysFromUploadingToHiding" to be 1
4.Specify "daysFromHidingToDeleting" to be 1