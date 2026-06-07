# Simple Tutorial: CodePipeline → ECR → ECS (Fargate)

A beginner-friendly, copy-paste guide. You'll push code to GitHub, and AWS will automatically build a Docker image, store it in **ECR**, and deploy it to **ECS Fargate**.

```
GitHub (code)  →  CodeBuild (builds image)  →  ECR (stores image)  →  ECS Fargate (runs it)
                          ↑___________________ all orchestrated by CodePipeline ___________________↑
```

**What you need first**
- An AWS account
- A GitHub account
- (Optional) AWS CLI installed — most of this is clickable in the console

Pick **one region** (e.g. `us-east-1`) and stay in it the whole time. Mixing regions is the #1 beginner mistake.

---

## Part 1 — The Sample App (3 files)

Create a folder and put these three files in it.

**`app.js`**
```js
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => res.send('Hello from ECS! 🚀  v1'));

app.listen(port, () => console.log(`App running on port ${port}`));
```

**`package.json`**
```json
{
  "name": "sample-app",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": { "start": "node app.js" },
  "dependencies": { "express": "^4.18.2" }
}
```

**`Dockerfile`**
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
```

**`buildspec.yml`** — this tells CodeBuild how to build and push the image.
```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME
      - IMAGE_TAG=${CODEBUILD_RESOLVED_SOURCE_VERSION:=latest}
  build:
    commands:
      - echo Building the Docker image...
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
  post_build:
    commands:
      - echo Pushing image to ECR...
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - echo Writing imagedefinitions.json...
      - printf '[{"name":"%s","imageUri":"%s"}]' "$CONTAINER_NAME" "$REPOSITORY_URI:$IMAGE_TAG" > imagedefinitions.json
artifacts:
  files:
    - imagedefinitions.json
```

> `imagedefinitions.json` is the magic file. It tells ECS "deploy THIS image to THIS container." The `name` must exactly match your container name in the task definition (we'll call it **`sample-app`**).

Push all four files to a new GitHub repo (e.g. `sample-ecs-app`) on the `main` branch.

---

## Part 2 — Create the ECR Repository (stores your images)

1. Console → **ECR** → **Create repository**
2. Name it: **`sample-app`**
3. Leave defaults → **Create**

Copy the repo URI shown — it looks like:
`<account-id>.dkr.ecr.us-east-1.amazonaws.com/sample-app`

---

## Part 3 — Create the ECS Cluster, Task Definition & Service

### 3a. Cluster
1. Console → **ECS** → **Clusters** → **Create cluster**
2. Name: **`sample-cluster`**
3. Infrastructure: **AWS Fargate (serverless)** → **Create**

### 3b. Task Definition (describes how to run your container)
1. ECS → **Task definitions** → **Create new task definition**
2. Family name: **`sample-task`**
3. Launch type: **Fargate**
4. CPU `.25 vCPU`, Memory `.5 GB` (smallest = cheapest)
5. Container:
   - Name: **`sample-app`**  ← must match `CONTAINER_NAME` later
   - Image URI: paste your ECR URI + `:latest` (e.g. `...amazonaws.com/sample-app:latest`)
   - Port mappings: container port **`3000`**, protocol TCP
6. **Create**

> AWS auto-creates a role called **`ecsTaskExecutionRole`** the first time — let it. That role lets ECS pull images from ECR.

### 3c. Service (keeps your app running)
1. Open your **`sample-cluster`** → **Services** tab → **Create**
2. Launch type: **Fargate**
3. Task definition: **`sample-task`** (latest revision)
4. Service name: **`sample-service`**
5. Desired tasks: **1**
6. Networking:
   - Use your default VPC and its subnets
   - Security group → **Create new** → add an **inbound rule**: type *Custom TCP*, port **3000**, source `0.0.0.0/0` (for testing only)
   - **Public IP: Turn ON** (so you can reach it without a load balancer)
7. **Create**

After ~1 minute: Service → **Tasks** → click the running task → find the **Public IP** → open `http://<public-ip>:3000` in your browser. You should see **"Hello from ECS! 🚀 v1"**.

✅ Your app is live. Now let's automate deployments.

---

## Part 4 — The Pipeline (Source → Build → Deploy)

Console → **CodePipeline** → **Create pipeline**.

### Step 1: Pipeline settings
- Name: **`sample-pipeline`**
- Service role: **New service role** (let it create one) → Next

### Step 2: Source
- Provider: **GitHub (via GitHub App)** → **Connect to GitHub** → authorize and install the AWS Connector on your repo
- Repository: **`sample-ecs-app`**, Branch: **`main`** → Next

### Step 3: Build
- Provider: **AWS CodeBuild** → **Create project** (opens a popup)
  - Project name: **`sample-build`**
  - Environment image: **Managed image**, OS **Amazon Linux**, latest standard runtime
  - **✅ Privileged** — REQUIRED, or Docker builds fail
  - Add these **environment variables**:

    | Name | Value |
    |---|---|
    | `AWS_ACCOUNT_ID` | your 12-digit account ID |
    | `IMAGE_REPO_NAME` | `sample-app` |
    | `CONTAINER_NAME` | `sample-app` |

  - Buildspec: **Use a buildspec file** (it reads `buildspec.yml` from your repo)
  - **Continue to CodePipeline** → Next

### Step 4: Deploy
- Provider: **Amazon ECS**
- Cluster: **`sample-cluster`**
- Service: **`sample-service`**
- Image definitions file: **`imagedefinitions.json`** (leave default) → Next → **Create pipeline**

---

## Part 5 — One Last Permission Fix (important!)

CodeBuild needs permission to push to ECR. Right now it doesn't have it.

1. Go to **IAM** → **Roles** → find the role named like **`codebuild-sample-build-service-role`**
2. **Add permissions** → **Attach policies** → attach **`AmazonEC2ContainerRegistryPowerUser`**
3. Save.

Then in CodePipeline, click **Release change** to re-run. The Build stage should now go green.

---

## Part 6 — Test the Automation 🎉

1. Edit `app.js` in GitHub — change the message to `Hello from ECS! 🚀  v2`
2. Commit to `main`
3. Watch CodePipeline: **Source → Build → Deploy** all turn green (takes ~3–5 min)
4. Refresh `http://<public-ip>:3000` → it now shows **v2**

> The public IP can change when ECS replaces the task. For production, put an **Application Load Balancer** in front and point users at its DNS name instead.

---

## Quick Troubleshooting

| Problem | Fix |
|---|---|
| Build fails at `docker build` | "Privileged" mode wasn't enabled on the CodeBuild project |
| Build fails pushing to ECR | Attach `AmazonEC2ContainerRegistryPowerUser` to the CodeBuild role (Part 5) |
| Deploy fails / "container name not found" | `CONTAINER_NAME` env var ≠ container name in the task definition — both must be `sample-app` |
| Can't open the app in browser | Security group missing inbound rule for port 3000, or task has no public IP |
| Task keeps stopping | Container port (3000) must match your app's listening port |
| Everything in different regions | Recreate so ECR, ECS, CodeBuild, and CodePipeline are all in the same region |

## Don't Forget to Clean Up (avoid charges)
Delete in this order: CodePipeline → CodeBuild project → ECS service → ECS cluster → ECR repository → the GitHub connection.
