// Force Next.js to evaluate this route dynamically on every request
export const dynamic = 'force-dynamic';

//Makes node work with self-signed certs for the student mainframe
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

export async function GET(request, { params }) {
    const resolvedParams = await params;
    const accountId = resolvedParams.accountId;
    
    // z/OSMF Data set API endpoint to read the physical dataset
    const url = `https://204.90.115.200:10443/zosmf/restfiles/ds/${process.env.MF_USER}.BANK.ACCOUNTS`;
    const auth = Buffer.from(`${process.env.MF_USER}:${process.env.MF_PASSWORD}`).toString('base64');

    try {
        console.log(`[API] Fetching live dataset from Mainframe for ID: ${accountId}...`);
        
        const mfResponse = await fetch(url, {
            headers: {
                'Authorization': `Basic ${auth}`,
                'X-CSRF-ZOSMF-HEADER': 'true'
            }
        });

        if (!mfResponse.ok) {
            return Response.json({ error: `Mainframe read failed: HTTP ${mfResponse.status}` }, { status: 500 });
        }

        const textData = await mfResponse.text();
        
        // Split the file by line and find the matching 8-character ID
        const lines = textData.split('\n');
        const record = lines.find(line => line.startsWith(accountId));

        if (!record) {
            return Response.json({ error: "Account not found on mainframe." }, { status: 404 });
        }

        // Parse the strict 68-byte COBOL layout
        const data = {
            accountNumber: record.substring(0, 8).trim(),
            branchCode: record.substring(8, 11).trim(),
            accountType: record.substring(11, 14).trim(),
            customerName: record.substring(14, 34).trim(),
            accountStatus: record.substring(34, 42).trim(),
            ledgerBalance: (parseInt(record.substring(42, 52), 10) / 100).toFixed(2),
            availableBalance: (parseInt(record.substring(52, 62), 10) / 100).toFixed(2),
            lastActivityDate: record.substring(62, 70).trim()
        };

        return Response.json({ data });

    } catch (error) {
        console.error(`[API ERROR]`, error.message);
        return Response.json({ error: error.message }, { status: 500 });
    }
}