#!/usr/bin/env python3
"""Score a job description against criteria.yaml"""

import sys
import yaml
import re

def load_criteria(path):
    with open(path) as f:
        return yaml.safe_load(f) or {}

def score_job(text, criteria):
    text_lower = text.lower()
    score = 0
    reasons = []
    warnings = []

    # Title keyword match (max 25 points)
    title_kw = criteria.get('title_keywords', [])
    title_hits = [kw for kw in title_kw if kw.lower() in text_lower]
    if title_hits:
        pts = min(25, len(title_hits) * 8)
        score += pts
        reasons.append(f"+{pts} title keywords: {', '.join(title_hits)}")

    # Exclude keyword penalty (-50 each, hard penalty)
    exclude_kw = criteria.get('exclude_keywords', [])
    exclude_hits = [kw for kw in exclude_kw if kw.lower() in text_lower]
    if exclude_hits:
        penalty = len(exclude_hits) * 50
        score -= penalty
        warnings.append(f"-{penalty} EXCLUDE keywords: {', '.join(exclude_hits)}")

    # Stack must_have (max 25 points)
    stack = criteria.get('stack', {})
    must_have = stack.get('must_have', [])
    must_hits = [s for s in must_have if s.lower() in text_lower]
    if must_hits:
        pts = min(25, len(must_hits) * 13)
        score += pts
        reasons.append(f"+{pts} must-have stack: {', '.join(must_hits)}")
    else:
        score -= 20
        warnings.append("-20 missing must-have stack (ruby/rails)")

    # Stack strong_match (max 15 points)
    strong = stack.get('strong_match', [])
    strong_hits = [s for s in strong if s.lower() in text_lower]
    if strong_hits:
        pts = min(15, len(strong_hits) * 3)
        score += pts
        reasons.append(f"+{pts} strong match: {', '.join(strong_hits)}")

    # Stack nice_to_have (max 10 points)
    nice = stack.get('nice_to_have', [])
    nice_hits = [s for s in nice if s.lower() in text_lower]
    if nice_hits:
        pts = min(10, len(nice_hits) * 2)
        score += pts
        reasons.append(f"+{pts} nice-to-have: {', '.join(nice_hits)}")

    # Location match (max 10 points)
    locations = criteria.get('location', [])
    loc_hits = [loc for loc in locations if loc.lower() in text_lower]
    if loc_hits:
        pts = min(10, len(loc_hits) * 3)
        score += pts
        reasons.append(f"+{pts} location: {', '.join(loc_hits)}")

    # Contract type (max 5 points)
    contracts = criteria.get('contract', [])
    contract_hits = [c for c in contracts if c.lower() in text_lower]
    if contract_hits:
        score += 5
        reasons.append(f"+5 contract: {', '.join(contract_hits)}")

    # Salary detection (max 10 points)
    salary_conf = criteria.get('salary', {})
    min_pln = salary_conf.get('min_pln_monthly', 0)
    min_eur = salary_conf.get('min_eur_yearly', 0)

    # Try to find PLN salary
    pln_match = re.findall(r'(\d[\d\s]*\d)\s*(?:-|–|to)\s*(\d[\d\s]*\d)\s*(?:PLN|pln|zł)', text)
    if pln_match:
        try:
            high = int(pln_match[0][1].replace(' ', ''))
            if high >= min_pln:
                score += 10
                reasons.append(f"+10 salary in range (PLN)")
            else:
                warnings.append(f"salary below minimum ({high} < {min_pln} PLN)")
        except ValueError:
            pass

    # EUR salary
    eur_match = re.findall(r'€\s*(\d[\d\s,]*\d)', text)
    if eur_match:
        try:
            val = int(eur_match[0].replace(' ', '').replace(',', ''))
            if val >= min_eur:
                score += 10
                reasons.append(f"+10 salary in range (EUR)")
        except ValueError:
            pass

    # Dealbreaker check
    dealbreakers = criteria.get('dealbreakers', [])
    db_hits = [db for db in dealbreakers if db.lower() in text_lower]
    if db_hits:
        score -= 100
        warnings.append(f"-100 DEALBREAKER: {', '.join(db_hits)}")

    # Blacklist check
    bl_recruiters = criteria.get('blacklist_recruiters', []) or []
    bl_companies = criteria.get('blacklist_companies', []) or []
    for bl in bl_recruiters + bl_companies:
        if bl.lower() in text_lower:
            score -= 100
            warnings.append(f"-100 BLACKLISTED: {bl}")

    # Watchlist bonus
    watchlist = criteria.get('watchlist', []) or []
    wl_hits = [w for w in watchlist if w.lower() in text_lower]
    if wl_hits:
        score += 15
        reasons.append(f"+15 WATCHLIST: {', '.join(wl_hits)}")

    # Clamp to 0-100
    score = max(0, min(100, score))

    return score, reasons, warnings

def main():
    if len(sys.argv) < 2:
        print("Usage: scorer.py <criteria.yaml> < job_description")
        sys.exit(1)

    criteria_path = sys.argv[1]
    criteria = load_criteria(criteria_path)
    text = sys.stdin.read()

    score, reasons, warnings = score_job(text, criteria)

    # Grade
    if score >= 80:
        grade = "A"
    elif score >= 60:
        grade = "B"
    elif score >= 40:
        grade = "C"
    elif score >= 20:
        grade = "D"
    else:
        grade = "F"

    print(f"Score: {score}/100 (Grade: {grade})")
    print("")
    if reasons:
        print("Matches:")
        for r in reasons:
            print(f"  {r}")
    if warnings:
        print("")
        print("Warnings:")
        for w in warnings:
            print(f"  {w}")

if __name__ == '__main__':
    main()
