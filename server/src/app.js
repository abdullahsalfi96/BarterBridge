// Import Express framework
const express = require('express')

// Import CORS middleware
const cors = require('cors')

// Import Helmet security middleware
const helmet = require('helmet')

// Create Express application
const app = express()

// Apply Helmet middleware
// Adds security-related HTTP headers
app.use(helmet())

// Apply CORS middleware
// Allows frontend apps to access backend
app.use(cors())

// Parse incoming JSON automatically
app.use(express.json())

// Health check route
app.get('/health', (req, res) => {

    res.json({
        status: 'ok',
        message: 'BarterBridge API running'
    })
})

// Export app
module.exports = app