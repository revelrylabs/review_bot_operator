const fs = require("fs")
const version = fs.readFileSync("./version")
const { runQuery } = require("./db")

console.log(`running migration version ${version}`)
runQuery(
  "insert into migrations(id, applied_at) values($1::text, now());",
  version
).then(response => console.log(response))
