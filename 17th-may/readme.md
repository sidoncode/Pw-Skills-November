# ELK Stack with Python Logging Demo

A complete setup guide for deploying **Elasticsearch**, **Logstash**, and **Kibana** on AWS EC2 to collect, process, and visualize logs from a Python application.

## 📋 Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Step-by-Step Setup](#step-by-step-setup)
- [Verification](#verification)
- [Access Kibana](#access-kibana)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)
- [Files Included](#files-included)

---

## 🎯 Overview

This project demonstrates a complete **ELK Stack** (Elasticsearch, Logstash, Kibana) implementation for log aggregation and visualization. A Python application generates logs that are collected, parsed, and indexed into Elasticsearch, where they can be visualized and analyzed through Kibana's web interface.

### Key Features
- ✅ Python application generating sample logs
- ✅ Docker & Docker Compose for containerization
- ✅ Logstash for log parsing and transformation
- ✅ Elasticsearch for log storage and indexing
- ✅ Kibana for visualization and analysis
- ✅ AWS EC2 deployment ready

---

## 📦 Prerequisites

### AWS Requirements
- **EC2 Instance Type**: `t2.medium` or `c4.i.flexLarge` (or larger)
- **Storage**: 10GB EBS volume (gp2 or gp3 recommended)
- **AMI**: Ubuntu 20.04 LTS or Ubuntu 22.04 LTS
- **Security Groups**: HTTP/HTTPS enabled

### Software Requirements
- Docker
- Docker Compose
- Python 3
- Bash/Terminal access

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│              AWS EC2 Instance (Ubuntu)           │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Python Application (app.py)             │  │
│  │  • Generates sample logs                 │  │
│  │  • Writes to logs/app.log                │  │
│  └────────┬─────────────────────────────────┘  │
│           │                                    │
│  ┌────────▼─────────────────────────────────┐  │
│  │  Logstash Container                      │  │
│  │  • Reads logs/app.log                    │  │
│  │  • Parses with GROK                      │  │
│  │  • Sends to Elasticsearch                │  │
│  └────────┬─────────────────────────────────┘  │
│           │                                    │
│  ┌────────▼──────────────┐  ┌──────────────┐  │
│  │  Elasticsearch        │  │  Kibana      │  │
│  │  :9200                │  │  :5601       │  │
│  │  • Indexes logs       │  │  • Visualize │  │
│  │  • Search engine      │  │  • Analyze   │  │
│  └───────────────────────┘  └──────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 🚀 Step-by-Step Setup

### Step 1: Launch EC2 Instance

1. Go to **AWS Console** → **EC2 Dashboard**
2. Click **Launch Instances**
3. Configure:
   - **AMI**: Ubuntu 20.04 LTS or 22.04 LTS
   - **Instance Type**: `t2.medium` or `c4.i.flexLarge`
   - **Storage**: 10GB EBS
   - **Security Group**: Enable HTTP (80), HTTPS (443), and Custom TCP (5601)
4. Launch and download the key pair

### Step 2: Connect to EC2

1. In EC2 Dashboard, select your instance
2. Click **Connect** button
3. Choose **EC2 Instance Connect** tab
4. Click **Connect** to open a browser-based terminal

*(Alternative: SSH via terminal)*
```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

### Step 3: Install Docker & Docker Compose

```bash
sudo apt update
sudo apt install docker.io docker-compose -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
```

**Verify Installation:**
```bash
docker --version
docker compose --version
```

### Step 4: Create Project Structure

```bash
mkdir elk-python-demo
cd elk-python-demo
mkdir logs
```

### Step 5: Create Python Application

```bash
nano app.py
```

**Paste the following content:**
```python
import time
import random
from datetime import datetime

log_file = "logs/app.log"
messages = [
    "INFO User Login Success",
    "ERROR Database Connection Failed",
    "WARNING High CPU Usage",
    "INFO Payment Completed",
    "INFO API Request Received"
]

while True:
    log = f"{datetime.now().isoformat()} {random.choice(messages)}\n"
    with open(log_file, "a") as file:
        file.write(log)
    print(log)
    time.sleep(5)
```

**Save and exit**: Press `Ctrl + X`, then `Y`, then `Enter`

### Step 6: Install Python & Test Application

```bash
sudo apt install python3 -y
```

**Optional - Test the Python app:**
```bash
python3 app.py
```

Run for a few seconds, then stop with `Ctrl + C`

**View generated logs:**
```bash
cat logs/app.log
```

### Step 7: Create Logstash Configuration

```bash
nano logstash.conf
```

**Paste the following content:**
```
input {
  file {
    path => "/logs/app.log"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
}

filter {
  grok {
    match => {
      "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:msg}"
    }
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "python-logs"
  }
  stdout {
    codec => rubydebug
  }
}
```

**Save and exit**: Press `Ctrl + X`, then `Y`, then `Enter`

### Step 8: Create Docker Compose Configuration

```bash
nano docker-compose.yml
```

**Paste the following content:**
```yaml
version: '3'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.12.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  kibana:
    image: docker.elastic.co/kibana/kibana:8.12.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      elasticsearch:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:5601/api/status || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5

  logstash:
    image: docker.elastic.co/logstash/logstash:8.12.0
    container_name: logstash
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
      - ./logs:/logs
    depends_on:
      elasticsearch:
        condition: service_healthy
```

**Save and exit**: Press `Ctrl + X`, then `Y`, then `Enter`

### Step 9: Start Docker Containers

```bash
sudo docker compose up -d
```

**Monitor startup (wait 30-60 seconds for all services):**
```bash
docker ps
docker logs elasticsearch
docker logs kibana
docker logs logstash
```

### Step 10: Verify Elasticsearch

```bash
curl http://localhost:9200
```

**Expected output:**
```json
{
  "name" : "abc123def",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "xxxxx",
  "version" : {
    "number" : "8.12.0",
    ...
  },
  "tagline" : "You Know, for Search"
}
```

### Step 11: Configure Security Group for Kibana

1. Go to **EC2 Dashboard** → **Security Groups**
2. Click on your instance's security group
3. Click **Edit inbound rules**
4. Click **Add rule**
5. Configure:
   - **Type**: Custom TCP
   - **Port Range**: `5601`
   - **Source**: `0.0.0.0/0` (or your IP for restricted access)
6. Click **Save rules**

### Step 12: Start Python Application

```bash
python3 app.py &
```

The `&` runs it in the background. Logs will be generated and sent to Elasticsearch.

---

## ✅ Verification

### Check Running Containers
```bash
docker ps
```

All four containers should be **UP**:
- elasticsearch
- kibana
- logstash
- (optional: your Python app in another terminal)

### Check Elasticsearch Indices
```bash
curl http://localhost:9200/_cat/indices
```

You should see an index named `python-logs`:
```
health status index        uuid                   pri rep docs.count docs.deleted
yellow open   python-logs  xxxxx                    1   1        42            0
```

### View Logs in Elasticsearch
```bash
curl http://localhost:9200/python-logs/_search?pretty
```

---

## 🔍 Access Kibana

### From Browser

1. Get your EC2 public IP address:
   ```bash
   curl http://169.254.169.254/latest/meta-data/public-ipv4
   ```

2. Open your browser and navigate to:
   ```
   http://YOUR_EC2_PUBLIC_IP:5601
   ```

### First-Time Setup in Kibana

1. **Create Index Pattern**:
   - Go to **Management** → **Stack Management** → **Index Patterns**
   - Click **Create index pattern**
   - Index pattern name: `python-logs*`
   - Timestamp field: `@timestamp`
   - Click **Create index pattern**

2. **View Logs**:
   - Go to **Discover**
   - Select the `python-logs` index pattern
   - Browse and analyze your logs

3. **Create Dashboards** (Optional):
   - Go to **Dashboards** → **Create**
   - Add visualizations for log levels, message types, etc.

---

## 📁 Project Structure

```
elk-python-demo/
├── app.py                 # Python application generating logs
├── logstash.conf          # Logstash pipeline configuration
├── docker-compose.yml     # Docker Compose service definitions
└── logs/
    └── app.log            # Generated application logs (auto-created)
```

---

## 📄 Files Included

### app.py
Python script that generates sample logs every 5 seconds. Simulates various log levels (INFO, ERROR, WARNING) and business events.

**Features:**
- Generates random log messages
- Writes to `logs/app.log`
- Runs indefinitely

### logstash.conf
Logstash pipeline configuration that:
- **Input**: Reads logs from `logs/app.log`
- **Filter**: Parses logs using GROK pattern to extract timestamp, level, and message
- **Output**: Sends to Elasticsearch and prints to stdout

### docker-compose.yml
Defines three services:
- **Elasticsearch**: Search and analytics engine
- **Kibana**: Web UI for visualization
- **Logstash**: Log processing pipeline

All services are networked together via Docker's default bridge network.

---

## 🛠️ Common Commands

### Manage Containers
```bash
# View running containers
docker ps

# View all containers
docker ps -a

# View logs
docker logs elasticsearch
docker logs kibana
docker logs logstash

# Stop all services
sudo docker compose down

# Restart services
sudo docker compose restart

# Remove all services and volumes
sudo docker compose down -v
```

### Manage Python Application
```bash
# Run in foreground
python3 app.py

# Run in background
python3 app.py &

# Stop background process
pkill -f "python3 app.py"

# View logs
tail -f logs/app.log
```

### Elasticsearch Queries
```bash
# List all indices
curl http://localhost:9200/_cat/indices

# Get index mapping
curl http://localhost:9200/python-logs/_mapping

# Search all documents
curl http://localhost:9200/python-logs/_search?pretty

# Search by log level
curl 'http://localhost:9200/python-logs/_search?q=level:ERROR&pretty'

# Delete index
curl -X DELETE http://localhost:9200/python-logs
```

---

## 🐛 Troubleshooting

### Issue: Kibana shows "Elastic is still initializing"
**Solution**: Wait 60 seconds for Elasticsearch to fully start. Check logs:
```bash
docker logs elasticsearch
```

### Issue: No logs appearing in Kibana
**Steps**:
1. Verify Python app is running:
   ```bash
   ps aux | grep python3
   ```
2. Check Logstash logs:
   ```bash
   docker logs logstash
   ```
3. Verify logs are being written:
   ```bash
   tail -f logs/app.log
   ```

### Issue: "Connection refused" error
**Solution**: Check if all containers are running:
```bash
docker ps
```
If not, restart:
```bash
sudo docker compose up -d
```

### Issue: Port 5601 not accessible
**Solution**: 
1. Verify security group allows inbound traffic on port 5601
2. Check if Kibana is running:
   ```bash
   curl http://localhost:5601/api/status
   ```

### Issue: High memory usage
**Solution**: The default ES configuration may need tuning. Edit `docker-compose.yml`:
```yaml
environment:
  - discovery.type=single-node
  - xpack.security.enabled=false
  - ES_JAVA_OPTS=-Xms512m -Xmx512m  # Add this line
```

---

## 📊 Sample Log Output

```
2024-01-15T10:23:45.123456 INFO User Login Success
2024-01-15T10:23:50.456789 ERROR Database Connection Failed
2024-01-15T10:23:55.789012 WARNING High CPU Usage
2024-01-15T10:24:00.012345 INFO Payment Completed
2024-01-15T10:24:05.345678 INFO API Request Received
```

After parsing by Logstash:
```json
{
  "@timestamp": "2024-01-15T10:23:45.123456Z",
  "message": "INFO User Login Success",
  "timestamp": "2024-01-15T10:23:45.123456",
  "level": "INFO",
  "msg": "User Login Success"
}
```

---

## 📚 Additional Resources

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Docker Documentation](https://docs.docker.com/)
- [GROK Pattern Reference](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html)

---

## 📝 License

This project is provided as-is for educational and demonstration purposes.

---

## 🤝 Contributing

Feel free to fork and submit pull requests for any improvements!

---

## ❓ FAQ

**Q: Can I use this in production?**  
A: This setup is designed for learning and testing. For production, implement security (authentication, encryption), proper resource allocation, and backup strategies.

**Q: How do I make Kibana accessible only from my IP?**  
A: In the security group inbound rule, change source from `0.0.0.0/0` to your IP address (e.g., `203.0.113.0/32`).

**Q: Can I use different Elasticsearch versions?**  
A: Yes, update the image version in `docker-compose.yml`. Ensure Logstash and Kibana versions are compatible.

**Q: How do I persist data after stopping containers?**  
A: Add volumes to Elasticsearch in `docker-compose.yml`:
```yaml
elasticsearch:
  volumes:
    - elasticsearch_data:/usr/share/elasticsearch/data
volumes:
  elasticsearch_data:
```

**Q: Can I collect logs from multiple applications?**  
A: Yes, modify `logstash.conf` to read from multiple log files or sources.

---

**Last Updated**: 2024  
**Version**: 1.0
