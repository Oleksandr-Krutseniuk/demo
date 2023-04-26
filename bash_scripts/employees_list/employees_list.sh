#!/bin/bash
declare -A people # declare assosiative array where index=employee name, value=profession

if [ ! -f employees.txt ]; then # check if employees list file exists
  touch employees.txt # create a file to store employees list if it doesn't exist
fi

while true; do 
    read -p "Enter employee's name (or 'done' to finish): " name
    if [ "$name" == "done" ]; then # cycle works until "done" is printed
        break
    fi
      
      if ! head -n 1 employees.txt | grep -q -E "Profession|Employee" 2> /dev/null; then # add a header at the top of a file 
      echo -e "Employee \t\tProfession\n" > employees.txt
      fi

      if [[ ! $name =~ ^[[:alpha:]]+$ ]]; then # check whether the value contains letters only
        echo "Name can't contain numbers or symbols (if you're not Musk's XÆA-Ⅻ  )"
        sleep 0.7
        continue # go back to the beginning of the loop if provided name is wrong
      fi

      if [[ ${people[$name]} ]]; then # check if name already exists in the associative array
        echo "The name '$name' already exists in the employee list. Please enter a different name."
        sleep 0.7
        continue # go back to the beginning of the loop if name already exists
      fi

    read -p "Enter employee's profession: " profession
    people["$name"]=$profession
    printf "%-16s" "$name" >> employees.txt && printf "%-15s\n" "${people[$name]}" >> employees.txt # add employees data to file
done

echo -e "\nPeople added:\nName\t\tProfession\n" # print newly added employees
for name in "${!people[@]}"; do
  printf "%-16s" "$name" && printf "%-15s\n" "${people[$name]}"
done

 