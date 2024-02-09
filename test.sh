#!/bin/bash

shopt -s extglob
export LC_COLLATE=C

DBMS_PATH="./DBMS"
ERROR_LOG="./.error.log"

mkdir "$DBMS_PATH" 2>> "$ERROR_LOG"

function mainMenu {
  dialog --backtitle "Main Menu" \
         --menu "Choose an option:" 15 50 5 \
         1 "Use DB" \
         2 "Create DB" \
         3 "Drop DB" \
         4 "Show DBs" \
         5 "Exit" 2>"$INPUT"
  menu_choice=$(<"$INPUT")

  case $menu_choice in
    1) useDB ;;
    2) createDB ;;
    3) dropDB ;;
    4) showDBs ;;
    5) exit ;;
    *) echo "Not Valid" ; mainMenu ;;
  esac
}

function useDB {
  dialog --backtitle "Use DB" \
         --inputbox "Enter Database Name:" 8 40 2>"$INPUT"
  dbName=$(<"$INPUT")
  dbName=$(echo "$dbName" | tr '[:upper:]' '[:lower:]')

  if [ -d "$DBMS_PATH/$dbName" ]; then
    cd "$DBMS_PATH/$dbName" 2>> "$ERROR_LOG"
    dialog --backtitle "Success" \
           --msgbox "You are using Database $dbName" 8 40
    tablesMenu
  else
    dialog --backtitle "Error" \
           --msgbox "Database $dbName wasn't found" 8 40
    mainMenu
  fi
}

function createDB {
  dialog --backtitle "Create DB" \
         --inputbox "Enter Database Name:" 8 40 2>"$INPUT"
  dbName=$(<"$INPUT")

  # Validate database name
  if [[ ! "$dbName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ || "$dbName" =~ ^[0-9] ]]; then
    dialog --backtitle "Error" \
           --msgbox "Invalid Database Name. Use only alphanumeric characters and underscores. It should not start with a number." 8 60
    mainMenu
    return
  fi

  dbPath="$DBMS_PATH/$dbName"

  # Check if the database already exists
  if [ -d "$dbPath" ]; then
    dialog --backtitle "Error" \
           --msgbox "Database $dbName already exists." 8 40
    mainMenu
    return
  fi

  mkdir "$dbPath"
  if [ $? -eq 0 ]; then
    dialog --backtitle "Success" \
           --msgbox "Database Created Successfully" 8 40
  else
    dialog --backtitle "Error" \
           --msgbox "Error Creating Database $dbName" 8 40
  fi
  mainMenu
}

function dropDB {
  dialog --backtitle "Drop DB" \
         --inputbox "Enter Database Name:" 8 40 2>"$INPUT"
  dbName=$(<"$INPUT")
  dbName=$(echo "$dbName" | tr '[:upper:]' '[:lower:]')

  rm -r "$DBMS_PATH/$dbName"
  if [ $? -eq 0 ]; then
    dialog --backtitle "Success" \
           --msgbox "Database Dropped Successfully" 8 40
  else
    dialog --backtitle "Error" \
           --msgbox "Error Dropping Database $dbName" 8 40
  fi
  mainMenu
}

function showDBs {
  dialog --backtitle "Show DBs" \
         --msgbox "$(ls "$DBMS_PATH")" 20 40
  mainMenu
}

function tablesMenu {
  dialog --backtitle "Tables Menu" \
         --menu "Choose an option:" 20 50 10 \
         1 "Show Existing Tables" \
         2 "Create New Table" \
         3 "Insert Into Table" \
         4 "Delete From Table" \
         5 "Select All From Table" \
         6 "Select Data From Table" \
         7 "Update Table" \
         8 "Drop Table" \
         9 "Back To Main Menu" \
         10 "Exit" 2>"$INPUT"
  menu_choice=$(<"$INPUT")

  case $menu_choice in
    1) ls .; tablesMenu ;;
    2) createTable ;;
    3) insert ;;
    4) deleteFromTable ;;
    5) selectAllFromTable ;;
    6) selectDataFromTable ;;
    7) updateTable ;;
    8) dropTable ;;
    9) mainMenu ;;
    10) exit ;;
    *) echo "Invalid Choice"; tablesMenu ;;
  esac
}

# Other functions remain unchanged
function deleteFromTable {
  echo -e "Enter Table Name: \c"
  read tName
  if [[ ! -f "$tName" ]]; then
    echo "Table $tName does not exist"
    tablesMenu
    return
  fi
  
  # Prompt the user to enter the column name they consider as the identifier
  echo -e "Enter Column Name for Identifying Rows: \c"
  read identifierColumn

  # Check if the provided column exists in the table
  identifierColumnIndex=$(awk -F'|' -v col="$identifierColumn" 'NR==1 { for(i=1; i<=NF; i++) { if($i == col) { print i } } }' "$tName")
  
  if [[ -z "$identifierColumnIndex" ]]; then
    echo "Column '$identifierColumn' not found in table $tName"
    tablesMenu
    return
  fi
  
  echo -e "Enter Value for $identifierColumn: \c"
  read identifierValue

  # Check if the provided value exists in the table
  rowNumber=$(awk -F'|' -v idx="$identifierColumnIndex" -v val="$identifierValue" '$idx == val { print NR }' "$tName")
  
  if [[ -z "$rowNumber" ]]; then
    echo "Row with $identifierColumn value '$identifierValue' not found in table $tName"
    tablesMenu
    return
  fi
  
  # Delete the row with the provided value
  sed -i -e "${rowNumber}d" -e '/^ *$/d' "$tName" 2>>./.error.log
  echo "Row with $identifierColumn value '$identifierValue' Deleted Successfully from $tName"
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

  if [ -f ".$tableName" ]; then
    echo "Table metadata already exists. Choose another name."
    tablesMenu
    return
  fi

  echo -e "Number of Columns:"
  read -r colsNum

  sep="|"
  rSep="\n"
  metaData="Field$sepType$sepKey"
  temp=""

  # Array to store column names
  declare -a columnNames

  for ((counter = 1; counter <= colsNum; counter++)); do
    echo -e "Name of Column No.$counter: \c"
    read -r colName

    # Check if column name already exists
    if [[ " ${columnNames[@]} " =~ " $colName " ]]; then
      echo "Column with name '$colName' already exists. Please choose a different name."
      counter=$((counter - 1))  # Decrement counter to re-enter column name
      continue
    fi

    # Add column name to array
    columnNames+=("$colName")

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

# Start the script
mainMenu
