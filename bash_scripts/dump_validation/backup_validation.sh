#!/bin/bash

# функція для повідомлень в телеграм та записів в локальний лог
send_telegram_message() {
    message="$*"
    curl -s -X POST https://api.telegram.org/bot$tg_token/sendMessage -d chat_id=$chat_id -d text="$message"\
     > /dev/null
    echo "$message" >> "$log_file"
}

source  /home/sashaa/.env # імпорт змінних з файлу
#           |      | <---- вказати актуальне ім'я користувача.і директорію також

# перелік змінних, які вимагає скрипт та які імпортуються командою source із ".env" 
  # backup_dir= місце, куди приходять архіви дампів
  # log_file= локальний журнал скрипта.можна просто вказати шлях, створення автоматичне
  # dbUser= користувач БД
  # dbPassword= пароль до БД
  # dbName= ім'я БД
  # dbPort= порт БД
  # tg_token= токен для телеграм
  # chat_id= айді чату в телеграм
  # error_dir= директорія для зберігання невалідних архівів та дампів.її не потрібно створювати-просто вказати шлях
  
archive_list=$(ls -t "$backup_dir") # сортує архіви з бекапом. 
last_archive=$(echo "$archive_list" | head -n 1) # отримую останній переданий архів дампа
dump_file=$(basename "${last_archive}" .tar.gz) # трансформує ім'я архіву в ім'я дампу, виключаючи з назви ".tar.gz"

# створення лог-файлу, якщо його ще немає
if [[ ! -f "$log_file" ]]; then
    touch "$log_file"
fi
 
# перевірка того, чи не пуста директорія з дампами.Прапорець "-А" відображає вміст (в т.ч. приховані файли та папки)
# окрім "." та ".."
if [ -z "$(ls -A "$backup_dir")" ]; then
  send_telegram_message "$(date '+%Y-%m-%d %H:%M:%S'): Директорія з дампами пуста. Відсутні дампи для валідації"
  exit 1
fi

# перевірка, що в директорії з дампами тільки архіви.якщо в директорії не тільки архіви-то це значить,що доставка дампів зломалася.
incorrect_files=($(find "$backup_dir" -maxdepth 1 -type f ! -name "*.tar.gz")) # записує файли,які не містять "*.tar.gz" в массив
if [ ${#incorrect_files[@]} -gt 0 ]; then # запускається, якщо знайдений 1 або більше файл без "*.tar.gz"
incorrect_files_names=() # в incorrect_files файли вказані з повними шляхами, потрібно вивести тільки ім'я файлу 
  for file in "${incorrect_files[@]}"; do
    incorrect_files_names+=("$(basename "$file")") # наповнюю новий масив іменами файлів без шляху
    mv "$file" "${error_dir}/$(basename "$file")" # переміщення не "*.tar.gz"-файлів в директорію проблемними дампами
  done
      
incorrect_files_formatted=$(printf "\\n%s" "${incorrect_files_names[@]}") 
# printf бере по 1 значенню з масиву "incorrect_files_names" та ставить перед значенням спец-символ "\n".В результаті формується
# вертикальний стовпчик, який потім іде в локальний лог та телеграм
  send_telegram_message "$(date '+%Y-%m-%d %H:%M:%S'): В директорії з дампами є файли з недопустимим форматом. Валідація припинена.\
  Список файлів:${incorrect_files_formatted}"
exit 1
fi

# Розпаковка останнього архіву з дампом

tar_err_msg=$(tar -xzf "${backup_dir}${last_archive}" -C "$backup_dir" 2>&1 )
  
# обробка крашу розпаковки дампу
if [ $? -ne 0 ]; then
  send_telegram_message "$(date '+%Y-%m-%d %H:%M:%S'): Помилка розпакування архіву дампу ${last_archive}.\
  Валідація перервана. Помилка: "$'\n'"$tar_err_msg"
  # переміщення архіву до директорії невалідних дампів
  mv "${backup_dir}${last_archive}" "${error_dir}/${last_archive}" 
  exit 1
fi

# відновлення бази даних з дампу.якщо команда відпрацює без помилок-то змінна "backup_restoration_fail" просто не буде використана.
# якщо в команді будуть помилки,stderr перенаправиться в stdout та запишеться в змінну, яка потім буде виводити текст помилки до 
# функції send_telegram_message.
backup_restoration_fail=$(mysql --protocol=TCP -u $dbUser --password=$dbPassword\
 --port=$dbPort $dbName < "${backup_dir}${dump_file}" 2>&1)

# обробка помилки при завантаженні дампа для валідації.якщо команда поверне не "0",помилка запишеться в змінну 
if [ $? -ne 0 ]; then
  safe_output=$(echo "$backup_restoration_fail" | sed -e "s/$dbPort/db_port/g" -e "s/$dbUser/db_User/g" -e "s/$dbPassword/db_Password/g" -e\
   "s/$dbName/db_Name/g" | sed -r 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ip_adress/g')
# "safe_output" потрібна щоб приховати чутливі дані.В помилці,яка буде відправлена в функцію,фактичні значення змінних dbPort,db_User та
# dbPassword змінюються на назву змінної (якщо $dbPassword=123456, то в виводі значення буде замінено на $dbPassword=dbPassword).Останній
# блок пайплайну замінює знайдені айпі адреси на текст "ip_adress"
  send_telegram_message "$(date '+%Y-%m-%d %H:%M:%S'): Помилка відновлення БД з файлу бекапу $dump_file.\
  Валідація перервана. Помилка: "$'\n'"$safe_output"
  # якщо дамп не завантажився-то скидую його та його архів в error_dir
  mv "${backup_dir}${dump_file}" "${error_dir}/${dump_file}"
  mv "${backup_dir}${last_archive}" "${error_dir}/${last_archive}"
  exit 1
fi
 
# Підключення до бази даних та виконання запиту на отримання кількості таблиць
count=$(mysql --protocol=TCP -u $dbUser --password=$dbPassword --port=$dbPort -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${dbName}';")

# перевірка валідності бекапу

if [[ "$count" -ge 70 && "$count" -le 100 ]]; then
    # надсилаю повідомлення в телеграм та локальний лог
    send_telegram_message "$(date '+%Y-%m-%d %H:%M:%S'): Бекап $dump_file - валідний. Кількість таблиць БД: $count"
    
    # якщо бекап валідний - видаляю розпакований файл дампу (архів залишиться)
    if [[ -f "${backup_dir}${dump_file}" ]]; then
        rm "${backup_dir}${dump_file}"
    fi
         
# при успішній валідації дампу-видалається його файл.також перестає бути потрібним і старий(попередній)архів дампу-його
# також видаляю.я міг-би пропустити перевірку к-ті архівів і залишити просто видалення 2гого архіву-але так скрипт  дає
# зрозуміти,що якщо вже виконується ця перевірка-значить архів валідний і видаляється попередній архів дампу.крім того, 
# якщо виконувати видалення без перевірки к-ті архівів,а на час перевірки архів буде всього 1 - скрипт буде виводити в
# консоль "rm: cannot remove '****': No such file or directory"
    num_archives=$(ls -t "${backup_dir}" | wc -l) # розпакований дамп вже видалений-рахуватимуться тільки архіви
    if [[ "$num_archives" -gt 1 ]]; then
        # отримую ім'я другого архіву дампу
        second_archive=$(echo "$archive_list" | sed -n 2p) 
        rm "${backup_dir}${second_archive}" # знищую його
    fi

else 
    # повідомлення в телеграм і локальний лог
  send_telegram_message "$(date '+%Y-%m-%d %H:%M:%S'): Бекап $dump_file невалідний. Кількість таблиць БД: $count"

    # створення директорії для невалідних архівів/файлів з бекапом, якщо вона ще не існує
  if [[ ! -d "$error_dir" ]]; then 
    mkdir -p "$error_dir"
  fi
  # переміщення невалідних дампу та архіву до іншої директорії 
  mv "${backup_dir}${dump_file}" "${error_dir}/${dump_file}"
  mv "${backup_dir}${last_archive}" "${error_dir}/${last_archive}"
 
fi

