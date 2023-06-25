#!/bin/bash   
 
source /home/ubuntu/vars/.env # файл зі змінними, які імпортуються
# key= ключ для ssh-коннекту в файлі зі змінними var_file.txt
# port_number= номер порту ssh-коннекту в файлі зі змінними var_file.txt
# backup_host= адреса бекап хосту в файлі зі змінними var_file.txt 
# backup_user= remote -user в файлі зі змінними var_file.txt
# dbHost =                                     > в файлі зі змінними var_file.txt
# $dbUser =                                    > в файлі зі змінними var_file.txt
# $dbName =                                    > в файлі зі змінними var_file.txt
# $dbPassword =                                > в файлі зі змінними var_file.txt

 
current_date=$(date +"%Y-%m-%d-%H-%M-%S" ) # поточний час виконання скрипта
sqlname=$current_date
file_path="/home/ubuntu/dumps/$sqlname.sql" # файл для відправки

 
mysqldump -u testuser --password=password testdb > $file_path # а это - всю базу данных


log_file="/home/ubuntu/logfile.log" # файл з результатом перевірки розміру файлу (відправлений=отриманий)

attempts=0 # для повідомлення про невдалі перевірки хеш-сум
max_attempts=5 # для зупинки скрипта при невдалій перевірці хеш-сум 5 разів
 
# архівація файлу
archive_name="$(basename ${file_path}).tar.gz" # тут буде назва файлу для архівації + ".tar.gz"
   
tar -czf "$archive_name" -C "$(dirname ${file_path})" "$(basename ${file_path})" > /dev/null   
#       | назва архіву  | місце файлу для архівації  | назва файлу для архівації |
# команда має такий вигляд тому, що при використанні "-С" вказується директорія, в якій будуть розміщені файли для архівації, а сам
# файл можна вказувати з відносним шляхом (або просто назву).це призводить до того, що в архів буде поміщений тільки файл, а не
# дерево директорій "/home/user/file"
  if [ $? -ne 0 ]; then
    echo "$current_date Failed to create archive $(basename ${file_path}).tar.gz" >> $log_file
    rm -f "$file_path"
    exit 1
  fi 
hashsum=$(sha256sum "$archive_name" | cut -d' ' -f1) # отримання хеш-суми архіву."cut" залишає тільки контрольну суму
# віправка файлу на сервер-отримувач

# безкінечний цикл для повторення віправки архіву на випадок, якщо хеш-суми не співпадуть.
# цикл буде зупинений після 5 невдалої перевірки хеш-сум
while true; do   

  scp -i "$key" -P "$port_number" "$archive_name" "$backup_user@$backup_host:/home/ubuntu/received_dumps/$archive_name" > /dev/null # якщо потрібно - 
# можна створити змінну для місця зберігання. після scp у терміналі з'являється назва переданого файлу, що не потрібно для крон-джоби - 
# тому вивід іде в /dev/null 
    if [ $? -ne 0 ]; then # перевірка провалу відправки файлу на бекап-сервер
      echo "$current_date Failed to send $archive_name to backup-server" >> $log_file
      rm -f "$file_path" "$archive_name"
      exit 1
    fi  
# перевірка хеш-сум на ремоут-хості та виведення результату в лог-файл на хості-відправнику
 
  received_hashsum=$(ssh -i "$key" -p "$port_number" $backup_user@$backup_host "sha256sum /home/ubuntu/received_dumps/$archive_name" | awk '{print $1}')
    if [ "$hashsum" = "$received_hashsum" ]; then # якщо хеш-суми однакові
      echo "$current_date File received successfully. Hashsum match." >> $log_file
      rm -f "$file_path" "$archive_name" # видаляє оригінальний файл та архів, якщо хеш-суми співпали
      break # завершує цикл якщо хеш-суми співпали
    else # хеш-сумми не співпали
      attempts=$((attempts+1)) # лічильник невдалих перевірок хеш-сум

        if [ "$attempts" -eq 1 ]; then # якщо перевірка хеш-сум провалена перший раз
          echo "$current_date Hashsum doesn't match. Something went wrong with $archive_name file." >> $log_file
        fi 

        if [ "$attempts" -eq "$max_attempts" ]; then # если 5 проверок хеш-сумм провалены
          echo "$current_date ATTENTION! Hashsums didn't match for $archive_name file after $attempts attempts" >> $log_file
          rm -f "$file_path" "$archive_name"
          ssh -i "$key" -p "$port_number" "$backup_user@$backup_host" "rm /home/ubuntu/$archive_name"
          exit 1 # вихід зі скрипту якщо перевірка чек-сум провалилася 5 разів 
        fi

        if [ "$attempts" -ge 2 ]; then # 2 або більше невдалих перевірок хеш-сум
          echo "$current_date Hashsums didn't match for $archive_name file after $attempts attempts" >> $log_file
        fi

    fi

done
