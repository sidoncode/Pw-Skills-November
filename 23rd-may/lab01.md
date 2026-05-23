# Python App Logs → GitHub Actions → ELK + Grafana on EC2

**Time: ~25 minutes | Method: Docker Compose + Python logging**

---

## The Big Picture

```
Python App  →  GitHub Actions  →  Logstash  →  Elasticsearch  →  Grafana
(your code)    (runs & ships logs)  (EC2)         (EC2)             (EC2)
```

---

# PART A — Your Python App

## Step 1 — Create the Python App

Create this folder structure in your GitHub repo:

```
my-app/
├── app.py
├── logger.py
├── requirements.txt
└── .github/
    └── workflows/
        └── ci.yml
```

**`logger.py`** — reusable ELK logger:

```python
import logging
import json
import os
import datetime
import urllib.request

class ELKHandler(logging.Handler):
    """Sends log records to Logstash over HTTP."""

    def __init__(self, url, extra_fields=None):
        super().__init__()
        self.url = url
        self.extra = extra_fields or {}

    def emit(self, record):
        payload = {
            "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
            "level":     record.levelname,
            "message":   self.format(record),
            "logger":    record.name,
            "file":      record.filename,
            "line":      record.lineno,
        }
        payload.update(self.extra)

        try:
            data = json.dumps(payload).encode("utf-8")
            req  = urllib.request.Request(
                self.url,
                data=data,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            urllib.request.urlopen(req, timeout=3)
        except Exception:
            pass  # never crash the app because of logging


def get_logger(name="app"):
    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)

    # Always print to console
    console = logging.StreamHandler()
    console.setFormatter(logging.Formatter("%(levelname)s | %(message)s"))
    logger.addHandler(console)

    # Send to ELK if LOGSTASH_URL is set
    url = os.getenv("LOGSTASH_URL")
    if url:
        elk = ELKHandler(url, extra_fields={
            "app":        os.getenv("APP_NAME", "my-python-app"),
            "environment": os.getenv("APP_ENV", "ci"),
            "run_number": os.getenv("GITHUB_RUN_NUMBER", "0"),
            "branch":     os.getenv("GITHUB_REF_NAME", "local"),
            "actor":      os.getenv("GITHUB_ACTOR", "local"),
            "repository": os.getenv("GITHUB_REPOSITORY", "local"),
        })
        logger.addHandler(elk)

    return logger
```

**`app.py`** — sample application:

```python
import time
import random
from logger import get_logger

log = get_logger("my-app")

def process_order(order_id):
    log.info(f"Processing order {order_id}")
    time.sleep(random.uniform(0.1, 0.5))  # simulate work

    if random.random() < 0.2:            # 20% chance of failure
        log.error(f"Order {order_id} failed — payment declined")
        return False

    log.info(f"Order {order_id} completed successfully")
    return True

def main():
    log.info("Application started")

    passed = failed = 0
    for i in range(1, 11):               # process 10 orders
        if process_order(f"ORD-{i:03d}"):
            passed += 1
        else:
            failed += 1

    log.info(f"Run complete — passed={passed} failed={failed}")

    if failed > 0:
        log.warning(f"{failed} orders failed in this run")

if __name__ == "__main__":
    main()
```

**`requirements.txt`**:

```
# No external dependencies needed — uses Python stdlib only
```

---

# PART B — EC2 + Docker Stack

## Step 2 — Launch EC2

1. **AWS Console → EC2 → Launch Instance**
2. OS: **Ubuntu 22.04 LTS**
3. Type: **t3.medium**
4. Storage: **20 GB**
5. Security Group — open ports:

| Port | Source | Purpose |
|------|--------|---------|
| 22 | Your IP | SSH |
| 5044 | 0.0.0.0/0 | Logstash (receives logs) |
| 3000 | Your IP | Grafana |
| 5601 | Your IP | Kibana |

## Step 3 — Install Docker on EC2

```bash
# SSH in
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu
newgrp docker
```

## Step 4 — Create the Stack Files

```bash
mkdir elk && cd elk
```

**`docker-compose.yml`**:

```bash
cat > docker-compose.yml << 'YAML'
version: "3.8"
services:

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms1g -Xmx1g
    ports:
      - "9200:9200"
    volumes:
      - esdata:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:8.12.0
    ports:
      - "5044:5044"
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:8.12.0
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - grafdata:/var/lib/grafana

volumes:
  esdata:
  grafdata:
YAML
```

**`logstash.conf`**:

```bash
cat > logstash.conf << 'CONF'
input {
  http {
    port => 5044
    codec => json
  }
}

filter {
  date {
    match => ["timestamp", "ISO8601"]
    target => "@timestamp"
  }
  mutate {
    remove_field => ["headers"]
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "python-app-%{+YYYY.MM.dd}"
  }
}
CONF
```

**Start everything:**

```bash
docker compose up -d

# Wait 60 seconds, then verify
curl http://localhost:9200
```

---

# PART C — GitHub Actions

## Step 5 — Add Secrets to GitHub

Go to your repo → **Settings → Secrets and variables → Actions → New secret**

| Secret Name | Value |
|-------------|-------|
| `LOGSTASH_URL` | `http://YOUR_EC2_IP:5044` |


## Step 5 — create a new python file called as send_log.py

**`/root directory`**:

```python
import os, json, urllib.request, datetime

url = os.getenv("LOGSTASH_URL")
if not url:
    print("No LOGSTASH_URL set, skipping")
    exit(0)

payload = {
    "timestamp":   datetime.datetime.utcnow().isoformat() + "Z",
    "level":       "INFO" if os.getenv("JOB_STATUS") == "success" else "ERROR",
    "message":     "CI run " + os.getenv("JOB_STATUS", "unknown"),
    "app":         os.getenv("APP_NAME", "my-python-app"),
    "environment": "ci",
    "conclusion":  os.getenv("JOB_STATUS", "unknown"),
    "run_number":  int(os.getenv("GITHUB_RUN_NUMBER", 0)),
    "branch":      os.getenv("GITHUB_REF_NAME", ""),
    "actor":       os.getenv("GITHUB_ACTOR", ""),
    "repository":  os.getenv("GITHUB_REPOSITORY", ""),
}

data = json.dumps(payload).encode()
req  = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
urllib.request.urlopen(req, timeout=5)
print("Log sent to ELK ✓")

```

## Step 6 — Create the Workflow

**`.github/workflows/ci.yml`**:

```yaml
name: Python CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  run:
    runs-on: ubuntu-latest

    env:
      LOGSTASH_URL: ${{ secrets.LOGSTASH_URL }}
      APP_NAME: my-python-app
      APP_ENV: ci

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Run app
        run: python app.py

      - name: Send final status to ELK
        if: always()
        env:
          JOB_STATUS: ${{ job.status }}
        run: python send_log.py
```

Push to `main` — your Python app runs, and every `log.info/warning/error` call ships to ELK automatically.

---

# PART D — Grafana Dashboard

## Step 7 — Connect Grafana to Elasticsearch

1. Open `http://YOUR_EC2_IP:3000` → login: **admin / admin123**
2. **Connections → Data Sources → Add data source → Elasticsearch**
3. Fill in:
   - **URL:** `http://elasticsearch:9200`
   - **Index name:** `python-app-*`
   - **Time field name:** `@timestamp`
   - **Version:** 8.0+
4. **Save & Test**

## Step 8 — Build the Dashboard

**Dashboards → New Dashboard → Add panels:**

---

### Panel 1 — Log Stream (Logs panel)
Shows live log messages from your app.
- Visualization: **Logs**
- Query: *(leave blank — shows all)*
- Title: `Application Logs`

---

### Panel 2 — Log Level Breakdown (Pie chart)
Shows INFO vs WARNING vs ERROR counts.
- Visualization: **Pie chart**
- Query (Lucene): `level:*`
- Metric: **Count**
- Group by: **Terms → field: `level`**
- Title: `Log Levels`

---

### Panel 3 — Errors Over Time (Time series)
Tracks error spikes.
- Visualization: **Time series**
- Query (Lucene): `level:ERROR`
- Metric: **Count**
- Group by: **Date histogram → @timestamp**
- Title: `Errors Over Time`

---

### Panel 4 — CI Run Results (Stat)
Shows total runs today.
- Visualization: **Stat**
- Query (Lucene): `conclusion:*`
- Metric: **Count**
- Title: `Total CI Runs Today`
- Time range: Last 24h

---

### Panel 5 — Failed Runs Table
Lists recent failures with details.
- Visualization: **Table**
- Query (Lucene): `conclusion:failure OR level:ERROR`
- Columns: `@timestamp`, `message`, `branch`, `actor`, `run_number`
- Title: `Recent Failures`

---

## Step 9 — Test the Full Pipeline

```bash
# Send a test log to verify everything works
curl -X POST http://YOUR_EC2_IP:5044 \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
    "level": "INFO",
    "message": "Test from terminal",
    "app": "my-python-app"
  }'

# Check it arrived in Elasticsearch
curl "http://YOUR_EC2_IP:9200/python-app-*/_count"
# Should return: {"count":1, ...}
```

Then push a commit to GitHub and watch logs appear in Grafana within seconds.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| No data in Grafana | Check index name is `python-app-*` and time field is `@timestamp` |
| Logstash not receiving | Verify port 5044 is open in EC2 security group |
| Elasticsearch down | Run `docker compose logs elasticsearch` — may need more RAM |
| GitHub Actions curl fails | Check `LOGSTASH_URL` secret has correct EC2 public IP |

## Useful Commands

```bash
# View live logs from all services
docker compose logs -f

# Restart a single service
docker compose restart logstash

# See all documents in Elasticsearch
curl "http://localhost:9200/python-app-*/_search?pretty&size=5"

# Stop everything
docker compose down
```

---

## Access URLs

| Service | URL | Login |
|---------|-----|-------|
| Grafana | `http://YOUR_EC2_IP:3000` | admin / admin123 |
| Kibana | `http://YOUR_EC2_IP:5601` | no login |
| Elasticsearch | `http://YOUR_EC2_IP:9200` | no login |
