
declare -A prices
prices["apples"]=5
prices["banana"]=8
prices["tea"]=2
prices["orange"]=11
prices["potato"]=1

echo Current prices:
for product in ${!prices[*]}
do
printf "%s  %s\n" $product ${prices[$product]}
done


echo Planned prices increase:
for price in ${!prices[*]}

 
do
  if [ ${prices[$price]} -lt 5 ]
  then ((new_price=prices[$price]+1))
  printf "%s %s \n" $price $new_price 
  else 
  printf "%s %s \n" $price ${prices[$price]}
   
  fi
 
  
done
