import csv
import sys

def main(path):
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    if not rows:
        print("No data")
        return

    print("KPI summary")
    for row in rows:
        name = row.get("metric")
        value = row.get("value")
        print(f"- {name}: {value}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python report_summary.py kpis.csv")
        sys.exit(1)
    main(sys.argv[1])
