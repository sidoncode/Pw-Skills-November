# 🐳 Docker Notes

## Basic Commands

```bash
docker images       # Show all images in current state
docker ps -a        # Show all running/stopped processes
```

---

## Problem Statement

```
Docker Image = { Ubuntu OS → install figlet (software) }

user1 → Docker Image → Hub push → repository
user2 ← pull from Hub repository
```

---

## Lab Walkthrough

### Step 1 – Pull Ubuntu Image

```bash
docker pull ubuntu
```

### Step 2 – Run a Container

```bash
docker run -it --name pizza ubuntu
```

> - `pizza` → process (container name)
> - `ubuntu` → Docker image

**Notes:**
- 1 image can run as **n** processes (containers)
- Each process can be mapped to a **port number**

### Step 3 – Set Up the Container

```bash
docker run -it --name devopsclass ubuntu
mkdir nepal
apt update
apt install figlet
figlet sid
exit
```

### Step 4 – Commit & Push to Docker Hub

```bash
docker commit <container-id> username/repoName:tag01
docker login
docker push username/repoName:tag01
```

**Example:**

```bash
docker commit 8abb18fea8da sidd33/devops5april:tag01
# sha256:3284b19c1d4041ead15a018b6fb0d3d5b21664e2527319db4e6861b02f21ecc5
```

---

## 👤 From a Second User's Perspective

```bash
# Pull a custom image from Docker Hub
docker pull userName/repoName:tag01

# Examples
docker pull sidd33/devops5april:tag01
docker run -it --name sidimage sidd33/devops5april:tag01

docker pull parasacharya/devops-paras-5th-april
docker run -it --name parasImage parasacharya/devops-paras-5th-april:tag01
```

---

## 📝 Key Notes

| Concept | Explanation |
|---|---|
| `bash: sudo: command not found` | Expected in virtualised/containerised systems |
| `repo` | Refers to Docker Hub repository |
| `commit` → `push` | Same concept as Git — commit saves locally, push uploads |

---

## 🔁 Concept Summary

```
Build Image → Commit → Push to Hub → Anyone can Pull & Run
```
