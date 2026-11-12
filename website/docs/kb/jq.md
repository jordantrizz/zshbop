---
title: Jq
description: "Using the @tsv filter has much to recommend it, mainly because it handles numerous edge cases in a standard way:"
---

<!-- BEGIN GENERATED: kb-jq -->
* https://lzone.de/cheat-sheet/jq

## jq + tsv aka tables
Using the @tsv filter has much to recommend it, mainly because it handles numerous "edge cases" in a standard way:

```.[] | [.id, .name] | @tsv```

Adding the headers can be done like so:

```jq -r '["ID","NAME"], ["--","------"], (.[] | [.id, .name]) | @tsv'```

---

*Generated from [`kb/jq.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/jq.md) by
`npm run gen:kb`. The shell shows the same article with `kb jq`.*

<!-- END GENERATED: kb-jq -->
