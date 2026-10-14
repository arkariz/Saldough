const admin = require('firebase-admin');
const fs = require('fs');

// Fetch credential from GitHub Actions environment variable
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);

if (serviceAccount.private_key) {
    serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
}

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

async function updateConfig() {
    const remoteConfig = admin.remoteConfig();

    try {
        console.log('Fetching active template...');
        const template = await remoteConfig.getTemplate();
        
        // Read markdown file
        const noteId = fs.readFileSync('release_notes/id.md', 'utf8');
        const noteEn = fs.readFileSync('release_notes/en.md', 'utf8');
        
        // Updating release note parameter
        template.parameters['latest_release_note_id'] = {
            defaultValue: { value: noteId },
            description: 'Release note ID from GitHub Actions'
        };
    
        template.parameters['latest_release_note_en'] = {
            defaultValue: { value: noteEn },
            description: 'Release note EN from GitHub Actions'
        };
    
        // Validation and Publication
        const validated = await remoteConfig.validateTemplate(template);
        const published = await remoteConfig.publishTemplate(validated);
        
        console.log('✅ Remote Config updated!');
        console.log('ETag New:', published.etag);
    } catch (error) {
        console.error('❌ Failed Updating Remote Config:', error);
        process.exit(1);
    }
}

updateConfig();