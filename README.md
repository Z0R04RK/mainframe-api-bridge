---

# Global Core Banking: z/OS Modernization & Transaction Pipeline

An architectural proof-of-concept demonstrating a read/write bridge between a legacy COBOL backend and a modern React web interface.

This repository explores legacy data modernization across two distinct deployment environments: a localized Linux/Docker emulation, and a native IBM z/OS hardware deployment.

## The Objective

To solve an industry-standard modernization challenge: safely exposing fixed-width, sequential mainframe datasets to a modern web frontend for live updates, while enforcing basic access controls and audit logging.

---

## Dual-Architecture Strategy

This project is actively maintained across two distinct branches to demonstrate both modern cloud-native containerization and native bare-metal IBM Z infrastructure.

### Architecture A: Containerized API Emulation

**Branch:** `main` | **Status:** Complete

A fully containerized local environment simulating a mainframe backend. It utilizes GnuCOBOL—an open-source COBOL compiler—inside a Dockerized Linux runtime to execute binary read/write operations against sequential datasets, bridged to the web via a Node.js Express API.

* **Frontend:** Next.js (React) Teller Dashboard
* **Middleware:** Node.js (Express) REST API
* **COBOL Programs:** GnuCOBOL binaries compiled via Docker
* **Data Layer:** Line-sequential `.DAT` fixed-width files

### Architecture B: Native IBM z/OS Deployment

**Branch:** `phase2-zos-native` | **Status:** In Progress

Porting the validated COBOL logic directly to IBM Z hardware. This branch strips out the Docker/Linux emulation and replaces it with native mainframe architecture.

* **Job Control:** JCL for dataset allocation and program compilation
* **COBOL Programs:** IBM Enterprise COBOL for z/OS
* **Data Layer:** VSAM / Native Sequential Datasets
* **Integration:** z/OS Connect / Unix System Services (USS) API gateways

---

## Key Features (Architecture A)

Unlike standard read-only API wrappers, this localized architecture demonstrates true data mutability and tracking:

* **Bi-Directional Mutability:** Safely parses, updates, and rewrites fixed-width sequential datasets (`ACCOUNTS.DAT`) without corrupting byte alignment.
* **Simulated Role-Based Access (RBAC):** Uses a simplified frontend toggle (Teller vs. Manager) passed through the Node.js middleware to demonstrate how an enterprise system would reject unauthorized update attempts before invoking the COBOL binaries.
* **Transaction Audit Logging:** Every update attempt—successful or unauthorized—is recorded with timestamps, target IDs, and user roles to an isolated `AUDIT.log` text file.
* **State-Aware UI:** The Next.js dashboard dynamically renders account statuses (Active, Frozen, Closed) and financial metrics based on real-time queries to the COBOL backend.

---

## Quick Start (Running the Docker Bridge)

To spin up the Phase 1 localized container architecture on your machine:

**1. Clone the repository and navigate to the project root:**

```bash
git clone https://github.com/Z0R04RK/mainframe-api-bridge.git
cd mainframe-api-bridge

```

**2. Build the Docker image:**

```bash
docker build -t mainframe-api-bridge .

```

**3. Run the container with absolute volume mounts (ensures live data reloading and audit logging):**

```bash
# Note: Update the path to match your local absolute directory
docker run -p 5000:5000 -d \
  --name legacy-core \
  -v "$(pwd)/ACCOUNTS.DAT:/app/ACCOUNTS.DAT" \
  -v "$(pwd)/AUDIT.log:/app/AUDIT.log" \
  mainframe-api-bridge

```

**4. Launch the Frontend:**
Open a second terminal, navigate to the `teller-dashboard` directory, and start the Next.js server:

```bash
cd teller-dashboard
npm install
npm run dev

```

Navigate to `http://localhost:3000` to interact with the teller UI.

---

## About the Author

**Jack Postlewaite**

* B.S. Computer Science and Engineering, University of California, Merced
* **Credentials:** Achieved the IBM Z Xplore All-Star badge in a 4-day sprint after discovering and becoming interested in mainframes.
* **Project Origin:** Followed up on the IBM Z Xplore curriculum by immediately applying the knowledge and using it with prior software engineering skills from college to build this enterprise bridge.

---