# Simple AWS CodePipeline Tutorial (with SNS Email Notifications)

A beginner-friendly, end-to-end tutorial. You'll build a tiny pipeline that
automatically deploys a one-page website whenever you push code, and emails you
when the pipeline starts, succeeds, or fails.

We deliberately keep this **simple**: the "application" is a single HTML file,
and there is **no build stage** — the pipeline just copies your files straight
to an S3 bucket.

---

## What you'll build

```
  GitHub repo            CodePipeline                 S3 bucket
  (index.html)   ──►   Source  ──►  Deploy   ──►   (static website)
                          │
                          │  events (start / success / fail)
                          ▼
                    Notification rule
                          │
                          ▼
                       SNS topic  ──►  your email
```

Three AWS pieces, that's it:

1. **S3** — hosts the website and is the deploy target.
2. **CodePipeline** — watches GitHub and deploys to S3.
3. **SNS** — sends you an email on pipeline events.

---

## Prerequisites

- An **AWS account** with permissions for S3, CodePipeline, and SNS (an admin/free-tier account is fine).
- A **GitHub account**.
- **Git** installed locally (`git --version` to check).
- About **20–30 minutes**.

> **Cost:** Everything here fits comfortably in the AWS Free Tier. A pipeline
> costs about $1/month per *active* pipeline after the free tier; SNS email and
> a tiny S3 bucket are effectively free. Follow the **Cleanup** section at the
> end to avoid charges.

---

## Step 1 — Create the application and push it to GitHub

### 1a. Create the files locally

Make a folder and add two files.

**`index.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>My Pipeline Demo</title>
</head>
<body>
  <h1>Hello from CodePipeline! 🚀</h1>
  <p>Version 1 — deployed automatically.</p>
</body>
</html>
```

**`README.md`** (optional, just so the repo isn't empty of context)

```markdown
# Pipeline demo
A one-page site deployed by AWS CodePipeline.
```

### 1b. Push to a new GitHub repository

Create an empty repo on GitHub called `pipeline-demo` (no README, so it stays
empty), then run:

```bash
cd pipeline-demo
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<your-username>/pipeline-demo.git
git push -u origin main
```

You now have `index.html` on the `main` branch. Good.

---

## Step 2 — Create the S3 bucket (your deploy target)

This bucket will both **store** and **serve** the website.

1. Go to the **S3 console** → **Create bucket**.
2. **Bucket name:** something globally unique, e.g. `pipeline-demo-<your-initials>-2026`.
3. **Region:** pick one and remember it (e.g. `us-east-1`). Use this same region everywhere.
4. Under **Block Public Access**, **uncheck "Block all public access"** and confirm the acknowledgment. (This is a demo site meant to be public.)
5. Leave the rest as default and **Create bucket**.

### 2a. Turn on static website hosting

1. Open the bucket → **Properties** tab.
2. Scroll to **Static website hosting** → **Edit** → **Enable**.
3. **Index document:** `index.html`.
4. Save. Copy the **Bucket website endpoint** URL shown here — that's your live site.

### 2b. Add a public-read bucket policy

1. Open the bucket → **Permissions** tab → **Bucket policy** → **Edit**.
2. Paste this, replacing `YOUR-BUCKET-NAME`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
    }
  ]
}
```

3. Save.

The bucket is empty for now — the pipeline will fill it.

---

## Step 3 — Create the pipeline

1. Go to the **CodePipeline console** → **Create pipeline**.
2. **Pipeline name:** `pipeline-demo`.
3. **Execution mode:** leave the default (Queued/Superseded is fine).
4. **Service role:** choose **New service role** and let AWS create it. **Next.**

### 3a. Source stage (GitHub)

1. **Source provider:** **GitHub (via GitHub App)** — this is the recommended connection method.
2. Click **Connect to GitHub** → **Install a new app** (or use an existing connection). This opens GitHub, where you authorize AWS to access your repo. Approve it, then return to the console.
3. **Repository name:** `<your-username>/pipeline-demo`.
4. **Branch:** `main`.
5. Leave "Start the pipeline on source code change" enabled. **Next.**

> **No build needed.** Because we're deploying a plain HTML file, we skip the
> build entirely.

### 3b. Build stage

- Choose **Skip build stage** and confirm. **Next.**

### 3c. Deploy stage (S3)

1. **Deploy provider:** **Amazon S3**.
2. **Region:** the same region as your bucket.
3. **Bucket:** select the bucket you made in Step 2.
4. **Check** the box **"Extract file before deploy."** (This unzips the source
   artifact so `index.html` lands at the bucket root — without it, you'd get a
   zip file in the bucket.)
5. **Next** → review → **Create pipeline.**

The pipeline runs immediately. After a minute you should see **Source** and
**Deploy** both go green. Open your S3 website endpoint URL — you should see
**"Hello from CodePipeline!"** 🎉

---

## Step 4 — Add SNS email notifications

Now wire up email alerts for pipeline events.

1. In the **CodePipeline console**, open your `pipeline-demo` pipeline.
2. Top right, choose **Notify** → **Create notification rule**.
3. **Notification name:** `pipeline-demo-alerts`.
4. **Detail type:** **Basic** (Full also works; Basic is simpler).
5. **Events that trigger notifications** — pick a few. Good starter set:
   - Pipeline execution → **Started**
   - Pipeline execution → **Succeeded**
   - Pipeline execution → **Failed**
6. **Target:**
   - Choose **Create target** → **SNS topic**.
   - Enter a name; it will be prefixed automatically, e.g. `codestar-notifications-pipeline-demo`.
   - Choose **Create.**

> **Why this is the easy path:** when you let the notification rule create the
> SNS topic for you, AWS automatically attaches the access policy that allows
> the notifications service to publish to that topic. If you reuse an
> *existing* topic instead, you'd have to add that publish policy yourself.

7. Choose **Submit.**

### 4a. Subscribe your email to the topic

Creating the topic doesn't subscribe you yet — do this once:

1. Go to the **SNS console** → **Topics** → open `codestar-notifications-pipeline-demo`.
2. **Create subscription.**
3. **Protocol:** **Email**. **Endpoint:** your email address. **Create subscription.**
4. **Check your inbox** and click **Confirm subscription**. (Until you confirm, no emails arrive.)

> Make sure the SNS topic and the notification rule are in the **same region**.

---

## Step 5 — Test the whole thing

Change the site and push:

```bash
# edit index.html — e.g. change "Version 1" to "Version 2"
git commit -am "Update to version 2"
git push
```

Within a minute or so:

- The pipeline runs again (you'll see it in the console).
- You get a **"Started"** email, then a **"Succeeded"** email.
- Refresh your S3 website URL — it now shows **Version 2**.

Want to see a failure email? Temporarily point the deploy stage at a
non-existent bucket name and push again — you'll get a **"Failed"**
notification. (Then fix it back.)

---

## Cleanup (do this to avoid charges)

Delete in this order:

1. **CodePipeline** → delete the `pipeline-demo` pipeline.
2. **Notification rule** → in the pipeline's Settings (or Developer Tools console), delete `pipeline-demo-alerts`.
3. **SNS** → delete the `codestar-notifications-pipeline-demo` topic and its subscription.
4. **S3** → empty, then delete the bucket. CodePipeline may have created a
   second "artifact" bucket (named like `codepipeline-<region>-...`) — empty and delete that too.
5. **IAM** (optional) → delete the auto-created CodePipeline service role if you don't need it.
6. **GitHub** → delete the connection from **CodePipeline → Settings → Connections** if you're done.

---

## Troubleshooting

| Problem | Likely cause / fix |
|---|---|
| Pipeline shows green but the website is a downloaded **zip file** | You forgot **"Extract file before deploy"** in the deploy stage. Edit the stage and re-run. |
| Website URL shows **403 Access Denied** | Block Public Access is still on, or the bucket policy is missing/wrong. Recheck Step 2a/2b. |
| **No emails** arriving | You didn't **confirm** the SNS email subscription, the email went to spam, or the topic/rule are in **different regions**. |
| Source stage fails on **GitHub** | The GitHub App connection wasn't authorized, or it has no access to that repo. Recreate the connection in **Settings → Connections**. |
| "Unreachable" next to the SNS topic in the notification rule | The topic is missing the publish access policy. Easiest fix: delete it and recreate the topic *through* the notification rule so the policy is applied automatically. |

---

## Optional: alternatives to keep in mind

- **Source other than GitHub:** AWS **CodeCommit** is available to new
  customers again (it returned to general availability in late November 2025),
  so you could use a native AWS Git repo instead of GitHub and skip the
  third-party connection. GitLab and Bitbucket are also supported.
- **Add a real build:** if your app needs compiling, npm builds, tests, etc.,
  insert a **CodeBuild** stage between Source and Deploy. That's the natural
  "next step up" from this tutorial.
- **Deploy to servers/containers instead of S3:** swap the S3 deploy action for
  **CodeDeploy** (EC2/on-prem) or **ECS** for containerized apps.

---

### Quick recap

You created a static site, pushed it to GitHub, and built a pipeline that
deploys to S3 on every push — with SNS emailing you on start, success, and
failure. From here, adding a build stage or a fancier deploy target is just one
more stage in the same pipeline.
