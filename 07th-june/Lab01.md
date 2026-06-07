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
- The **ECS service-linked role** in your account (see the box below — this is a one-time setup that trips up most beginners)

Pick **one region** (e.g. `us-east-1`) and stay in it the whole time. Mixing regions is the #1 beginner mistake.

> **📝 A note on names:** This guide uses `sample-cluster`, `sample-service`, `sample-task`, and `sample-app`. If you named anything differently, just use **your** name everywhere that name appears — and keep it consistent across the cluster, service, task definition, container, and the CodeBuild environment variables. Inconsistent names are the #2 beginner mistake.

---

## Part 0 — One-Time Account Setup: the ECS Service-Linked Role

**Do this before you create a cluster.** ECS needs a special IAM role called `AWSServiceRoleForECS` to manage cluster resources on your behalf. AWS *usually* creates it automatically the first time you use the ECS console wizard — but if you create the cluster via CLI, CloudFormation, Terraform, or just hit a fresh-account edge case, it won't exist yet, and cluster creation fails with:

```
Unable to assume the service linked role.
Please verify that the ECS service linked role exists.
```

Create it once with the CLI:

```bash
aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com
```

If you get an error saying it already exists, great — you're already set. Verify any time with:

```bash
aws iam get-role --role-name AWSServiceRoleForECS
```

No CLI? In the console: **IAM → Roles → Create role → AWS service → Elastic Container Service → the "Elastic Container Service" service-linked role use case → Create.**

Wait a few seconds for IAM to propagate, then continue.

---

## Part 1 — The Sample App (4 files)

Create a folder and put these four files in it.

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
2. Name it: **`sample-app`** (this must match the `IMAGE_REPO_NAME` env var in Part 4)
3. Leave defaults → **Create**

Copy the repo URI shown — it looks like:
`<account-id>.dkr.ecr.us-east-1.amazonaws.com/sample-app`

---

## Part 3 — Create the ECS Cluster, Task Definition & Service

> Make sure you finished **Part 0** first, or the cluster will fail with the "service linked role" error.

### 3a. Cluster
1. Console → **ECS** → **Clusters** → **Create cluster**
2. Name: **`sample-cluster`**
3. Infrastructure: **AWS Fargate (serverless)** → **Create**

> ⚠️ If you see **"Unable to assume the service linked role"**, the cluster creation didn't actually finish — go back to **Part 0**, create the role, wait ~30 seconds, then delete the half-created cluster (if any) and create it again.

### 3b. Task Definition (describes how to run your container)
1. ECS → **Task definitions** → **Create new task definition**
2. Family name: **`sample-task`**
3. Launch type: **Fargate**
4. CPU `.25 vCPU`, Memory `.5 GB` (smallest = cheapest)
5. Container:
   - Name: **`sample-app`**  ← must match `CONTAINER_NAME` later
   - Image URI: paste your ECR URI + `:latest` (e.g. `...amazonaws.com/sample-app:latest`)
   - Port mappings: container port **`3000`**, protocol TCP
6. **Logging: leave "Use log collection" / CloudWatch logs turned ON.** This is what lets you see *why* a task crashed later. Without logs, a failing task gives you almost nothing to debug.
7. **Create**

> **Two roles to know about:**
> - **`ecsTaskExecutionRole`** — AWS offers to auto-create this the first time; **let it**. This role lets ECS pull your image from ECR and write logs to CloudWatch. If it's missing, your task will fail to start with a "pull image" or "unable to retrieve" error.
> - The **service-linked role** from Part 0 is separate — that one is for the cluster itself.

### 3c. Service (keeps your app running)
1. Open your **`sample-cluster`** → **Services** tab → **Create**
2. Launch type: **Fargate**
3. Task definition: **`sample-task`** (latest revision)
4. Service name: **`sample-service`**
5. Desired tasks: **1**
6. Networking:
   - Use your default VPC and its subnets (these have a route to the internet, which Fargate needs to pull the image from ECR)
   - Security group → **Create new** → add an **inbound rule**: type *Custom TCP*, port **3000**, source `0.0.0.0/0` (for testing only)
   - **Public IP: Turn ON** — required here for two reasons: it's how you'll reach the app without a load balancer, **and** in a default VPC it's how Fargate reaches ECR to pull the image. If this is OFF, the task often gets stuck and can't pull the image.
7. **Create**

After ~1 minute: Service → **Tasks** → click the running task → find the **Public IP** → open `http://<public-ip>:3000` in your browser. You should see **"Hello from ECS! 🚀 v1"**.

> If the task isn't running, click it → **Logs** tab (CloudWatch) and the **Stopped reason** at the top of the task page. Those two places tell you exactly what went wrong — see Troubleshooting below.

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

> If the connection shows **"Pending"**, click into it and finish the authorization handshake until its status is **"Available"** — a pending connection silently blocks the Source stage.

### Step 3: Build

Provider: **AWS CodeBuild** → **Create project** (opens the "Create build project" page). Fill it in top to bottom — the two settings people miss (Privileged + environment variables) are near the bottom under a collapsed section, so don't jump to "Continue" early.

1. **Project name** — `sample-build`.
2. **Project type** — leave **Default project** (not Runner project).
3. **Environment image** — **Managed image**.
4. **Compute** — choose **EC2**, *not* Lambda. Lambda compute can't run privileged Docker builds, so `docker build` would fail. EC2 is required for building images.
5. **Running mode** — leave **Container**. **Operating system** **Amazon Linux**, **Runtime** **Standard**, **Image** the latest `aws/codebuild/amazonlinux-x86_64-standard:*`, **Image version** "Always use the latest" — all fine as defaulted.
6. **Service role** — **New service role**, name `codebuild-sample-build-service-role`. **Note this name down** — you attach an ECR permission to it in Part 5, and the build can't push without it.
7. **Expand "Additional configuration"** — this section is collapsed and holds the two critical settings:
   - **Privileged** — turn **ON**. Required, or `docker build` fails. (Leave the newer "Docker server" option unchecked; the privileged flag is all you need.)
   - **Environment variables** (Type = Plaintext for all three):

     | Name | Value |
     |---|---|
     | `AWS_ACCOUNT_ID` | your 12-digit account ID |
     | `IMAGE_REPO_NAME` | `sample-app` |
     | `CONTAINER_NAME` | `sample-app` |

8. **Buildspec** — select **Use a buildspec file**. Leave the name blank so it reads `buildspec.yml` from your repo root.
9. **Logs** — leave **CloudWatch logs** as-is (default is fine; it helps you debug failed builds).
10. **Continue to CodePipeline** → Next.

Compute size (2 vCPUs / 4 GiB) and everything else can stay at defaults.

### Step 4: Deploy
- Provider: **Amazon ECS**
- Cluster: **`sample-cluster`**
- Service: **`sample-service`**
- Image definitions file: **`imagedefinitions.json`** (leave default) → Next → **Create pipeline**

---

## Part 5 — One Last Permission Fix (important!)

CodeBuild needs permission to push to ECR. The auto-created build role doesn't have it yet.

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
| **Cluster fails: "Unable to assume the service linked role"** | The `AWSServiceRoleForECS` role doesn't exist. Run `aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com` (Part 0), wait ~30s, retry. |
| Build fails at `docker build` | "Privileged" mode wasn't enabled on the CodeBuild project |
| Build fails pushing to ECR | Attach `AmazonEC2ContainerRegistryPowerUser` to the CodeBuild role (Part 5) |
| Deploy fails / "container name not found" | `CONTAINER_NAME` env var ≠ container name in the task definition — both must be `sample-app` |
| **Task fails to start / "unable to pull image"** | Either Public IP is OFF (task can't reach ECR), or `ecsTaskExecutionRole` is missing/lacks ECR access. Turn Public IP ON and make sure that role exists. |
| **Task keeps stopping right after starting** | Open the task → check **Stopped reason** and the **Logs (CloudWatch)** tab. Usually a container crash or the port (3000) not matching your app's listening port. |
| Can't open the app in browser | Security group missing inbound rule for port 3000, or task has no public IP |
| Source stage stuck / won't trigger | GitHub connection is still "Pending" — finish authorizing it until it shows "Available" |
| Everything in different regions | Recreate so ECR, ECS, CodeBuild, and CodePipeline are all in the same region |

## Don't Forget to Clean Up (avoid charges)
Delete in this order: CodePipeline → CodeBuild project → ECS service → ECS cluster → ECR repository → the GitHub connection. (You can also delete the auto-created IAM roles afterward if you won't reuse them.)
