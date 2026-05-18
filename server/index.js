// Load environment variables
require('dotenv').config()

// Import Express application
const app = require('./src/app')

// Import PostgreSQL connection pool
const pool = require('./src/config/database')

// Get PORT from environment variables
const PORT = process.env.PORT || 5000

// Test PostgreSQL database connection
pool.query('SELECT NOW()')

    .then((result) => {

        console.log('Database connected successfully')

        console.log('Database time:', result.rows[0].now)

        // Start Express server
        app.listen(PORT, () => {

            console.log('Server running on port ${PORT}')
        })
    })

    .catch((error) => {

        console.error('Database connection failed')

        console.error(error)

        // Exit Node.js process with failure code
        process.exit(1)
    })