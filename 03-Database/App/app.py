import boto3, random
from flask import Flask, render_template, redirect, url_for
from apscheduler.schedulers.background import BackgroundScheduler

dynamodb = boto3.resource('dynamodb', region_name='eu-central-1')
table = dynamodb.Table('coockieTable')

app = Flask(__name__)

dailyFortune = {}
fortune = {}
usedFortunes = []

def rollDailyFortune():
    global dailyFortune, usedFortunes

    pool = []

    response = table.query(
        KeyConditionExpression=boto3.dynamodb.conditions.Key('isPremade').eq('premade') #roll for only premade fortune as daily
    )
    items = response.get('Items')
    for i, item in enumerate(items):
        if item['coockieId'] not in usedFortunes:
            pool.append(items[i])

    if not pool:
        usedFortunes = []
        pool = items.copy()

    dailyFortune = random.choice(pool)
    usedFortunes.append(dailyFortune['coockieId'])

scheduler = BackgroundScheduler()
scheduler.add_job(func=rollDailyFortune, trigger="cron", hour=0, minute=0)
scheduler.start()

def rollFortune():
    global fortune
    response = table.scan() #roll for all fortunes
    items = response.get('Items')

    fortune = random.choice(items)


@app.route('/', methods=['GET'])
def index():
    if not dailyFortune:
        rollDailyFortune()
    return render_template('index.html', dailyFortune=dailyFortune)

@app.route('/random', methods=['GET'])
def rand():
    rollFortune()
    return render_template('random.html', fortune=fortune)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)