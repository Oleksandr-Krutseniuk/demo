#!/bin/bash

  
if [ ! -f employees.txt ]; then # check if employees list file exists
  touch employees.txt # create a file to store employees list if it doesn't exist
fi

while true; do

declare -A people # create assosiative array where index=employee name, value=profession
    while read -r column1 column2 column3; do #columns 1 and 2 stands for name+surname, 3 stands for profession
    name="${column1} ${column2}" #name and surname are combined in 1 var
    profession="${column3}"
    people["$name"]="$profession"
    #printf "%-21s%-20s\n" "$name" "${people[$name]}"
   done < <(tail -n +3 employees.txt)

    
# ask user what he's about to do
  
  echo -e "\nSelect an option:\n"
  echo "1. Add a new employee"
  echo "2. Remove an employee"
  echo "3. Update employee's profession"
  echo -e "4. Quit\n"

  read -p $'Enter option number: \n' option

  
case $option in
  1)
  declare -A new_people # one more array where input data is stored 
  while true; do
    read -p $'Enter employee\'s name and surname (or \'done\' to finish ): \n' first_name second_name
    
    if [ "$first_name" == "done" ]; then # cycle works until "done" is printed
      break
    fi

    name="${first_name} ${second_name}"
      

    if ! head -n 1 employees.txt | grep -q -E "Profession|Employee" 2> /dev/null; then # add a header at the top of a file 
      printf "%-20s %-22s\n" "Employee" $'Profession\n' > employees.txt
    fi

    if [[ ! $name =~ ^[[:alpha:]]+[[:space:]][[:alpha:]]+$ ]]; then # check whether the value contains letters only
      echo "Please enter employee's name and surname" # to remake !!!
      sleep 0.7
      continue # go back to the beginning of the loop if provided name is wrong
    fi

    if [[ ${people["$name"]} ]]; then # check if name already exists in the associative array
      echo "The name '$name' already exists in the employee list. Please enter a different name."
      sleep 0.7
      continue # go back to the beginning of the loop if name already exists
    else
      read -p "Enter employee's profession: " profession # добавить переход строки
      people["$name"]=$profession
      new_people["$name"]=$profession
      printf "%-21s" "$name" >> employees.txt && printf "%-20s\n" "${people[$name]}" >> employees.txt # add employees data to file
    fi
    
  done
  sleep 0.7

  if [ ${#new_people[@]} -eq 0 ]; then
    sleep 0.7 && echo "No new employees added."
  else 
    printf "%-24s" $'\nPeople added:' && printf "%-21s\n" $'Profession\n'
    for name in "${!new_people[@]}"; do # "!" в цикле позволяет пройтись по ключам вместо значений
      sleep 0.7
      printf "%-23s" "$name" && printf "%-20s\n" "${new_people[$name]}"
    done
    unset new_people # массив выводит только введенных в этом цикле работников, поэтому его нужно очищать для нового ввода 
  fi 
    ;;
  
  2)
# employee deletion
  while true; do
  read -e -p $'Enter the name of the employee you want to remove or press \'exit\' to quit\n' name 

    if [ "$name" == "exit" ]; then # cycle works until "done" is printed
      break
      
    elif [[ ! ${people[$name]} ]]; then
      echo "The name '$name' does not exist in the employee list."
      sleep 0.7
      continue

    else
      unset people[$name] # remove employee from associative array
      # remove employee's data from file
      sed -i "/^$name\s/ d" employees.txt && sleep 0.5
      echo -e "The '$name' has been removed from the employee list\n"
      continue
    fi
  done
  ;;
  3)
# profession update
  while true; do
  read -e -p $'Enter the name of the employee whose profession you want to update or press \'exit\' to quit\n' name
    if [ "$name" == "exit" ]; then # cycle works until "done" is printed
      break

    elif [[ ! ${people[$name]} ]]; then # check whether an employee is in the list
      echo "The name '$name' does not exist in the employee list."
      sleep 0.7
      continue # go back to the beginning of the loop if name does not exist
    else 
      read -p "Enter new profession for $name employee"$'\n' new_profession  
      people["$name"]=$new_profession # change profession in the associative array
      sed -i "s/^$name\s.*/$name $(printf '%*s' $((19-${#name})) '' ) $new_profession/g" employees.txt
      sleep 0.7
      echo -e "The profession of '$name' has been changed to '$new_profession'\n"
      continue
    fi
  done
    ;;           

  4)
    sleep 0.5
    echo "Bye"
    exit 0
    ;;

  *)
    echo "Invalid option. Please select option 1, 2, 3, or 4."
    sleep 0.7
    continue
    ;;
esac
done
 
