# 🚀 Jenkins Pipeline Logs → ELK Stack on AWS EC2

A step-by-step guide to ship Jenkins pipeline logs to the ELK Stack (Elasticsearch, Logstash, Kibana) running on AWS EC2 Ubuntu.

---

## 📐 Architecture

```
┌─────────────────┐     TCP Logs      ┌──────────────────────────────────────────┐
│                 │ ────────────────► │                                          │
│    Jenkins      │                   │   Logstash → Elasticsearch → Kibana      │
│  EC2 Instance 1 │                   │            EC2 Instance 2                │
│                 │                   │                                          │
└─────────────────┘                   └──────────────────────────────────────────┘
```

| Component     | Role                        |
|---------------|-----------------------------|
| **Jenkins**   | Generate pipeline logs      |
| **Logstash**  | Parse & filter logs         |
| **Elasticsearch** | Store & search logs     |
| **Kibana**    | Visualize & dashboards      |

---

## 🖥️ Prerequisites

- 2 × AWS EC2 Ubuntu 22.04 LTS instances
  - **EC2 #1** — Jenkins (`t2.medium` or higher)
  - **EC2 #2** — ELK Stack (`t3.medium` minimum — ELK is RAM-heavy)
- SSH access to both instances

---

## 🔒 Security Group Rules (ELK Instance)

| Port | Protocol | Source          | Purpose             |
|------|----------|-----------------|---------------------|
| 22   | TCP      | Your IP         | SSH                 |
| 5601 | TCP      | Your IP         | Kibana UI           |
| 9200 | TCP      | Jenkins SG      | Elasticsearch API   |
| 5044 | TCP      | Jenkins SG      | Logstash Beats      |
| 5000 | TCP      | Jenkins SG      | Logstash TCP input  |

---

## Step 1 — Install ELK Stack on EC2 #2

SSH into your ELK instance and run:

```bash
# Update & add Elastic repo
sudo apt update && sudo apt install -y apt-transport-https curl gnupg

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch \
  | sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg

echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] \
  https://artifacts.elastic.co/packages/8.x/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

sudo apt update

# Install Elasticsearch, Logstash, and Kibana
sudo apt install -y elasticsearch logstash kibana
```

---

## Step 2 — Configure Elasticsearch

```bash
sudo nano /etc/elasticsearch/elasticsearch.yml
```

```yaml
cluster.name: jenkins-logs
node.name: elk-node-1
network.host: 0.0.0.0
http.port: 9200
xpack.security.enabled: false   # Keep simple for internal use
```

```bash
sudo systemctl enable --now elasticsearch

# Verify (wait ~30s after start)
curl http://localhost:9200
```

✅ You should see a JSON response with cluster info.

---

## Step 3 — Configure Kibana

```bash
sudo nano /etc/kibana/kibana.yml
```

```yaml
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
```

```bash
sudo systemctl enable --now kibana
```

Access Kibana at: `http://<ELK-EC2-PUBLIC-IP>:5601`

---

## Step 4 — Configure Logstash

Create a Jenkins pipeline config:

```bash
sudo nano /etc/logstash/conf.d/jenkins.conf
```

```ruby
input {
  tcp {
    port => 5000
    codec => json_lines
  }
}

filter {
  if [message] {
    grok {
      match => {
        "message" => "%{TIMESTAMP_ISO8601:timestamp} \[%{DATA:job_name}\] %{GREEDYDATA:log_message}"
      }
    }
    date {
      match => ["timestamp", "ISO8601"]
      target => "@timestamp"
    }
  }
  mutate {
    add_field => { "source" => "jenkins" }
  }
}

output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "jenkins-logs-%{+YYYY.MM.dd}"
  }
  stdout { codec => rubydebug }   # Remove in production
}
```

```bash
sudo systemctl enable --now logstash

# Watch for errors
sudo journalctl -u logstash -f
```

---

## Step 5 — Install Jenkins on EC2 #1

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

Access Jenkins at: `http://<EC2-1-PUBLIC-IP>:8080` and complete the setup wizard.

---

## Step 6 — Send Jenkins Logs to Logstash

Choose **one** of the three options below:

### ✅ Option A — Logstash Plugin (Recommended)

1. Go to **Jenkins → Manage Jenkins → Plugins**
2. Search for **Logstash** and install it
3. Go to **Manage Jenkins → Logstash** and configure:

| Setting             | Value                          |
|---------------------|--------------------------------|
| Enable sending logs | ✅ Checked                    |
| Indexer type        | TCP                            |
| Host                | `<ELK-EC2-PRIVATE-IP>`        |
| Port                | `5000`                         |

---

### ⚙️ Option B — Jenkinsfile (Pipeline as Code)

```groovy
pipeline {
  agent any
  stages {
    stage('Build') {
      steps {
        sh '''
          echo "Starting build..."
          # Your build commands here
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

### 🪶 Option C — Filebeat (Lightweight, No Plugin Needed)

Install Filebeat on the Jenkins EC2:

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

> **Note:** For Filebeat, add a `beats` input block to your Logstash config using `port => 5044`.

---

## Step 7 — Kibana Dashboard Setup

1. Open `http://<ELK-EC2-IP>:5601`
2. Navigate to **Stack Management → Index Patterns**
3. Create pattern: `jenkins-logs-*` with time field `@timestamp`
4. Go to **Discover** → select `jenkins-logs-*` to view live logs
5. Build visualizations:
   - 📊 Bar chart by job name
   - 📈 Error rate over time
   - ⏱️ Build duration trends

---

## 🔧 Troubleshooting

```bash
# Check all ELK services at once
sudo systemctl status elasticsearch logstash kibana

# Verify Elasticsearch has the jenkins index
curl "http://localhost:9200/_cat/indices?v" | grep jenkins

# Tail recent Logstash activity
sudo journalctl -u logstash --since "5 min ago"

# Test TCP connection from Jenkins EC2
echo '{"message":"test log"}' | nc <ELK-PRIVATE-IP> 5000
```

### Common Issues

| Problem | Fix |
|---------|-----|
| Logs not arriving in Elasticsearch | Check EC2 security group — port 5000/5044 must be open from Jenkins SG |
| Kibana blank / not loading | Wait 60–90s after start; check `sudo journalctl -u kibana -f` |
| Elasticsearch `OutOfMemoryError` | Increase JVM heap: edit `/etc/elasticsearch/jvm.options`, set `-Xms2g -Xmx2g` |
| Logstash `connection refused` | Ensure Elasticsearch started first; check port 9200 is listening |

---

## 📁 Project Structure

```
jenkins-elk-setup/
├── README.md
└── logstash/
    └── jenkins.conf       # Logstash pipeline config
```

---

## 📚 References

- [Elastic Documentation](https://www.elastic.co/guide/index.html)
- [Jenkins Logstash Plugin](https://plugins.jenkins.io/logstash/)
- [Filebeat Reference](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)

---

## 📄 License

MIT License — feel free to use and adapt.
