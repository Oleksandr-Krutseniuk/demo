#!/bin/bash

while true; do
if [ ! -f employees.txt ]; then # check if employees list file exists
  touch employees.txt # create a file to store employees list if it doesn't exist
fi

# ask user what he's about to do
 
  echo -e "\nSelect an option:"
  echo "1. Add a new employee"
  echo "2. Remove an employee"
  echo "3. Update employee's profession"
  echo "4. Quit"

  read -p "Enter option number: " option
#done
case $option in
  1)
    declare -A people # create assosiative array where index=employee name, value=profession
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
    ;;
  

  2)
    declare -A people # create array from existing employees list
    if [ -f employees.txt ]; then # fill up the array with employees data
      while read line; do
      name=$(echo $line | cut -f1 -d $' ') # extract name as index
      profession=$(echo $line | cut -f2 -d $' ') # extract proffesion as index's value
      people[$name]=$profession # put the index and value into the array
      done < <(tail -n +3 employees.txt) # raws with employees start from 3rd string
    else
      printf "Employees list file is not found" 
    fi
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
        echo -e "The employee '$name' has been removed from the employee list\n"
        continue
      fi
    done
    ;;
  3)
    declare -A people # create array from existing employees list
    if [ -f employees.txt ]; then # fill up the array with employees data
      while read line; do
      name=$(echo $line | cut -f1 -d $' ') # extract name as index
      profession=$(echo $line | cut -f2 -d $' ') # extract proffesion as index's value
      people[$name]=$profession # put the index and value into the array
      done < <(tail -n +3 employees.txt) # raws with employees start from 3rd string
    else
      printf "Employees list file is not found" 
    fi  
      

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
        read -p "Enter new profession for $name employee " new_profession # добавить новую строку
        people["$name"]=$new_profession # change profession in the associative array
        #sed -i "s/^$name\s.*/$name\t$new_profession/g" employees.txt # change profession in the file
        sed -i "s/^$name\s.*/$name\t\t\t$new_profession/g" employees.txt # change profession in the file
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
 
