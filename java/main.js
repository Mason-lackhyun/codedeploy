require('dotenv').config();
const { IncomingWebhook } = require('@slack/webhook');
const url = "https://hooks.slack.com/services/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";
const webhook = new IncomingWebhook(url);
const scrape = require('./scrape');
const cronJob = require('cron').CronJob;

const sendToSlack = async() => {
    const weather = await scrape.getWeather()
    const tomorrowAverTemp = weather.tomorrowAverTemp
    const formattedMessage = scrape.createMessage(tomorrowAverTemp)
    const message = scrape.formatMessage(weather.location, weather.todayLowTemp, weather.todayHighTemp, weather.tomorrowLowTemp, weather.tomorrowHighTemp, formattedMessage)
    webhook.send(message);
}

new cronJob('30 52 3 * * *',  () => {
    sendToSlack();
},null,true,"Asia/Seoul")
