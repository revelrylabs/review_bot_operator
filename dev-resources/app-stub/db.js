const { Client } = require('pg')

const getClient = () => {
  const config = {
    user: process.env.POSTGRES_USER,
    host: process.env.POSTGRES_HOSTNAME,
    database: process.env.POSTGRES_DATABASE || 'postgres',
    password: process.env.POSTGRES_PASSWORD,
    port: 5432,
  }
  return config.user && config.host && config.password ? new Client(config) : undefined;
}

const runQuery = async (query, args = []) => {
  const client = getClient();
  if (!client) {
    return {
      status: 'error',
      message: 'Query could not be executed. DB connection data was incomplete.'
    }
  }

  const cleanArgs = Array.isArray(args) ? args : [args]

  await client.connect()
  const res = await client.query(query, cleanArgs);
  await client.end()
  return res.rows
}

module.exports = {
  runQuery,
}
