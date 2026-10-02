const JSDOM = require('jsdom').JSDOM;
const html = require('fs').readFileSync('_site/en/index.html', 'utf8');
const dom = new JSDOM(html, { runScripts: "dangerously" });
console.log("Scripts executed");
