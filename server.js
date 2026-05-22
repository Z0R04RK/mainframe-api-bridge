const express = require('express')
const cors = require('cors')
const {execFile} = require('child_process')

const app = express();
app.use(cors());
app.use(express.json());

const PORT = 5000;

app.get('/api/accounts/:id', (req, res) => {
    const accountId = req.params.id;

    if (!/^\d{8}$/.test(accountId)) {
        return res.status(400).json({ error: "Invalid account number format. Must be 8 digits." });
    }

    // Execute the compiled COBOL binary directly
    execFile('./ACCTINQ', [accountId], (error, stdout, stderr) => {
        if (error) {
            console.error("Execution error:", error);
            return res.status(500).json({ error: "Internal server error connecting to legacy core" });
        }

        // Clean any trailing line breaks from the standard output
        const output = stdout.trim();

        // Route the known COBOL error codes
        if (output === '404:ACCOUNT NOT FOUND') {
            return res.status(404).json({ error: "Account record not found in system" });
        }

        if (output.startsWith('500:')) {
            return res.status(500).json({ error: "Legacy sequential dataset unavailable" });
        }

        // Process the successful 200 payload
        const parts = output.split(':');

        if (parts[0] === '200' && parts.length === 9) {
            // Reconstruct the raw COBOL string into a structured JSON object
            const responseJson = {
                status: "success",
                data: {
                    accountNumber: parts[1],
                    branchCode: parts[2],
                    accountType: parts[3],
                    // .trim() strips the hardcoded 20/8 char space padding from the fixed-width file
                    customerName: parts[4].trim(), 
                    accountStatus: parts[5].trim(),
                    // Convert the raw string pennies into proper decimals (000450075 -> 4500.75)
                    ledgerBalance: (parseInt(parts[6], 10) / 100).toFixed(2),
                    availableBalance: (parseInt(parts[7], 10) / 100).toFixed(2),
                    lastActivityDate: parts[8] // Format YYYYMMDD
                }
            };
            return res.json(responseJson);
        }

        // Fallback for bad output
        return res.status(502).json({ error: "Invalid payload received from legacy system" });
    });

});

app.listen(PORT, () => {
    console.log(`Mainframe API Bridge running on http://localhost:${PORT}`);
});
