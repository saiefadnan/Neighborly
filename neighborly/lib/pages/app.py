from flask import Flask, request, jsonify
import numpy as np
import nltk
nltk.download('punkt')
nltk.download('wordnet')
import json
import random
from tensorflow.keras.models import load_model
from nltk.stem import WordNetLemmatizer
from flask_cors import CORS

# Initialize
app = Flask(__name__)
CORS(app)
lemmatizer = WordNetLemmatizer()

# Load model and data
model = load_model('my_model.keras')
intents = json.load(open('intents.json'))
words = json.load(open('words.json'))       # List of words
classes = json.load(open('classes.json'))   # List of intents

def clean_up_sentence(sentence):
    tokens = nltk.word_tokenize(sentence)
    tokens = [lemmatizer.lemmatize(w.lower()) for w in tokens]
    return tokens

def bow(sentence, words):
    sentence_words = clean_up_sentence(sentence)
    bag = [0] * len(words)
    for s in sentence_words:
        for i, w in enumerate(words):
            if w == s:
                bag[i] = 1
    return np.array(bag)

def predict_class(sentence):
    p = bow(sentence, words)
    res = model.predict(np.array([p]))[0]
    ERROR_THRESHOLD = 0.7
    results = [[i, r] for i, r in enumerate(res) if r > ERROR_THRESHOLD]
    results.sort(key=lambda x: x[1], reverse=True)
    return [{"intent": classes[r[0]], "probability": str(r[1])} for r in results]

def get_response(intents_list):
    if len(intents_list) == 0:
        return "I'm not sure I understand. Try again."
    tag = intents_list[0]['intent']
    for intent in intents['intents']:
        if intent['tag'] == tag:
            return random.choice(intent['responses'])

@app.route("/chat", methods=["POST"])
def chat():
    data = request.get_json()
    message = data.get("message", "")
    intents_list = predict_class(message)
    response = get_response(intents_list)
    return jsonify({"response": response})

if __name__ == "__main__":
    app.run(debug=True)
