# Dockerfile: Introduction and Demo

A Dockerfile is a plain text script of instructions that tells Docker how to build an image — a self-contained, reproducible snapshot of your application along with its runtime, libraries, and system dependencies. Once built into an image, it can run identically on any machine that has Docker, which is what solves the classic "works on my machine" problem.

You can think of it as a recipe. Each line is a step, and Docker executes them top to bottom, producing a layered image where every instruction adds a cached layer.

## Core instructions

The handful you'll use most often:

- `FROM` — the base image you start from (e.g. `python:3.12-slim`). Every Dockerfile begins here.
- `WORKDIR` — sets the working directory inside the image for the commands that follow.
- `COPY` — copies files from your machine into the image.
- `RUN` — executes a command at build time (installing packages, etc.). Each `RUN` creates a new layer.
- `ENV` — sets environment variables.
- `EXPOSE` — documents which port the app listens on.
- `CMD` — the default command run when the container starts. Unlike `RUN`, this happens at runtime.

A subtle but important distinction: `RUN` happens while building the image; `CMD` happens when you launch a container from that image.

## Demo: containerizing a small web app

Let's containerize a tiny Python Flask app. Three files in one folder.

**`app.py`**

```python
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello from inside a Docker container!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

**`requirements.txt`**

```
flask
```

**`Dockerfile`**

```dockerfile
# 1. Start from a lightweight official Python image
FROM python:3.12-slim

# 2. Set the working directory inside the container
WORKDIR /app

# 3. Copy dependency list first (better layer caching)
COPY requirements.txt .

# 4. Install dependencies at build time
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy the rest of the app code in
COPY . .

# 6. Document the port the app uses
EXPOSE 5000

# 7. Command that runs when the container starts
CMD ["python", "app.py"]
```

## Build and run

From the folder containing those files:

```bash
# Build an image named "myapp"
docker build -t myapp .

# Run a container, mapping your machine's port 5000 to the container's
docker run -p 5000:5000 myapp
```

Then open `http://localhost:5000` in your browser and you'll see the greeting served from inside the container.

A few commands worth knowing alongside this:

```bash
docker images          # list images you've built
docker ps              # list running containers
docker stop <id>       # stop a running container
docker run -d -p 5000:5000 myapp   # run detached (in the background)
```

## Note for macOS users

Port 5000 is often occupied by the macOS AirPlay Receiver. If you hit a "port already in use" error or a 403 page at `localhost:5000`, map to a different host port instead:

```bash
docker run -p 5001:5000 myapp
```

The format is `-p HOST_PORT:CONTAINER_PORT` — the left number is what you type in the browser (`localhost:5001`), and the right number must match the port the app listens on inside the container (5000). Alternatively, turn off AirPlay Receiver under **System Settings → General → AirDrop & Handoff** to free up port 5000.
