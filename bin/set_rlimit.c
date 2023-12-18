#include <stdio.h>
#include <stdlib.h>
#include <sys/resource.h>
#include <errno.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <soft_limit> <hard_limit>\n", argv[0]);
        return 1;
    }

    struct rlimit limit;
    rlim_t soft_limit = strtoul(argv[1], NULL, 10);
    rlim_t hard_limit = strtoul(argv[2], NULL, 10);

    // Get the current limit
    if (getrlimit(RLIMIT_NOFILE, &limit) != 0) {
        perror("getrlimit");
        return 1;
    }

    printf("Current limits -> Soft limit: %ld, Hard limit: %ld\n", limit.rlim_cur, limit.rlim_max);

    // Set the new limits
    limit.rlim_cur = soft_limit;
    limit.rlim_max = hard_limit;

    if (setrlimit(RLIMIT_NOFILE, &limit) != 0) {
        perror("setrlimit");
        return 1;
    }

    // Verify the new limit
    if (getrlimit(RLIMIT_NOFILE, &limit) != 0) {
        perror("getrlimit");
        return 1;
    }

    printf("New limits -> Soft limit: %ld, Hard limit: %ld\n", limit.rlim_cur, limit.rlim_max);

    return 0;
}
