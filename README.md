# book-apps-benchmark (opds fork)

a fork of [kevin-s722/book-apps-benchmark](https://github.com/kevin-s722/book-apps-benchmark) to see how [microopds](https://github.com/XanderStrike/MicroOPDS) stacks

this is not a valid comparison, microopds generates one xml feed. the others are full applications with databases and web interfaces.

that said, a good app + opds can be enough

## results

| | 10K | 50K | 100K | 150K |
|---|---|---|---|---|
| **ingestion** | 0:02 | 0:13 | 0:27 | 0:41 |
| **idle ram** | 18 MB | 81 MB | 390 MB | 429 MB |
| **peak ram** | 19 MB | 82 MB | 391 MB | 455 MB |
| **peak cpu** | 37% | 67% | 63% | 66% |

for context, bookorbit (the next fastest) ingests 10K in 2:34 and idles at 285 MB. but it also gives you a web ui, search, users, reading progress — microopds gives you an opds feed and nothing else

idle ram scales ~2.9 MB per 1K books (all metadata in memory). that's the tradeoff for the tiny base footprint

[interactive dashboard](https://htmlpreview.github.io/?https://raw.githubusercontent.com/XanderStrike/book-apps-benchmark/refs/heads/main/results/comparison.html) with all apps

## running it

```bash
cd scripts
python3 generate_books.py 10000
./run_microopds_benchmark.sh 10K

# compare against reference data
python3 generate_comparison.py --reports-dir ../results ../reference
```

## what changed from upstream

- added `docker/microopds/` and `scripts/run_microopds_benchmark.sh`
- `monitor.py` now handles podman's stats format 
- [lightly modified microopds](https://github.com/XanderStrike/MicroOPDS/tree/benchmark) with `-defer-scan` and `-no-watch` flags -- it kept finishing scans before the monitor was ready

this was run on an M4 macbook pro with 16GB ram

all reference data and the original methodology are in the [upstream repo](https://github.com/kevin-s722/book-apps-benchmark)
