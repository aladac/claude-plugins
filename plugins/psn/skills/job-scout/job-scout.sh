#!/usr/bin/env bash
# Job Scout skill — multi-source job search aggregator
# Usage: bash job-scout.sh <command> [args...]
# Requires: gog (gmail), python3 (yaml/scoring), browse MCP (scraping)

set -euo pipefail

JOBS_DIR="$HOME/Projects/jobs"
LEADS_DIR="$JOBS_DIR/leads"
CRITERIA="$JOBS_DIR/criteria.yaml"
STATUS="$JOBS_DIR/status.yaml"
GMAIL_SKILL="$HOME/Projects/MVP/personality-plugin/skills/gmail/gmail.sh"
SCOUT_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON="$JOBS_DIR/.venv/bin/python"

mkdir -p "$LEADS_DIR"

usage() {
  cat <<'EOF'
Job Scout Commands:

  Scan
    scout                     Full scan across all sources
    scout --source <name>     Scan one source only
    inbox                     Check email for new job-related messages

  Analyze
    review <url>              Deep analysis of a specific job posting
    score <text>              Score job description text against criteria

  Manage
    track <company>           Add company to watchlist
    blacklist <name>          Add to recruiter/company blacklist
    pipeline                  Show application pipeline status
    status <url> <state>      Update pipeline status for a job

  Report
    report                    Summary of new leads since last scan
    leads                     List all lead files
    criteria                  Show current search criteria

Sources: gmail, nofluffjobs, justjoinit, rubyonremote, railsjobboard, hnhiring, bulldogjob, wttj
EOF
}

# === HELPERS ===

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

date_stamp() {
  date +"%Y-%m-%d"
}

update_last_scan() {
  local source="$1"
  local ts
  ts=$(timestamp)
  "$PYTHON" -c "
import yaml, sys
with open('$STATUS', 'r') as f:
    data = yaml.safe_load(f) or {}
data['last_scan'] = '$ts'
if 'last_scan_per_source' not in data:
    data['last_scan_per_source'] = {}
data['last_scan_per_source']['$source'] = '$ts'
with open('$STATUS', 'w') as f:
    yaml.dump(data, f, default_flow_style=False)
" 2>/dev/null || true
}

is_seen() {
  local url="$1"
  "$PYTHON" -c "
import yaml
with open('$STATUS', 'r') as f:
    data = yaml.safe_load(f) or {}
seen = data.get('seen_urls', []) or []
print('yes' if '$url' in seen else 'no')
" 2>/dev/null
}

mark_seen() {
  local url="$1"
  "$PYTHON" -c "
import yaml
with open('$STATUS', 'r') as f:
    data = yaml.safe_load(f) or {}
if 'seen_urls' not in data or data['seen_urls'] is None:
    data['seen_urls'] = []
if '$url' not in data['seen_urls']:
    data['seen_urls'].append('$url')
with open('$STATUS', 'w') as f:
    yaml.dump(data, f, default_flow_style=False)
" 2>/dev/null || true
}

# Score a job description against criteria
# Returns: score (0-100), reasons
score_text() {
  local text="$1"
  "$PYTHON" "$SCOUT_DIR/scorer.py" "$CRITERIA" <<< "$text"
}

# === SCANNERS ===

scan_gmail() {
  echo "=== Gmail Scan ==="
  local queries=(
    'subject:ruby OR subject:rails OR subject:"backend engineer" OR subject:"software engineer" newer_than:7d'
    'from:lever.co OR from:greenhouse.io OR from:greenhouse-mail.io OR from:ashbyhq.com newer_than:7d'
  )
  for q in "${queries[@]}"; do
    bash "$GMAIL_SKILL" search-all "$q" --max 10 2>/dev/null || true
  done
  update_last_scan "gmail"
  echo ""
}

scan_rubyonremote() {
  echo "=== RubyOnRemote ==="
  # Fetch the EU jobs page
  local url="https://rubyonremote.com/remote-ruby-on-rails-jobs-in-eu/"
  curl -sL "$url" 2>/dev/null | "$PYTHON" -c "
import sys, re, html

content = sys.stdin.read()

# Extract job listing blocks - look for job titles and companies
# RubyOnRemote uses structured HTML with job cards
listings = re.findall(r'<h[23][^>]*>(.*?)</h[23]>', content, re.DOTALL)
links = re.findall(r'href=\"(/remote-jobs/[^\"]+)\"', content)

seen = set()
for link in links[:20]:
    full_url = 'https://rubyonremote.com' + link
    if full_url not in seen:
        seen.add(full_url)
        # Clean up the path to get a readable name
        parts = link.replace('/remote-jobs/', '').replace('-', ' ').strip('/')
        print(f'{parts}')
        print(f'  {full_url}')
" 2>/dev/null || echo "  (fetch failed)"
  update_last_scan "rubyonremote"
  echo ""
}

scan_railsjobboard() {
  echo "=== Rails Job Board ==="
  curl -sL "https://jobs.rubyonrails.org/" 2>/dev/null | "$PYTHON" -c "
import sys, re

content = sys.stdin.read()

# Extract job links and titles
jobs = re.findall(r'<a[^>]*href=\"(/jobs/[^\"]+)\"[^>]*>(.*?)</a>', content, re.DOTALL)
seen = set()
for href, title in jobs[:15]:
    title = re.sub(r'<[^>]+>', '', title).strip()
    url = 'https://jobs.rubyonrails.org' + href
    if title and url not in seen and len(title) > 5:
        seen.add(url)
        print(f'{title}')
        print(f'  {url}')
" 2>/dev/null || echo "  (fetch failed)"
  update_last_scan "railsjobboard"
  echo ""
}

scan_hnhiring() {
  echo "=== HN Who's Hiring (Rails) ==="
  curl -sL "https://hnhiring.com/technologies/rails" 2>/dev/null | "$PYTHON" -c "
import sys, re

content = sys.stdin.read()

# Extract job entries
entries = re.findall(r'<div class=\"job[^\"]*\"[^>]*>(.*?)</div>', content, re.DOTALL)
# Fallback: look for links with job info
links = re.findall(r'href=\"(https://[^\"]+)\"[^>]*>([^<]+)</a>', content)

seen = set()
count = 0
for url, text in links:
    text = text.strip()
    if count >= 15:
        break
    if 'ycombinator' in url or 'hnhiring' in url:
        continue
    if url not in seen and len(text) > 5:
        seen.add(url)
        print(f'{text}')
        print(f'  {url}')
        count += 1
" 2>/dev/null || echo "  (fetch failed)"
  update_last_scan "hnhiring"
  echo ""
}

scan_nofluffjobs() {
  echo "=== NoFluffJobs ==="
  curl -sL "https://nofluffjobs.com/api/posting?criteria=requirement%3DRuby%20on%20Rails&criteria=seniority%3DSenior&criteria=city%3Dremote" 2>/dev/null | "$PYTHON" -c "
import sys, json

try:
    data = json.load(sys.stdin)
    postings = data.get('postings', [])
    ruby_kw = {'ruby', 'rails', 'ruby on rails'}
    seen_titles = set()
    count = 0
    for p in postings:
        if count >= 15:
            break
        title = p.get('title', '').lower()
        tech = p.get('technology', '').lower()
        reqs = ' '.join([r.get('value','').lower() for r in p.get('mustHave', p.get('requirements', {}).get('musts', []))]) if isinstance(p.get('mustHave', p.get('requirements', {}).get('musts', [])), list) else ''
        combined = f'{title} {tech} {reqs}'
        if not any(kw in combined for kw in ruby_kw):
            continue
        company = p.get('name', 'Unknown')
        # Dedup by company+title (NFJ lists per-voivodeship)
        dedup_key = f'{company}|{p.get(\"title\",\"\")}'
        if dedup_key in seen_titles:
            continue
        seen_titles.add(dedup_key)
        url_slug = p.get('url', p.get('id', ''))
        salary = p.get('salary', {})
        sal_from = salary.get('from', '?')
        sal_to = salary.get('to', '?')
        sal_currency = salary.get('currency', 'PLN')
        remote = p.get('location', {}).get('fullyRemote', False)
        loc_str = 'Remote' if remote else ', '.join(list(dict.fromkeys([loc.get('city', '?') for loc in p.get('location', {}).get('places', [])]))[:3])
        full_url = f'https://nofluffjobs.com/pl/job/{url_slug}'
        print(f'{p.get(\"title\", \"Unknown\")} @ {company}')
        print(f'  {sal_from}-{sal_to} {sal_currency} | {loc_str}')
        print(f'  {full_url}')
        count += 1
    if count == 0:
        print('  (no Ruby/Rails senior remote postings found)')
except Exception as e:
    print(f'  (parse error: {e})')
" 2>/dev/null || echo "  (fetch failed — may need browser)"
  update_last_scan "nofluffjobs"
  echo ""
}

scan_justjoinit() {
  echo "=== Just Join IT ==="
  # JustJoinIT API is locked; scrape the filtered page
  curl -sL "https://justjoin.it/all-locations/ruby/senior?remote=true" 2>/dev/null | "$PYTHON" -c "
import sys, re

content = sys.stdin.read()
# Extract offer links
links = re.findall(r'href=\"(/offers/[^\"]+)\"', content)
# Extract titles near links
titles = re.findall(r'<h[23][^>]*>(.*?)</h[23]>', content, re.DOTALL)

seen = set()
count = 0
for link in links:
    if count >= 15:
        break
    url = 'https://justjoin.it' + link
    if url not in seen:
        seen.add(url)
        name = link.replace('/offers/', '').replace('-', ' ')[:80]
        print(f'{name}')
        print(f'  {url}')
        count += 1
if count == 0:
    print('  (no results parsed — may need browser scraping)')
" 2>/dev/null || echo "  (fetch failed — may need browser)"
  update_last_scan "justjoinit"
  echo ""
}

scan_bulldogjob() {
  echo "=== Bulldogjob ==="
  curl -sL "https://bulldogjob.pl/companies/jobs/s/skills,Ruby/experienceLevel,senior/city,Remote" 2>/dev/null | "$PYTHON" -c "
import sys, re

content = sys.stdin.read()

# Extract job cards
titles = re.findall(r'<a[^>]*href=\"(/companies/jobs/[^\"]+)\"[^>]*>(.*?)</a>', content, re.DOTALL)
seen = set()
for href, title in titles[:15]:
    title = re.sub(r'<[^>]+>', '', title).strip()
    url = 'https://bulldogjob.pl' + href
    if title and url not in seen and len(title) > 5:
        seen.add(url)
        print(f'{title}')
        print(f'  {url}')
" 2>/dev/null || echo "  (fetch failed)"
  update_last_scan "bulldogjob"
  echo ""
}

scan_wttj() {
  echo "=== Welcome to the Jungle ==="
  curl -sL "https://www.welcometothejungle.com/en/jobs?query=ruby+rails&refinementList%5Bremote%5D%5B%5D=fulltime" 2>/dev/null | "$PYTHON" -c "
import sys, re

content = sys.stdin.read()

links = re.findall(r'href=\"(/en/companies/[^\"]+/jobs/[^\"]+)\"', content)
titles = re.findall(r'<h[34][^>]*>(.*?)</h[34]>', content, re.DOTALL)

seen = set()
for link in links[:15]:
    url = 'https://www.welcometothejungle.com' + link
    if url not in seen:
        seen.add(url)
        name = link.split('/jobs/')[-1].replace('-', ' ') if '/jobs/' in link else link
        print(f'{name}')
        print(f'  {url}')
" 2>/dev/null || echo "  (fetch failed)"
  update_last_scan "wttj"
  echo ""
}

# === COMMANDS ===

CMD="${1:-help}"
shift 2>/dev/null || true
ARGS=("$@")

case "$CMD" in
  scout)
    source_filter=""
    if [ ${#ARGS[@]} -ge 2 ] && [ "${ARGS[0]}" = "--source" ]; then
      source_filter="${ARGS[1]}"
    fi

    echo "Job Scout — $(date_stamp)"
    echo "================================"
    echo ""

    if [ -z "$source_filter" ]; then
      scan_gmail
      scan_nofluffjobs
      scan_justjoinit
      scan_rubyonremote
      scan_railsjobboard
      scan_hnhiring
      scan_bulldogjob
      scan_wttj
    else
      case "$source_filter" in
        gmail) scan_gmail ;;
        nofluffjobs|nfj) scan_nofluffjobs ;;
        justjoinit|jjit) scan_justjoinit ;;
        rubyonremote|ror) scan_rubyonremote ;;
        railsjobboard|rjb) scan_railsjobboard ;;
        hnhiring|hn) scan_hnhiring ;;
        bulldogjob|bdj) scan_bulldogjob ;;
        wttj) scan_wttj ;;
        *) echo "Unknown source: $source_filter" ; exit 1 ;;
      esac
    fi

    echo "================================"
    echo "Scan complete: $(timestamp)"
    ;;

  inbox)
    echo "Job Inbox — $(date_stamp)"
    echo "================================"
    echo ""
    echo "--- Recruiter Messages (7d) ---"
    bash "$GMAIL_SKILL" search-all 'subject:opportunity OR subject:role OR subject:position OR subject:hiring newer_than:7d -from:jobalerts-noreply -from:jobs-noreply -from:jobs-listings -category:promotions' --max 10 2>/dev/null || true
    echo ""
    echo "--- ATS Updates (7d) ---"
    bash "$GMAIL_SKILL" search-all 'from:lever.co OR from:greenhouse.io OR from:greenhouse-mail.io OR from:ashbyhq.com OR from:workable.com newer_than:7d' --max 10 2>/dev/null || true
    echo ""
    echo "--- Job Alerts (3d) ---"
    bash "$GMAIL_SKILL" search-all 'from:jobalerts-noreply@linkedin.com newer_than:3d subject:ruby OR subject:rails OR subject:backend' --max 10 2>/dev/null || true
    ;;

  score)
    if [ ${#ARGS[@]} -gt 0 ]; then
      text="${ARGS[*]}"
    elif [ ! -t 0 ]; then
      text=$(cat)
    else
      echo "Usage: job-scout.sh score <text>"
      echo "  echo 'Senior Ruby on Rails Engineer, remote, 30K PLN B2B' | bash job-scout.sh score"
      exit 1
    fi
    score_text "$text"
    ;;

  track)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: job-scout.sh track <company>"
      exit 1
    fi
    company="${ARGS[*]}"
    "$PYTHON" -c "
import yaml
with open('$CRITERIA', 'r') as f:
    data = yaml.safe_load(f) or {}
wl = data.get('watchlist', []) or []
if '$company' not in wl:
    wl.append('$company')
    data['watchlist'] = wl
    with open('$CRITERIA', 'w') as f:
        yaml.dump(data, f, default_flow_style=False)
    print('Added to watchlist: $company')
else:
    print('Already on watchlist: $company')
"
    ;;

  blacklist)
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "Usage: job-scout.sh blacklist <company or recruiter>"
      exit 1
    fi
    name="${ARGS[*]}"
    "$PYTHON" -c "
import yaml
with open('$CRITERIA', 'r') as f:
    data = yaml.safe_load(f) or {}
bl_r = data.get('blacklist_recruiters', []) or []
bl_c = data.get('blacklist_companies', []) or []
if '$name' not in bl_r and '$name' not in bl_c:
    bl_c.append('$name')
    data['blacklist_companies'] = bl_c
    with open('$CRITERIA', 'w') as f:
        yaml.dump(data, f, default_flow_style=False)
    print('Blacklisted: $name')
else:
    print('Already blacklisted: $name')
"
    ;;

  pipeline)
    "$PYTHON" -c "
import yaml
with open('$STATUS', 'r') as f:
    data = yaml.safe_load(f) or {}
pipeline = data.get('pipeline', []) or []
if not pipeline:
    print('Pipeline is empty.')
else:
    print(f'{'Status':<15} {'Company':<25} {'Role':<35} {'Date'}')
    print('-' * 90)
    for p in pipeline:
        print(f\"{p.get('status','?'):<15} {p.get('company','?'):<25} {p.get('role','?'):<35} {p.get('date','?')}\")
"
    ;;

  status)
    if [ ${#ARGS[@]} -lt 2 ]; then
      echo "Usage: job-scout.sh status <url> <new|reviewing|applied|interviewing|rejected|offer|withdrawn>"
      exit 1
    fi
    url="${ARGS[0]}"
    state="${ARGS[1]}"
    "$PYTHON" -c "
import yaml
with open('$STATUS', 'r') as f:
    data = yaml.safe_load(f) or {}
pipeline = data.get('pipeline', []) or []
found = False
for p in pipeline:
    if p.get('url') == '$url':
        p['status'] = '$state'
        found = True
        break
if not found:
    pipeline.append({'url': '$url', 'status': '$state', 'date': '$(date_stamp)', 'company': '', 'role': '', 'notes': ''})
data['pipeline'] = pipeline
with open('$STATUS', 'w') as f:
    yaml.dump(data, f, default_flow_style=False)
print('Updated: $url -> $state')
"
    ;;

  report)
    echo "Job Scout Report — $(date_stamp)"
    echo "================================"
    echo ""
    lead_count=$(find "$LEADS_DIR" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo "Total leads: $lead_count"
    echo ""
    # Show recent leads (modified in last 7 days)
    echo "--- Recent Leads (7d) ---"
    find "$LEADS_DIR" -name "*.md" -mtime -7 -exec basename {} \; 2>/dev/null | sort || echo "  (none)"
    echo ""
    # Pipeline summary
    echo "--- Pipeline ---"
    "$PYTHON" -c "
import yaml
with open('$STATUS', 'r') as f:
    data = yaml.safe_load(f) or {}
pipeline = data.get('pipeline', []) or []
if not pipeline:
    print('  (empty)')
else:
    from collections import Counter
    counts = Counter(p.get('status', 'unknown') for p in pipeline)
    for status, count in sorted(counts.items()):
        print(f'  {status}: {count}')
" 2>/dev/null
    echo ""
    # Last scan times
    echo "--- Last Scans ---"
    "$PYTHON" -c "
import yaml
with open('$STATUS', 'r') as f:
    data = yaml.safe_load(f) or {}
scans = data.get('last_scan_per_source', {}) or {}
for source, ts in sorted(scans.items()):
    print(f'  {source:<20} {ts or \"never\"}')
" 2>/dev/null
    ;;

  leads)
    echo "Lead files in $LEADS_DIR:"
    ls -1t "$LEADS_DIR"/*.md 2>/dev/null | while read -r f; do
      basename "$f"
    done || echo "  (none)"
    ;;

  criteria)
    cat "$CRITERIA"
    ;;

  help|--help|-h|*)
    usage
    ;;
esac
