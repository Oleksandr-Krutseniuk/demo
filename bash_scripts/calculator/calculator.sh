#!/bin/bash

read -e -p $'Enter the first value:\n' N1
  if [[ $N1 =~ [[:alpha:]] ]]; then
    printf "only numbers allowed\n"
    exit
  fi
read -e -p $'choose an operator (+,-,x,/)\n' operator
read -e -p $'enter 2nd value\n' N2
case $operator in
'+')
((Result=$N1+$N2)) ;;
'-')
((Result=$N1-$N2)) ;;
'x')
((Result=$N1*$N2)) ;;
'/')
((Result=$N1/$N2)) ;;
*)
echo "Wrong numbers of arguments"
exit 0 ;;
esac
echo "$N1 $operator $N2 = $Result"