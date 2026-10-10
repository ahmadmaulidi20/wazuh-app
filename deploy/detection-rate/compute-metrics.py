#!/usr/bin/env python3
"""compute-metrics.py — Hitung metrik deteksi (TP/FN/FP/TN, DR, FPR, Precision, F1)
dari CSV hasil eksperimen.

CSV format (per baris):
  skenario,threshold,intensitas,serangan_terjadi(0/1),alert_muncul(0/1)
Aturan labeling:
  serangan_terjadi=1 & alert_muncul=1 -> TP
  serangan_terjadi=1 & alert_muncul=0 -> FN
  serangan_terjadi=0 & alert_muncul=1 -> FP
  serangan_terjadi=0 & alert_muncul=0 -> TN

Penggunaan: python3 compute-metrics.py <results.csv>
"""
import sys
import csv
from collections import defaultdict

def main():
    if len(sys.argv) < 2:
        print("usage: compute-metrics.py <results.csv>")
        sys.exit(1)

    path = sys.argv[1]
    rows = []
    with open(path, newline="") as f:
        for r in csv.DictReader(f):
            rows.append({
                "skenario": r["skenario"],
                "threshold": r["threshold"],
                "intensitas": r["intensitas"],
                "attack": int(r["serangan_terjadi"]),
                "alert": int(r["alert_muncul"]),
            })

    groups = defaultdict(list)
    for r in rows:
        groups[r["skenario"]].append(r)

    header = "skenario,threshold,n,TP,FN,FP,TN,DR,FPR,Precision,F1"
    print(header)
    for skenario, items in groups.items():
        TP = sum(1 for r in items if r["attack"] and r["alert"])
        FN = sum(1 for r in items if r["attack"] and not r["alert"])
        FP = sum(1 for r in items if not r["attack"] and r["alert"])
        TN = sum(1 for r in items if not r["attack"] and not r["alert"])
        n = len(items)

        dr = TP / (TP + FN) if (TP + FN) else 0.0
        fpr = FP / (FP + TN) if (FP + TN) else 0.0
        prec = TP / (TP + FP) if (TP + FP) else 0.0
        f1 = 2 * prec * dr / (prec + dr) if (prec + dr) else 0.0
        print(f"{skenario},all,{n},{TP},{FN},{FP},{TN},{dr:.4f},{fpr:.4f},{prec:.4f},{f1:.4f}")

    print("\nDONE")

if __name__ == "__main__":
    main()