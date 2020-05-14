const express = require('express')
const { WebClient } = require('@slack/web-api');
const { createEventAdapter } = require('@slack/events-api');

var array=[];
// Read a token from the environment variables
const token = process.env.SLACK_TOKEN || 'xoxb-508424999907-1039361926867-Y232JXDeuItrVDAfQguqi0JL';

 // Read the signing secret from the environment variables
const slackSigningSecret = process.env.SLACK_SIGNING_SECRET || 'dcfa8a4261bf20eede557332185cad95';
 
const app = express()
const slackEvents = createEventAdapter(slackSigningSecret)

app.use('slack/events', slackEvents.expressMiddleware);
//const bodyParser = require('body-parser')

const web = new WebClient(token);

const port = process.env.PORT || 3000;


app.use(express.json())

app.get('/', (req, res) => res.send('test'))
app.get('/slack/events', (req, res) => res.send('test'))

app.post('/slack/events', (req, res) => {
  res.send(req.body.challenge)
  console.log(req.body)
  if (req.body.event.type=='app_mention') {
    web.chat.postMessage({channel: 'groceries', text: 'tanisha sucks'})
    console.log(req.body)}})
    //array.push(req.body.event.text)
    //web.chat.postMessage({channel: 'groceries', text: array.toString()})}})

//web.chat.postMessage({channel: 'groceries', text: 'tanisha sucks'})

app.listen(port, () => console.log(`Example app listening at http://localhost:${port}`))
