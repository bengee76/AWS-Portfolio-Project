import boto3, random
from flask import Flask, render_template
from apscheduler.schedulers.background import BackgroundScheduler

dynamodb = boto3.resource('dynamodb', region_name='eu-central-1')
table = dynamodb.Table('coockieTable')

app = Flask(__name__)

dailyFortune = {}
usedFortunes = []

def rollFortune():
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
scheduler.add_job(func=rollFortune, trigger="cron", hour=0, minute=0)
scheduler.start()

@app.route('/')
def index():
    if not dailyFortune:
        rollFortune()
    return render_template('index.html', dailyFortune=dailyFortune)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)