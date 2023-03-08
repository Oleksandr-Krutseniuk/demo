#!/bin/bash
echo Provide the jar name you\'d like to start
read jar extra_jar
jarfile=$(find ~ -iname $jar | head -n 1)

if [ ! -z "$extra_jar" ]; then # check if no more than 1 variable was passed
  printf "Please provide only 1 filename\n"

elif [ ! -z "$jarfile" ]; then # starts if the file has been found
  file $jarfile | grep JAR &> /dev/null
  jarcheck=$(echo $? | tee /dev/null)
: 'When "file" command is applied to a JAR-file it gives the output: <filename>: Java archive data (JAR). So, 
if i`d like to check whether a file I`m looking for has a JAR-format, I take the "file" command`s output and 
search for a word which is indispensable part of the output when a filetype defined as JAR. If you proceed 
to view my code further you will see why I needed to perform "file" command coupled with "grep". 
'
  if [ $jarcheck == 0 ]; then # check if the provided file has a JAR format
    sudo chmod u+x $jarfile
    address=$(curl ifconfig.me.)
    printf "You can reach your app at $address:8080\n"
    java -jar $jarfile # to start a file Java 17 is needed
  else 
    printf "Can\`t start your '$jar' file (it is not a JAR format)\n"
  fi
else 
  printf "Nothing has been found. Check if the filename is correct\n" # check whether the provided file is found

fi