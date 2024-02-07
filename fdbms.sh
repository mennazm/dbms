#!/bin/bash
shopt -s extglob
export LC_COLLATE=C

DBMS_PATH="./DBMS"
ERROR_LOG="./.error.log"

mkdir "$DBMS_PATH" 2>> "$ERROR_LOG"

function mainMenu {
  echo -e "\n+---------Main Menu-------------+"
  echo "| 1. Use DB                     |"
  echo "| 2. Create DB                  |"
  echo "| 3. Drop DB                    |"
  echo "| 4. Show DBs                   |"
  echo "| 5. Exit                       |"
  echo "+-------------------------------+"
  echo -e "Enter Choice: \c"
  read -r ch
  case $ch in
    1) useDB ;;
    2) createDB ;;
    3) dropDB ;;
    4) showDBs ;;
    5) exit ;;
    *) echo "Not Valid" ; mainMenu ;;
  esac
}

function useDB {
  echo -e "Enter Database Name: "
  read -r dbName

  # Convert to lowercase
  dbName=$(echo "$dbName" | tr '[:upper:]' '[:lower:]')

  if [ -d "$DBMS_PATH/$dbName" ]; then
    cd "$DBMS_PATH/$dbName" 2>> "$ERROR_LOG"
    echo "You are using Database $dbName"
    tablesMenu
  else
    echo "Database $dbName wasn't found"
    mainMenu
  fi
}

function createDB {
  echo -e "Enter Database Name:"
  read -r dbName

  # Validate database name
if [[ ! "$dbName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ || "$dbName" =~ ^[0-9] ]]; then
  echo "Invalid Database Name. Use only alphanumeric characters and underscores. It should not start with a number."
  mainMenu
  return
fi

  dbPath="$DBMS_PATH/$dbName"

  # Check if the database already exists
  if [ -d "$dbPath" ]; then
    echo "Database $dbName already exists."
    mainMenu
    return
  fi

  mkdir "$dbPath"
  if [ $? -eq 0 ]; then
    echo "Database Created Successfully"
  else
    echo "Error Creating Database $dbName"
  fi
  mainMenu
}

function dropDB {
  echo -e "Enter Database Name:"
  read -r dbName

  # Convert to lowercase
  dbName=$(echo "$dbName" | tr '[:upper:]' '[:lower:]')

  rm -r "$DBMS_PATH/$dbName"
  if [ $? -eq 0 ]; then
    echo "Database Dropped Successfully"
  else
    echo "Error Dropping Database $dbName"
  fi
  mainMenu
}

function showDBs {
  ls "$DBMS_PATH"
  mainMenu
}

function tablesMenu {
  echo -e "\n+--------Tables Menu------------+"
  echo "| 1. Show Existing Tables       |"
  echo "| 2. Create New Table           |"
  echo "| 3. Insert Into Table           |"
  echo "| 4. deleteFromTable            |"              
  echo "| 7. Drop Table                 |"   
  echo "| 8. Back To Main Menu          |"
  echo "| 9. Exit                       |"
  echo "+-------------------------------+"
  echo -e "Enter Choice: \c"
  read -r choice

  case $choice in
    1) ls .; tablesMenu ;;
    2) createTable ;;
    3) insert ;;
    4) deleteFromTable;;
    7)  dropTable;;
    8) clear; cd ../.. 2>> "$ERROR_LOG"; mainMenu ;;
    9) exit ;;
    *) echo "Invalid Choice"; tablesMenu ;;
  esac
}

function deleteFromTable {
  echo -e "Enter Table Name: \c"
  read tName

  # Check if the table file exists
  if [ ! -f "$tName" ]; then
    echo "Table does not exist."
    tablesMenu
    return
  fi

  # Assuming primary key is 'id'
  primaryKey="id"

  echo -e "Enter Condition Value for $primaryKey: \c"
  read val

  # Check if the condition value is empty
  if [ -z "$val" ]; then
    echo "Condition value cannot be empty."
    tablesMenu
    return
  fi

  # Debugging: Print table contents before deletion
  echo "Table Contents before deletion:"
  cat "$tName"

  # Debugging: Print primary key value being searched for
  echo "Searching for $primaryKey=$val"

  # Search for the row with the primary key value
  row=$(awk -v pKey="$primaryKey" -v value="$val" -F "|" '$1 == value {print}' "$tName")

  # Debugging: Print row content found
  echo "Row Found: $row"

  # If row not found
  if [ -z "$row" ]; then
    echo "Row with $primaryKey=$val not found."
    tablesMenu
    return
  fi

# Delete the row with the primary key value
awk -v pKey="$primaryKey" -v value="$val" -F "|" '$1 != value' "$tName" > "$tName.tmp" && mv "$tName.tmp" "$tName"

# Debugging: Print contents of the updated table file after deletion
echo "Table Contents after deletion:"
cat "$tName"


  echo "Row Deleted Successfully"
  tablesMenu
}


function createTable {
  echo -e "Table Name: "
  read -r tableName

  # Validate table name
 if [[ ! "$tableName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ || "$tableName" =~ ^[[:space:]] ]]; then
    echo "Invalid Table Name. Use only alphanumeric characters and underscores. It should not start with a number."
    tablesMenu
    return
  
  fi

  # Convert to lowercase
  tableName=$(echo "$tableName" | tr '[:upper:]' '[:lower:]')

  if [ -f "$tableName" ]; then
    echo "Table already exists. Choose another name."
    tablesMenu
    return
  fi

  echo -e "Number of Columns:"
  read -r colsNum

  sep="|"
  rSep="\n"
  metaData="Field$sepType$sepKey"
  temp=""

  for ((counter = 1; counter <= colsNum; counter++)); do
    echo -e "Name of Column No.$counter: \c"
    read -r colName

    echo -e "Type of Column $colName: "
    select var in "int" "str"; do
      case $var in
        int ) colType="int"; break ;;
        str ) colType="str"; break ;;
        * ) echo "Invalid option" ;;
      esac
    done

    if [ -z "$pKey" ]; then
      echo -e "Make PrimaryKey ? "
      select var in "yes" "no"; do
        case $var in
          yes ) pKey="PK"
                metaData+="$rSep$colName$sep$colType$sep$pKey"
                break ;;
          no )  metaData+="$rSep$colName$sep$colType$sep"
                break ;;
          * )   echo "not valid option" ;;
        esac
      done
    else
      metaData+="$rSep$colName$sep$colType$sep"
    fi

    if [ $counter -eq $colsNum ]; then
      temp+="$colName"
    else
      temp+="$colName$sep"
    fi
  done

  touch ".$tableName"  # Create metadata file
  echo -e "$metaData" >> ".$tableName"

  touch "$tableName"  # Create data file
  echo -e "$temp" >> "$tableName"

  if [ $? -eq 0 ]; then
    echo "Table Created Successfully"
  else
    echo "Error Creating Table $tableName"
  fi

  tablesMenu
}

function insert {
  echo -e "Table Name: \c"
  read tableName
  if ! [[ -f $tableName ]]; then
    echo "Table $tableName isn't existed ,choose another Table"
    tablesMenu
  fi
  colsNum=`awk 'END{print NR}' .$tableName`
  sep="|"
  rSep="\n"
  for (( i = 2; i <= $colsNum; i++ )); do
    colName=$(awk 'BEGIN{FS="|"}{ if(NR=='$i') print $1}' .$tableName)
    colType=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $2}' .$tableName)
    colKey=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $3}' .$tableName)
    echo -e "$colName ($colType) = \c"
    read data

    # Validate Input
    if [[ $colType == "int" ]]; then
      while ! [[ $data =~ ^[0-9]*$ ]]; do
        echo -e "invalid DataType !!"
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi

    if [[ $colKey == "PK" ]]; then
      while [[ true ]]; do
        if [[ $data =~ ^[`awk 'BEGIN{FS="|" ; ORS=" "}{if(NR != 1)print $(('$i'-1))}' $tableName`]$ ]]; then
          echo -e "primary key must be unique !"
        else
          break;
        fi
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi

    #Set row
    if [[ $i == $colsNum ]]; then
      row=$row$data$rSep
    else
      row=$row$data$sep
    fi
  done
  echo -e $row"\c" >> $tableName
  if [[ $? == 0 ]]
  then
    echo "Data Inserted Successfully"
  else
    echo "Error Inserting Data into Table $tableName"
  fi
  row=""
  tablesMenu
}

function dropTable {
  echo -e "Enter Table Name: \c"
  read tName
  rm $tName .$tName 2>>./.error.log
  if [[ $? == 0 ]]
  then
    echo "Table Dropped Successfully"
  else
    echo  "Error Dropping Table $tName"
  fi
  tablesMenu
}








# Start the script
mainMenu

