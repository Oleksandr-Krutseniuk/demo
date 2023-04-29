#!/bin/bash

if [ ! -f employees.txt ]; then # check if employees list file exists
  touch employees.txt # create a file to store employees list if it doesn't exist
fi

# create array with data from existing employees list 
declare -A people # create assosiative array where index=employee name, value=profession
  while read -r column1 column2 column3; do #columns 1 and 2 stands for name+surname, 3 stands for profession
    name="${column1} ${column2}" #name and surname are combined in 1 var
    profession="${column3}"
    people["$name"]="$profession"
  done < <(tail -n +3 employees.txt)

while true; do
    
# ask user what he's about to do
  
  echo -e "\nSelect an option:\n"
  echo "1. Add a new employee"
  echo "2. Remove an employee"
  echo "3. Update employee's profession"
  echo -e "4. Quit\n"

  read -p $'Enter option number: \n' option

  
case $option in
  1) # block which adds new employees
  declare -A new_people # one more array where input data is stored.it's used to display a list of newly added employees
  while true; do
    read -p $'Enter employee\'s name and surname (or \'done\' to finish ): \n' first_name second_name
    
    if [ "$first_name" == "done" ]; then # cycle works until "done" is printed
      break
    fi

    name="${first_name} ${second_name}" # combine name+surname to 1 value (which will become an index name)
      
    # create a file containing the employees list if it doens't exist yet and add the headers 
    if ! head -n 1 employees.txt | grep -q -E "Profession|Employee" 2> /dev/null; then # add a header at the top of a file --------------->
      printf "%-20s %-22s\n" "Employee" $'Profession\n' > employees.txt                # ---> in case user uses script for the 1 time
    fi

    if [[ ! $name =~ ^[[:alpha:]]+[[:space:]][[:alpha:]]+$ ]]; then # check if the value contains letters only (name+surname separated by space)
      echo "Please enter actual employee's name and surname"  
      sleep 0.7
      continue # go back to the beginning of the loop if provided name is wrong
    fi

    if [[ ${people["$name"]} ]]; then # check if name already exists in the associative array "people"
      echo "The '$name' is already in the employees list. Please enter a different name."
      sleep 0.7
       
    else
      while true; do
        read -p $"Enter employee's profession: " profession
        if [[ -z "$profession" ]]; then # check whether a user entered a profession
          echo "Please enter a valid profession."
          sleep 0.7
          continue # go back to the beginning of the loop if profession is empty
        else
          break # exit the loop if profession is not empty
        fi
      done
      people["$name"]=$profession
      new_people["$name"]=$profession
      printf "%-21s" "$name" >> employees.txt && printf "%-20s\n" "${people[$name]}" >> employees.txt # add employees data to file
    fi
    
  done

  if [ ${#new_people[@]} -eq 0 ]; then # separate array where newly added employees are stored.if they're no added employees-array is empty
    sleep 0.7 && echo "No new employees added."
  else 
    printf "%-24s" $'\nPeople added:' && printf "%-21s\n" $'Profession\n'
    for name in "${!new_people[@]}"; do # when "!" is used the loop tries indexes instead of array's values
      sleep 0.7
      printf "%-23s" "$name" && printf "%-20s\n" "${new_people[$name]}"
    done
    unset new_people # массив выводит только введенных в этом цикле работников, поэтому его нужно очищать для нового ввода 
  fi 
    ;;
  
  2)
# employee deletion
  while true; do

  if [ ! -s employees.txt ]; then # check whether employees file isn't empty
    sleep 0.7
    echo -e "\nYour employees file is empty. Add some people to your team first"
    break

  elif [ ${#people[@]} -eq 0 ]; then  # used when user has no or deleted empoyees and tries to modify their profession
    sleep 0.7
    echo "Your employees list is empty. Time to hire new team!"
    break
  fi # this block needed for the cases such as if user starts block 1 in case condition and doesn't add any employees (+original emp_list
  # is empty). Then if user tries to delete someone he will get a message that emp_list is empty before he recieves a message
  # "Enter the name of the employee you want to remove"

  read -e -p $'Enter the name of the employee you want to remove or press \'exit\' to quit\n' name 
  
  if [ "$name" == "exit" ]; then # cycle works until "done" is printed
    break

  elif [[ -z "$name" ]]; then 
    echo "You didn't enter employee's name"
    continue
    sleep 0.7  
  fi
  
  if [[ ${people[$name]} ]]; then  
    unset "people[$name]"  
    # it's absolutely neccessary to use double quot marks.if you write command without "", it would be interpreted as "people[name]" instead of
    # "people[name+space+surname]" 
    sed -i "/^$name\s/ d" employees.txt && sleep 0.5 # search for a string starting with employee's name and remove it
    echo -e "The '$name' has been removed from the employee list\n"
        if [ ${#people[@]} -eq 0 ]; then # activated if user deleted all the empoyees
          echo "Your employees list is empty. Time to hire new team!"
          break
        fi
    
  else
    echo "The name '$name' does not exist in the employee list."
    sleep 0.7
  fi
   
done
  ;;

  3)
# profession update
  while true; do

    if [ ! -s employees.txt ]; then # check whether employees file isn't empty. used when file doesn't exist
      sleep 0.7
      echo -e "\nYour employees file is empty. Add some people to your team first"
      break

    elif [ ${#people[@]} -eq 0 ]; then #used when user deleted all empoyees and tries to modify their profession
      sleep 0.7
      echo "Your employees list is empty. Time to hire new team!"
      break
    fi  

  read -e -p $'Enter the name of the employee whose profession you want to update or press \'exit\' to quit\n' name
    if [ "$name" == "exit" ]; then # cycle works until "done" is printed
      break

    elif [[ -z "$name" ]]; then
      echo "You didn't enter employee's name"
      sleep 0.7
    elif [[ ! ${people[$name]} ]]; then # check whether an employee is in the list
      echo -e "The name '$name' does not exist in the employee list\n"
      sleep 0.7
    else 
      read -p "Enter new profession for $name employee"$'\n' new_profession  
      people["$name"]=$new_profession # change profession in the associative array
      sed -i "s/^$name\s.*/$name $(printf '%*s' $((19-${#name})) ) $new_profession/g" employees.txt
# this 'sed' takes a string starting with $name(employee's name+surname) and rewrites it to name+surname+spaces(20-name_surname length).
# that results in new $profession var printed from 21nd symbol in a string and puts it in the same position with the word "Profession"
# from the 1 string of a file,which makes a file comfortable to read.        
      sleep 0.7
      echo -e "The profession of '$name' has been changed to '$new_profession'\n"
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
 
