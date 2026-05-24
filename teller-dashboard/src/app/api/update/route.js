import fs from 'fs';
import path from 'path';

//Makes node work with self-signed certs for the student mainframe
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

export async function POST(request) {
    const { accountId, newStatus } = await request.json();

    //Have to ensure that they are 8-bytes
    const targetId = accountId.padEnd(8, ' ');
    const status = newStatus.padEnd(8, ' ');

    //Reads the JCL blueprint from the root folder and takes it from drive
    //and into active memory as a large string
    const jclPath = path.join(process.cwd(), '..', 'JCL', 'RUN.JCL');
    let jclText = fs.readFileSync(jclPath, 'utf8');

    //Regex to replace the default params
    const parmRegex = /PARM='.*'/;
    jclText = jclText.replace(parmRegex, `PARM='${targetId}${status}'`);

    //This is where we are using the Job Entry Subsystem (JES2)
    const url = 'https://204.90.115.200:10443/zosmf/restjobs/jobs';

    //not encryption just avoiding sending raw binary and having it be corrupted during transmission
    const auth = Buffer.from(`${process.env.MF_USER}:${process.env.MF_PASSWORD}`).toString('base64');

    try {
        const response = await fetch(url, {
            method: 'PUT',
            body: jclText,
            headers: {
                'Content-Type': 'text/plain',
                'Authorization': `Basic ${auth}`,
                'X-CSRF-ZOSMF-HEADER': 'true'
                //proves to mainframe that this comes form custom application code layer and
                //not a malicious script from a browser
            }
        });

        //doing this as raw txt to avoid parsing error
        const responseText = await response.text();

        if (response.ok) {
            const data = JSON.parse(responseText);
            console.log(`[API] Success. Job ID: ${data.jobid}`);
            return Response.json({ success: true, jobId: data.jobid });
        } else {
            // Log the mainframe error
            console.error(`[ZOSMF ERROR] HTTP ${response.status}:`, responseText);
            return Response.json({ success: false, error: `Mainframe rejected: HTTP ${response.status}` }, { status: 500 });
        }
    } catch (error) {
        console.error(`[NETWORK FATAL]`, error.message);
        return Response.json({ success: false, error: error.message }, { status: 500 });
    }
}