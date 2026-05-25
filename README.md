# z/OS Mainframe Modernization: Pseudo Banking Example

A proof-of-concept project demonstrating how to securely connect a legacy IBM mainframe backend to a modern React web interface. 

Instead of just acting as a read-only data wrapper, this repository explores how to safely handle updates to fixed-width sequential z/OS datasets and batch processing (JCL) to a frontend while enforcing strict API-level access controls.

## Dual-Architecture Strategy

This project is maintained across two distinct branches to demonstrate both native hardware integration and local emulation:

* **Branch: `main` (Active)**
  The branch running directly against **native IBM Z hardware**. It uses Next.js to handle both the React frontend and the secure server-side mainframe communication via z/OSMF.
* **Branch: `phase1-docker-emulation` (Legacy)**
  A fully containerized local environment using GnuCOBOL and Node.js to simulate a mainframe backend without needing actual IBM hardware.

## System Flow (Native z/OS Architecture)

1. **Data Retrieval (Read):** The Next.js API bypasses SQL, using z/OSMF REST protocols to read native sequential datasets directly. It parses the raw flat-file datasets, slices the fixed-width strings based on the COBOL copybook layout, formats the decimals, and delivers clean JSON to the frontend.
2. **Job Execution (Write):** The backend intercepts UI payloads, enforces exact 8-byte string padding to prevent memory corruption, dynamically injects the parameters into a JCL blueprint, and submits the batch job directly to the JES2 execution spool.
3. **Payload Delivery:** Implements mandatory z/OSMF anti-forgery headers (`X-CSRF-ZOSMF-HEADER`) to ensure payloads are securely accepted by the mainframe.

## Key Features

* **Data Mutability:** Instead of relying on read-only endpoints, the backend actively manipulates JCL files in memory to pass dynamic `PARM` arguments to compiled COBOL binaries.
* **Foundational Access Control:** Demonstrates API-level security by locking UI elements based on the active session (Teller vs. Manager). While a production enterprise environment would tie this directly into RACF security groups, this proof-of-concept successfully drops unauthorized payloads at the Next.js API layer with a 403 Forbidden before they reach the mainframe network.
* **Batch Job Timing (No CICS):** Since this uses batch jobs (JES2) instead of real-time CICS, the frontend automatically delays its refresh cycle just long enough for the mainframe to finish writing to the physical disk.

## Quick Start

Because the `main` branch interfaces with live IBM Z hardware, Docker emulation is no longer required. The entire stack runs natively via Next.js.

**0. Mainframe Infrastructure Setup (One-Time)**

Before starting the Next.js server, the physical z/OS environment must be initialized. The `/JCL` folder contains the Infrastructure-as-Code required to allocate the datasets and compile the COBOL binaries.

1. Open `ALLOCATE.JCL`, `ALLOCPDS.JCL`, and `COMPILE.JCL`.
2. Perform a global Find & Replace, changing `{{HLQ}}` to your specific IBM Z user ID (e.g., `Z12345`).
3. Submit the jobs via Zowe Explorer or ISPF to physically allocate your `BANK.ACCOUNTS` dataset and compile the `ACCTUPD` executable into your load library.

**1. Clone the repository and navigate to the application folder:**
```bash
git clone [https://github.com/Z0R04RK/mainframe-api-bridge.git](https://github.com/Z0R04RK/mainframe-api-bridge.git)
cd mainframe-api-bridge/teller-dashboard
```

**2. Configure Mainframe Credentials:**
Create a `.env` file inside the `teller-dashboard` directory to securely store your routing parameters.
```env
MF_USER=Z12345
MF_PASSWORD=your_mainframe_password
```

**3. Install Dependencies:**
```bash
npm install
```

**4. Boot the Application:**
```bash
npm run dev
```
Navigate to `http://localhost:3005` to access the live dashboard.

## About the Project

**Jack Postlewaite**
* B.S. Computer Science and Engineering, University of California, Merced
* **Credentials:** Achieved the IBM Z Xplore All-Star badge in a 4-day sprint after discovering and becoming interested in mainframes.
* **Project Origin:** Followed up on the IBM Z Xplore curriculum by immediately applying the knowledge and using it with prior software engineering skills from college to build this enterprise bridge.
