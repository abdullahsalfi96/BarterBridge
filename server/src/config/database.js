// Import Pool class from pg package
const { Pool } = require('pg')

// Load environment variables from .env file
require('dotenv').config()

// Create PostgreSQL connection pool
const pool = new Pool({
    host: process.env.DB_HOST,

    port: process.env.DB_PORT,

    database: process.env.DB_NAME,

    user: process.env.DB_USER,

    password: process.env.DB_PASSWORD
})

// Export pool so other files can use it
module.exports = pool