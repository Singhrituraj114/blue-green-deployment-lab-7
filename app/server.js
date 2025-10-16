const express = require('express');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.VERSION || '1.0.0';
const COLOR = process.env.COLOR || 'unknown';

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

// Main endpoint
app.get('/', (req, res) => {
    res.json({
        message: 'Blue-Green Deployment Demo',
        version: VERSION,
        color: COLOR,
        hostname: os.hostname(),
        platform: os.platform(),
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    });
});

// Version endpoint
app.get('/version', (req, res) => {
    res.json({
        version: VERSION,
        color: COLOR,
        buildNumber: process.env.BUILD_NUMBER || 'unknown'
    });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Version: ${VERSION}`);
    console.log(`Color: ${COLOR}`);
});
