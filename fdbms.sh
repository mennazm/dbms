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
  echo "| 3. Insert Into Table          |"
  echo "| 4. deleteFromTable            |"
  echo "| 5. selectAllFromTable         |"
  echo "| 6. selectDataFromTable        |"
  echo "| 7. updateTable                |"
  echo "| 8. Drop Table                 |"   
  echo "| 9. Back To Main Menu          |"
  echo "|10. Exit                       |"
  echo "+-------------------------------+"
  echo -e "Enter Choice: \c"
  read -r choice

  case $choice in
    1) ls .; tablesMenu ;;
    2) createTable ;;
    3) insert ;;
    4) deleteFromTable;;
    5) selectAllFromTable ;;
    6) selectDataFromTable ;;
    7) updateTable ;; 
    8) dropTable;;
    9) clear; cd ../.. 2>> "$ERROR_LOG"; mainMenu ;;
    10) exit ;;
    *) echo "Invalid Choice"; tablesMenu ;;
  esac
}

function deleteFromTable {
  echo -e "Enter Table Name: \c"
  read tName
  if [[ ! -f "$tName" ]]; then
    echo "Table $tName does not exist"
    tablesMenu
    return
  fi
  echo -e "Enter Unique Value Column name: \c"
  read uniqueField
  echo -e "Enter Unique Value: \c"
  read uniqueValue
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$uniqueField'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "Column '$uniqueField' Not Found"
    tablesMenu
  else
    res=$(awk -v fid="$fid" -v val="$uniqueValue" 'BEGIN{FS="|"} $fid == val {print NR}' $tName 2>>./.error.log)
    if [[ $res == "" ]]
    then
      echo "Value Not Found"
      tablesMenu
    else
      sed -i -e "${res}d" -e '/^ *$/d' $tName 2>>./.error.log
      echo "Row with unique value '$uniqueValue' Deleted Successfully"
      tablesMenu
    fi
  fi
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



function selectAllFromTable {
  echo -e "Enter Table Name: \c"
  read tableName

  # Check if the table exists
  if [ ! -f "$tableName" ]; then
    echo "Table $tableName does not exist."
    tablesMenu
    return
  fi

  # Print column names
  awk 'NR==1' "$tableName"

  # Print data
  awk 'NR>1' "$tableName"

  tablesMenu
}

function selectDataFromTable {
  echo -e "Enter Table Name: \c"
  read tableName

  # Check if the table exists
  if [ ! -f "$tableName" ]; then
    echo "Table $tableName does not exist."
    tablesMenu
    return
  fi

  # Print column names
  echo "Column names:"
  header=$(awk 'NR==1' "$tableName")
  echo "$header"

  echo -e "Enter condition (in the format 'column_name=value'): \c"
  read condition

  # Extract column name and value from the condition
  colName=$(echo "$condition" | awk -F "=" '{print $1}')
  value=$(echo "$condition" | awk -F "=" '{print $2}')

  echo "Condition: $condition"
  echo "Column name: $colName"
  echo "Value: $value"

  # Check if the column exists in the table
  if ! awk -F "|" -v colName="$colName" 'NR==1 {for (i=1; i<=NF; i++) if ($i == colName) exit 0; exit 1}' <<< "$header"; then
    echo "Column $colName does not exist in the table."
    tablesMenu
    return
  fi

  # Print data matching the condition
  matchingRows=$(awk -v colName="$colName" -v value="$value" -F "|" 'NR>1 {if (index($colName, value)) print $0}' "$tableName")

  if [ -z "$matchingRows" ]; then
    echo "No matching rows found."
  else
    echo "Matching rows:"
    echo "$matchingRows"
  fi

  tablesMenu
}

function updateTable {
  echo -e "Enter Table Name: \c"
  read -r tableName
  
  # Check if the table file exists  
  if [ ! -f "$tableName" ]; then
    echo "Table does not exist."
    tablesMenu
    return
  fi
  
  # Get the primary key column name (assuming it is the first column)
  primaryKey=$(awk -F "|" 'NR==1 {print $1; exit}' "$tableName")
  
  # Prompt for the primary key value  
  echo -e "Enter $primaryKey for the row to update: \c"
  read -r primaryKeyValue
  
  # Check if the condition value is empty  
  if [ -z "$primaryKeyValue" ]; then
    echo "$primaryKey cannot be empty."
    tablesMenu
    return
  fi
  
  # Check if the primary key value exists in the table
  if ! grep -q "^$primaryKeyValue|" "$tableName"; then
    echo "Row with $primaryKey=$primaryKeyValue not found."
    tablesMenu
    return
  fi
  
  # Create a temporary file to store the updated table  
  tmpfile=$(mktemp)
  
  # Loop to update columns
  while true; do
    # Prompt user to select the column to update
    echo "Select the column to update:"
    echo "1. ID"
    echo "2. Name"
    echo "3. Age"
    read -r choice
    
    # Check the user's choice and set the column variable accordingly
    case $choice in
      1) column="ID";;
      2) column="Name";;
      3) column="Age";;
      *) echo "Invalid choice"; tablesMenu; return;;
    esac
    
    # Prompt for the new value for the selected column
    echo -e "Enter new value for $column: \c"
    read -r newValue
    
    # Update the table
    awk -v pKey="$primaryKey" -v pKeyValue="$primaryKeyValue" -v col="$column" -v newVal="$newValue" -F "|" '
      BEGIN { OFS = FS }
      {
        if ($1 == pKeyValue) {
          if (col == "ID") {
            $1 = newVal
          } else if (col == "Name") {
            $2 = newVal
          } else if (col == "Age") {
            $3 = newVal
          }
        }
        print $0
      }
    ' "$tableName" > "$tmpfile" && mv "$tmpfile" "$tableName"
    
    # Ask user if they want to update more values
    echo -e "Do you want to update more values in this row? (1: Yes, 2: No): \c"
    read -r updateMore
    
    # If the user chooses not to update more values, exit the loop
    if [ "$updateMore" = "2" ]; then
      break
    fi
  done
  
  # Display the updated table  
  echo "Updated Table:"
  cat "$tableName"
  echo "Row updated successfully."
  
  tablesMenu
}



# Start the script
mainMenu

