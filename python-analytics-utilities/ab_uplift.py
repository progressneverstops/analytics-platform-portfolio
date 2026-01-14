import csv
import sys
from collections import defaultdict

def main(path):
    totals = defaultdict(int)
    converts = defaultdict(int)

    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            variant = row["variant"]
            totals[variant] += 1
            converts[variant] += int(row["converted"])

    for variant in sorted(totals):
        rate = converts[variant] / totals[variant]
        print(f"{variant}\t{rate:.3f}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python ab_uplift.py experiment_events.csv")
        sys.exit(1)
    main(sys.argv[1])
