from flask import Blueprint, jsonify
from .models import Fortune

main = Blueprint("main", __name__, url_prefix="/api")

@main.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

@main.route("/dailyFortune", methods=["GET"])
def getDaily():
    fortune = Fortune.getDailyFortune()
    return jsonify(
        {
            "text": fortune.text,
            "author": fortune.author
        }
    )

@main.route("/randomFortune", methods=["GET"])
def getRandom():
    fortune = Fortune.getRandomFortune()
    return jsonify(
        {
            "text": fortune.text,
            "author": fortune.author
        }
    )