import csv
import sys
from collections import defaultdict

def main(path):
    counts = defaultdict(int)
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            counts[row["event_date"]] += 1

    for day in sorted(counts):
        print(f"{day}\t{counts[day]}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python kpi_rollup.py events.csv")
        sys.exit(1)
    main(sys.argv[1])
