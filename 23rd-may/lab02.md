# 🚀 Jenkins Pipeline Logs → ELK Stack on AWS EC2 (Docker Compose)

Ship Jenkins pipeline logs to Elasticsearch, visualize in Kibana — all running via Docker Compose on AWS EC2 Ubuntu.

---

## 📐 Architecture

```
┌──────────────────────┐          ┌─────────────────────────────────────────────────┐
│                      │          │              Docker Compose (EC2 #2)            │
│   Jenkins (EC2 #1)   │  TCP     │  ┌───────────┐   ┌───────────┐   ┌──────────┐  │
│   Port 8080          │ ──────►  │  │ Logstash  │──►│  Elastic  │──►│  Kibana  │  │
│   Sends logs on 5000 │          │  │ :5000     │   │  :9200    │   │  :5601   │  │
│                      │          │  └───────────┘   └───────────┘   └──────────┘  │
└──────────────────────┘          └─────────────────────────────────────────────────┘
```

---

## 🖥️ Prerequisites

| Requirement | Detail |
|-------------|--------|
| EC2 #1 | Ubuntu 22.04+, `t2.medium`, Jenkins |
| EC2 #2 | Ubuntu 22.04+, `t3.medium` min, Docker + ELK |
| Docker | 20.x or higher |
| Docker Compose | v2 plugin |

---

## 🔒 EC2 Security Group Rules (ELK Instance)

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | Your IP | SSH |
| 5601 | TCP | Your IP | Kibana UI |
| 9200 | TCP | Jenkins SG | Elasticsearch API |
| 5044 | TCP | Jenkins SG | Logstash Beats |
| 5000 | TCP | Jenkins SG | Logstash TCP input |

---

## Step 1 — Install Docker on EC2 #2

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-plugin

# Start Docker
sudo systemctl enable --now docker

# Allow ubuntu user to run docker without sudo
sudo usermod -aG docker ubuntu

# Apply group change without re-login
newgrp docker
```

---

## Step 2 — Create Project Folder

```bash
mkdir ~/elk-stack && cd ~/elk-stack
```

---

## Step 3 — Create docker-compose.yml

```bash
tee docker-compose.yml << 'EOF'
version: '3.8'

services:

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.10
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    ports:
      - "9200:9200"
    volumes:
      - esdata:/usr/share/elasticsearch/data
    networks:
      - elk

  logstash:
    image: docker.elastic.co/logstash/logstash:7.17.10
    container_name: logstash
    ports:
      - "5000:5000/tcp"
      - "5044:5044"
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
    depends_on:
      - elasticsearch
    networks:
      - elk

  kibana:
    image: docker.elastic.co/kibana/kibana:7.17.10
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch
    networks:
      - elk

volumes:
  esdata:

networks:
  elk:
    driver: bridge
EOF
```

---

## Step 4 — Create Logstash Pipeline Config

```bash
mkdir -p logstash/pipeline

tee logstash/pipeline/jenkins.conf << 'EOF'
input {
  tcp {
    port => 5000
    codec => json_lines
  }
}

filter {
  mutate {
    add_field => { "source" => "jenkins" }
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "jenkins-logs-%{+YYYY.MM.dd}"
  }
  stdout { codec => rubydebug }
}
EOF
```

---

## Step 5 — Set System Memory Limit

> Required for Elasticsearch to start correctly.

```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

---

## Step 6 — Start the Stack

```bash
docker compose up -d
```

---

## Step 7 — Verify Everything is Running

```bash
# Check all containers
docker compose ps

# Test Elasticsearch (wait ~30 seconds after start)
curl http://localhost:9200

# Check Logstash logs
docker compose logs logstash

# Check Kibana logs
docker compose logs kibana
```

✅ Expected Elasticsearch response:
```json
{
  "name" : "elk-node-1",
  "cluster_name" : "jenkins-logs",
  "version" : { "number" : "7.17.10" },
  "tagline" : "You Know, for Search"
}
```

---

## Step 8 — Install Jenkins on EC2 #1

```bash
# Install Java
sudo apt update && sudo apt install -y fontconfig openjdk-17-jre

# Add Jenkins repo
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list

sudo apt update && sudo apt install -y jenkins
sudo systemctl enable --now jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Access Jenkins at: `http://<EC2-1-PUBLIC-IP>:8080`

---

## Step 9 — Connect Jenkins to Logstash

Choose **one** of the three options:

### ✅ Option A — Logstash Plugin (Recommended)

1. Go to **Jenkins → Manage Jenkins → Plugins**
2. Search **Logstash** → Install
3. Go to **Manage Jenkins → Logstash** and set:

| Setting | Value |
|---------|-------|
| Enable sending logs | ✅ |
| Indexer type | TCP |
| Host | `<ELK-EC2-PRIVATE-IP>` |
| Port | `5000` |

---

### ⚙️ Option B — Jenkinsfile

```groovy
pipeline {
  agent any
  stages {
    stage('Build') {
      steps {
        sh '''
          echo "Starting build..."
          echo "Build complete"
        '''
      }
      post {
        always {
          logstashSend failBuild: false, maxLines: 1000
        }
      }
    }
  }
}
```

---

### 🪶 Option C — Filebeat (No Plugin)

Install Filebeat on Jenkins EC2:

```bash
sudo apt install -y filebeat
sudo nano /etc/filebeat/filebeat.yml
```

```yaml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/lib/jenkins/jobs/*/builds/*/log

output.logstash:
  hosts: ["<ELK-EC2-PRIVATE-IP>:5044"]
```

```bash
sudo systemctl enable --now filebeat
```

---

## Step 10 — Kibana Dashboard Setup

1. Open `http://<ELK-EC2-PUBLIC-IP>:5601`
2. Go to **Stack Management → Index Patterns**
3. Create pattern: `jenkins-logs-*` with time field `@timestamp`
4. Go to **Discover** → select `jenkins-logs-*` to see live logs
5. Build visualizations:
   - 📊 Bar chart by job name
   - 📈 Error rate over time
   - ⏱️ Build duration trends

---

## 📁 Project Structure

```
elk-stack/
├── docker-compose.yml
└── logstash/
    └── pipeline/
        └── jenkins.conf
```

---

## 🔧 Useful Docker Commands

```bash
# Stop the stack
docker compose down

# Stop and delete all data volumes
docker compose down -v

# Restart a single service
docker compose restart logstash

# Live logs from all services
docker compose logs -f

# Live logs from one service
docker compose logs -f elasticsearch
```

---

## 🔧 Troubleshooting

| Problem | Fix |
|---------|-----|
| Elasticsearch won't start | Run `sudo sysctl -w vm.max_map_count=262144` |
| Kibana shows "server not ready" | Wait 60s; Elasticsearch takes time to boot |
| Logs not arriving in Kibana | Check EC2 SG — port 5000 must be open from Jenkins SG |
| Container keeps restarting | Run `docker compose logs elasticsearch` to check errors |
| `curl localhost:9200` refused | Container still starting — wait 30s and retry |

```bash
# Test TCP connection from Jenkins EC2 to Logstash
echo '{"message":"test log","source":"jenkins"}' | nc <ELK-PRIVATE-IP> 5000

# Check Elasticsearch index was created
curl "http://localhost:9200/_cat/indices?v" | grep jenkins
```

---

## 📚 References

- [Elastic Docker Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/docker.html)
- [Jenkins Logstash Plugin](https://plugins.jenkins.io/logstash/)
- [Filebeat Reference](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)

---

## 📄 License

MIT License — feel free to use and adapt.
