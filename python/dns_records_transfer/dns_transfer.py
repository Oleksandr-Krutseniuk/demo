import sys # повинен бути імпортований щоб зупинити скрипт при обробці перевірки наявності модулів
modules = [
    "json", # для роботи з json-файлами 
    "requests", # для запитів в API Cloudflare
    "oauth2client", # для підключення до API для таблиць
    "gspread" # для роботи з таблицями
]

for module_name in modules:
  try:
    __import__(module_name)
# тут "try" імпортує модуль якщо він встановлений. однак "__import__" не дозволяє  використовувати 
# модуль по імені в коді (наприклад, так: config = json.load(config_file)).тому після перевірки наявності всіх
# модулів вони імпортуються окремо через команду "import"   
  except ImportError:
    print(f"Module \'{module_name}\' isn\'t installed though could be intalled with:\n\
sudo pip install {module_name}")
    sys.exit()


import json
import requests
from oauth2client.service_account import ServiceAccountCredentials
import gspread  

# функція для отримання DNS-записів з Cloudflare
def get_dns_records_from_cloudflare(): 
    vars_file_path = '/home/*****/*****/vars.json'# адреса файлу зі змінними

    with open(vars_file_path) as config_file:  # відкриває файл зі змінними
      config = json.load(config_file) # запис змінних в словник
    CLOUDFLARE_TOKEN = config['CLOUDFLARE_TOKEN'] # 
    ZONE_ID = config['ZONE_ID']

    headers = {
        'Authorization': f'Bearer {CLOUDFLARE_TOKEN}',
        'Content-Type': 'application/json'
    }
# запит DNS-записів та їх запис в змінну.в результаті буде отримано список словників,в якому 1 запис=1 словник. для перегляду
# вмісту словника можна розкоментувати строки 83-85 та подивитися вміст "dns_records.json" в директорії, з якої запущено скрипт
    response = requests.get(f'https://api.cloudflare.com/client/v4/zones/{ZONE_ID}/dns_records', headers=headers)

    return response.json()['result'] # з всієї відповіді потрібен тільки вміст ключа 'result'

# функція для запису в лист в таблиці. Назва листа буде відповідати назві зони DNS
def write_records_to_sheet(dns_records):
    vars_file_path = '/home/sashaa/python/vars.json' # адреса файлу зі змінними

    with open(vars_file_path) as config_file: # відкриває файл зі змінними
        config = json.load(config_file)
    google_keyfile = config['google_keyfile'] # шлях до файлу з ключем від сервісного акаунту
    sheet_name = config['sheet_name'] # ім'я гугл-таблиці
    # scope визначає АРІ,до яких отримають доступ запити скрипта.тут це Google Sheets та Google Drive 
    scope = ['https://spreadsheets.google.com/feeds', 'https://www.googleapis.com/auth/drive']
    credentials = ServiceAccountCredentials.from_json_keyfile_name(google_keyfile, scope)
    gc = gspread.authorize(credentials) # підключення до АРІ та передача облікових даних ключа та доступних АРІ 

    try: # перевірка існування таблиці
      spreadsheet = gc.open(sheet_name)
    except gspread.exceptions.SpreadsheetNotFound:
      print(f'Table "{sheet_name}" doesn\'t exist or access for service account hasn\'t been granted by spreadsheet owner!')
      sys.exit() # якщо скрипт не знаходить таблицю - вона або не існує, або до неї не надано доступ сервісному акаунту

     
    domain = dns_records[0]['zone_name'] # змінна для присвоєння назви листку в таблиці
    try: # <-перевірка існування листа таблиці
        worksheet = spreadsheet.worksheet(domain)# скрипт намагається отримати доступ до листа в таблиці.
    except gspread.WorksheetNotFound:# <-якщо лист не існує - створюю,а цифри в параметрах є розміром полей таблиці
        worksheet = spreadsheet.add_worksheet(title=domain, rows="100", cols="5")

    worksheet.clear() # очистка листа таблиці перед записом даних. функція "get_dns_records_from_cloudflare"
    # отримує живі дані від Cloudflare API - тому контент листа видаляється та заповнюється 
    # актуальними записами

# вивід з ДНС-записами складається з списку, а кожен елемент списку-це словник.тому кожний елемент списку буде давати 
# значення ключів ['name'], ['type'],['content'],['ttl'] і 'comment' та поміщати його в змінну,яка буде дописана в таблицю
    for record in dns_records:
        row = [record['name'], record['type'], record['content'], record['ttl'], record.get('comment', '')]
        worksheet.append_row(row)
# отримання значення ключа "comment" має форму, яка дозволяє повернути визначений аргумент (тут це '') як значення ключа,
# якщо спражнє значення ключа пусте. якщо значення ключа "comment" - пусте і відсутній дефолтне значення для повернення - 
# станеться помилка.

def main():
    dns_records = get_dns_records_from_cloudflare()

# це частина для тих, хто хоче подивитися вміст відповіді з DNS-записами від Cloudflare
#    with open('dns_records.json', 'w') as file:
#        json.dump(dns_records, file, indent=4)

    write_records_to_sheet(dns_records)

if __name__ == "__main__": # запускає функцію main, якщо скрипт запущений напряму (python3 dns_transfer.py)
    main()