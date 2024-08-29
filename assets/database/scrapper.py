from io import BytesIO
import json
import os
import requests
from PIL import Image
from bs4 import BeautifulSoup
from unidecode import unidecode
import unicodedata


def set_html_file(name: str):
    return f"assets/database/htmls/{name}.html"

def set_json_file(name: str):
    return f"assets/database/jsons/{name}.json"

def local_image_file(id: int):
    return f"assets/database/scans/raw/CardGame.Tools/Revised Core Set/{id}.jpg"

def local_final_image_file(id: int):
    return f"assets/database/scans/final/Revised Core Set/{id}.png"

def download_set_html(set_name: str):
    url_encoded_set = set_name.replace(" ", "+")
    url = f"https://hallofbeorn.com/LotR?DeckType=Encounter&CardSet={url_encoded_set}&Sort=Set_Number&Lang=EN"

    response = requests.get(url)
    with open(set_html_file(set_name), "w", encoding="UTF-8") as file:
        file.write(response.text)


def parse_set_html(set_name: str):
    html_file = set_html_file(set_name)

    with open(html_file, "r", encoding="UTF-8") as file:
        html_content = file.read()

        # Parse the HTML content using BeautifulSoup
        soup = BeautifulSoup(html_content, 'html.parser')

        # Find all the search result divs
        results = soup.find_all('div', id=lambda x: x and x.startswith('search-result-'))

        # List to store parsed entries
        entries = []

        print("Results: ", len(results))

        card_id = 74
        # Iterate over each result div
        for result in results:
            entry = {}

            entry['id'] = card_id
            card_id += 1
            
            # Extract name
            name_tag = result.find('a', href=True)
            entry['name'] = name_tag.text.strip()
            entry['set'] = set_name

            # Extract encounter set
            encounter_set_tag = result.find('div', class_='d-inline-block bg-secondary border border-danger border-1')
            entry['encounter_set'] = encounter_set_tag.find('img')['src'].split('/')[-1].replace('-', ' ').replace('.png', '') if encounter_set_tag else ''

            # Extract threat cost
            threat_cost_tag = result.find('span', class_='threat-cost')
            entry['threat_cost'] = int(threat_cost_tag.text.strip()) if threat_cost_tag else 0

            # Extract stats
            stats = result.find_all('span', class_='stat-wrapper d-block')
            entry['threat'] = int(stats[0].find('span', class_='stat-text').text.strip()) if stats else 0
            entry['attack'] = int(stats[1].find('span', class_='stat-text').text.strip()) if len(stats) > 1 else 0
            entry['defense'] = int(stats[2].find('span', class_='stat-text').text.strip()) if len(stats) > 2 else 0
            
            # Extract hitpoints (different class)
            hitpoints_tag = result.find('span', class_='stat-wrapper d-block mb-2')
            entry['hitpoints'] = int(hitpoints_tag.find('span', class_='stat-text').text.strip()) if hitpoints_tag else 0

            # Extract traits
            traits = result.find('div', class_='w-100 d-flex justify-content-center')
            entry['traits'] = ' '.join([trait.text.strip() for trait in traits.find_all('span')]) if traits else ''

            # Extract quantity
            detail_label = result.find_all('span', class_='detail-label')
            if detail_label and len(detail_label) >= 2 :
                quantity_text = detail_label[1].text.strip()
                quantities = quantity_text.strip('()').split('/')
                entry['quantity'] = int(quantities[0][1:])

            # Determine entry type
            if entry['attack'] != 0 or entry['defense'] != 0 or entry['hitpoints'] != 0:
                entry['type'] = 'Enemy'
            elif entry['threat'] != 0:
                entry['type'] = 'Location'
            elif entry['traits'].startswith("Item"):
                entry['type'] = 'Objective'
            else:
                entry['type'] = 'Treachery'

            # Extract effect
            effect_tag = result.find('p', class_='main-text')
            entry['text'] = effect_tag.text.strip() if effect_tag else ''

            # Extract shadow effect
            shadow_tag = result.find('p', class_='shadow-text')
            entry['shadow'] = shadow_tag.text.strip() if shadow_tag else ''

            entries.append(entry)

        # Save the parsed entries to a JSON file
        with open(f"assets/database/jsons/{set_name}.json", 'w', encoding='utf-8') as json_file:
            json.dump(entries, json_file, ensure_ascii=False, indent=4)

        return entries

def to_ascii(text: str):
    return unicodedata.normalize('NFD', text).encode('ascii', 'ignore').decode()
            
def download_image(card: dict):
    id = card['id']
    type = card['type']
    name = to_ascii(card['name'].replace(" ", "_").replace("'", "").replace("!", ""))
    type = card['type']

    suffix = ""
    if (type in ["Enemy", "Location", "Treachery"]):
        suffix = to_ascii(card['encounter_set'].replace(" Campaign", "").replace(" ", "_").replace("'", ""))
    else:
        suffix = card['sphere_name']

    # Example: "https://images.cardgame.tools/lotr/MEC01-74-front-Enemy-King_Spider-Spiders_of_Mirkwood.jpg"
    url = f"https://images.cardgame.tools/lotr/MEC01-{id}-front-{type}-{name}-{suffix}.jpg"

    local_file = local_image_file(id)
    # print(f"Downloading {code} to {local_file}")

    response = requests.get(url)
    if response.status_code == 200:
        img = Image.open(BytesIO(response.content))
        img.save(local_file, 'JPEG')
    else: 
        print(f"Failed to download {id}!")

def download_images(set_name: str):
    cards = json.load(open(set_json_file(set_name), "r", encoding="UTF-8"))
    print(len(cards))

    for card in cards[:80]:
        id = card['id']
        name = card['name']
        local_file = local_image_file(id)
        
        if not os.path.exists(local_file):
            print(f"Downloading {id} - {name}...")
            download_image(card)

def process_image(set_name: str, id: int):
    input_file = local_image_file(id)
    output_file = local_final_image_file(id)


set_name = "Revised Core Set"
# download_set_html(set_name)
# cards = parse_set_html(set_name)
# download_images(set_name)
