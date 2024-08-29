from io import BytesIO
import json
import requests
from PIL import Image


def download(card):
    code = card["code"]
    pack = card["pack_code"].lower()

    url = f"https://ringsdb.com/bundles/cards/{code}.png"
    local_file = f"assets/database/scans/{pack}/{code}.png"

    print(f"Downloading {code} to {local_file}")

    response = requests.get(url)
    if response.status_code == 200:
        img = Image.open(BytesIO(response.content))
        img.save(local_file, 'JPG')


file_path = "assets/database/jsons/cards.json"
json_string = open(file_path, encoding="UTF-8").read()
cards = json.loads(json_string)

print(len(cards))

MAX_CARDS = 100
for i, card in enumerate(cards[:MAX_CARDS]):
    if (card["pack_code"] != "Core"):
        break
    
    download(card)