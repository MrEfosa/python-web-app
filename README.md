# Cloud-Native Django CI/CD Pipeline Architecture

An enterprise-grade, fully automated DevOps pipeline designed to build, optimize, and deploy a containerized Python Django application to an AWS cloud environment. This project covers the entire infrastructure lifecycle: from bootstrapping the initial automation server with automated Bash tooling, to managing continuous integration with Jenkins, up to executing automated remote container deployments on AWS EC2.

---

## Architecture Overview

The automation workflow runs seamlessly across decoupled environments:

* **Host Provisioning:** A custom shell script bootstraps a clean Linux distribution with Docker, Docker Compose, and localized server dependencies.
* **Version Control:** Code commits pushed to GitHub trigger a webhook notification to the automation server.
* **Continuous Integration (Jenkins):** A multi-stage Declarative pipeline automates environment building and image optimization layers.
* **Artifact Registry (Docker Hub):** Compiled images are tagged dynamically and securely pushed to a centralized container registry.
* **Continuous Deployment (AWS EC2):** Jenkins opens a secure SSH tunnel to an AWS EC2 production instance, manages container lifecycles, pulls the latest application artifact, and executes an automated zero-downtime hotfix rollout.

---

## Tech Stack & Tools

* **Application Framework:** Python / Django
* **CI/CD Automation:** Jenkins (Declarative Pipelines)
* **Containerization & Orchestration:** Docker / Docker Compose / Docker CLI
* **Cloud Infrastructure:** AWS (EC2, IAM, Security Groups)
* **Automation Scripting:** Bash / Shell

---

## Automated Host Provisioning

The automation controller environment is provisioned deterministically utilizing a dedicated bash initialization script (`setup-jenkins.sh`). This completely eliminates configuration drift and ensures reproducible server setup environments across the development pipeline.

The infrastructure configuration script automates the following systems engineering milestones:
* **Package Architecture Initialization:** Synchronizes internal operating system tracking and pushes mandatory security upgrades to the host.
* **Container Core Provisioning:** Integrates Docker Engine and the native Docker Compose Plugin runtime layers into the core OS.
* **Volume Persistence Orchestration:** Configures localized root tracking paths and structures a persistent configuration mapping for the automation engine.
* **Daemon Level Inter-process Communication:** Mounts the host's UNIX socket `/var/run/docker.sock` straight into the isolated Jenkins container matrix. This Docker-out-of-Docker (DooD) architecture grants Jenkins the capability to spin up sibling application containers natively on the host platform without running nested container architectures.
* **Dynamic Pipeline Core Execution:** Executes a root-level inline container patch directly inside the active Jenkins runtime instance, embedding execution dependencies inside the continuous integration pipeline environment.
---

## Pipeline Stages & Implementation Details

### 1. Source Code Management (SCM)
The pipeline automatically tracks the repository branch, checking out the fresh codebase code on every commit event.

### 2. Docker Image Build & Optimization
The workflow builds a custom Docker image utilizing optimized base layers (`python-slim`) to keep runtime execution fast and significantly reduce attack surfaces.

### 3. Secure Registry Distribution
Authenticates securely against Docker Hub utilizing masked Jenkins system variables and streams via `--password-stdin` to safely push the immutable version-tagged container image (`${DOCKER_REPO}:${IMAGE_TAG}`).

### 4. Automated AWS EC2 Remote Deployment
Using the Jenkins `sshagent` plugin, the pipeline establishes a secure SSH handshake with the target AWS EC2 instance to execute a production rollout:
* Gracefully stops and removes previous runtime container bindings to eliminate port conflicts.
* Pulls down the newly updated image layer.
* Launches the container mapping standard routing port `80` to the internal application framework container port `8000`.
* Triggers an automated storage eviction policy (`docker image prune -f`) to delete orphaned caches and preserve disk space on the cloud server.

---

## Infrastructure Configuration Blueprint

To run this pipeline successfully, the following infrastructure dependencies must be configured:

### 1. AWS Security Group Rules
Ensure your EC2 instance firewall has the following inbound configurations open:
* **Port 22 (SSH):** Restricted to your Jenkins Server IP for secure remote code execution access.
* **Port 80 (HTTP):** Open to `0.0.0.0/0` (Anywhere) to allow live client web traffic.

### 2. Jenkins Credentials Matrix
The following credentials must be securely stored inside your global Jenkins credential vault:
* `docker-hub-credentials` (Username with Password) – For registry write-access.
* `aws-ec2-instance` (SSH Username with private key) – Containing your AWS `.pem` private key string matching the instance target deployment user (`ubuntu`/`ec2-user`).

---

## How to Access the Live Application

Once the pipeline run completes with a successful green status, you can view the live application via a web browser using the public IPv4 address assigned to your cloud server:

```text
http://<YOUR_AWS_EC2_PUBLIC_IP>
```

## Author's Note
Developed as a practical demonstration of cloud automation, continuous deployment best practices, and secure infrastructure management. Feel free to explore the Jenkinsfile and Dockerfile architectures included in this repository!
