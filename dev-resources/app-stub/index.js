const express = require('express')
const app = express()
const port = 5000
const fs = require('fs')
const version = fs.readFileSync('./version')
const { runQuery } = require('./db')

function env() {
  const env = Object.keys(process.env)
    .filter(key => !key.startsWith('npm_'))
    .reduce(
      (accum, key) => ({
        ...accum,
        [key]: process.env[key]
      }),
      {}
  )
  return JSON.stringify(env, null, '\t')
}

app.get('*', async (_req, res) => {
  const migrations = JSON.stringify(
    await runQuery('select * from migrations'),
    null,
    "\t"
  )

  res.send(
    [
      `<h2>Test Review App version ${version}</h2>`,
      `<h4>Environment</h4>`,
      `<pre>${env()}</pre>`,
      `<h4>Migrations</h4>`,
      `<pre>${migrations}</pre>`,
    ].join('\n')
  )
})

app.listen(port, () => console.log(`Example app listening at http://0.0.0.0:${port}`))
