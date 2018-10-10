#!/usr/bin/env bash
shopt -s globstar
GLOBIGNORE=.:..

### CHANGE THIS VARIABLE ###
user="Matt"

## VARIABLES ##
debug=0  # Debug output lvl1
debug2=1 # Enumerate files before copy
ROOT_DEST="/home/${user}/backup"
YELLOW='\033[0;33m' # Yeller color
RED='\033[0;31m' # Red color
GREEN='\033[0;32m' # Green color
NC='\033[0m' # No color
varwww=0
etcnginx=0
DATE=`date +%Y.%m.%d.%H.%M`
dest=''

# Debugging does output in a test folder
if [ $debug -eq 1 ] ; then
    echo -e "${RED}Debugging enabled.${NC}"
    ROOT_DEST="/home/Matt/backup/test"
fi

# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
mkdir -p "${ROOT_DEST}/log" # Make sure log directory exists
exec > >(tee -i "${ROOT_DEST}/log/${DATE}.log")

# Redirect STDERR to STDOUT
exec 2>&1


## FUNCTIONS ##

# Copy command
function copy() {
    # Check for args
    if [ $# -lt 2 ] ; then
        echo -e "${RED}Error: backup() called without arguments.${NC}"
        exit
    fi

    indir=$1
    outdir=$2

    printf "Copying ${indir} to ${outdir}..."

    cp -p $indir $outdir
    result=$?
    if [ $result -ne 0 ] ; then
        echo -e "${RED}File copy failed.${NC}"
        echo "exiting with status code ${result}..."
        exit
    else
        printf "${GREEN}Done${NC}\n"
    fi

}

# Backup function
# - first parameter is input directory
# - second parameter is output directory
function backup() {
    # Check for args
    if [ $# -lt 2 ] ; then
        echo -e "${RED}Error: backup() called without arguments.${NC}"
        exit
    fi

    bindir="$1"
    boutdir="$2"

    if [ $debug -eq 1 ]
    then
        echo "backup function"
        echo "bindir = ${bindir}"
        echo "boutdir = ${boutdir}"
    fi

    if [ $debug2 -eq 1 ] ; then
        search="${bindir}/**"
        for filename in ${search}; do
            if [ -d "${filename}" ]
            then
                # Check if root cwd
                echo "directory: ${filename}"

                if [ "$filename" = "$bindir/" ] ; then
                    echo -e "${YELLOW}Ignoring - . directory.${NC}"
                    continue
                fi

                # If not cwd, create dir
                strip=${filename#"$bindir"}
                newdir="${boutdir}${strip}"

                echo -e "${YELLOW}Creating ${newdir}...${NC}"
                createdir $newdir
            else
                strip=${filename#"$bindir"}
                outfile="${boutdir}${strip}"

#                echo "file: ${filename}"
#                echo "stripped: ${strip}"
#                read -p "Press ENTER to copy..." inaskflj

                copy $filename $outfile

#                read -p "Press ENTER to continue..." akfjlkjasfklje
            fi
        done
    fi

    read -p "Done, continue with next batch? >" afejoiajf

#    cp -a "${indir}/"* $outdir
#    result=$?
#    if [ $result -ne 0 ] ; then
#        echo -e "${RED}File copy failed.${NC}"
#        echo "exiting with status code ${result}..."
#        exit
#    fi

#    cp -a "${indir}/."* $outdir
#    result=$?
#    if [ $result -ne 0 ] ; then
#        echo -e "${RED}File copy failed.${NC}"
#        echo "exiting with status code ${result}..."
#        exit
#    fi
}

function createdir() {
    if [ $# -eq 0 ] ; then
        echo -e "${RED}Error: createdir() called without arguments.${NC}"
        exit
    fi

    newdest="$1" # First parameter is new destination

    echo "Creating folder: ${newdest}"...
    mkdir "${newdest}"
    if [ $? -ne 0 ] ; then
        echo -e "${RED}Directory creation failed."
        read -p $'The folder may already exist. Continuing may cause a loss of data.'
        case $response in
            [Yy]* ) echo "Ok, if you're sure...";;
            [Nn]* ) echo "Exiting..."; exit;;
            * ) echo "Exiting..."; exit;;
        esac
    fi
}


# Intro, ask whether to proceed
echo
echo -e "${YELLOW}========================"
echo "  Custom Backup Script"
echo "========================"
echo
echo "Date: ${DATE}"
echo
echo -e "${RED}NOTE: This will back everything up into ~/backup."
echo "It will create a folder based on the current date and time."
echo -e "${NC}" # Change color back to default
read -p "Do you want to start backup? (Y/n)>" response
case $response in
    [Yy]* ) echo -e "${GREEN}OK, proceeding...${NC}";;
    [Nn]* ) echo "Goodbye."; exit;;
    * ) echo -e "${GREEN}OK, proceeding...${NC}";;
esac
echo

# Create the new backup directory
dest="${ROOT_DEST}/${DATE}"
createdir $dest

# Ask whether to back up /var/www/
read -p $'Back up \e[36m/var/www/\e[0m? (Y/n)>' response
case $response in
    [Yy]* ) echo -e "${GREEN}OK, proceeding...${NC}"; varwww=1;;
    [Nn]* ) echo -e "${RED}Ok, ignoring...${NC}";;
    * ) echo -e "${GREEN}OK, proceeding...${NC}"; varwww=1;;
esac
echo

# Ask whether to back up /etc/nginx/
read -p $'Back up \e[36m/etc/nginx/\e[0m? (Y/n)>' response
case $response in
    [Yy]* ) echo -e "${GREEN}OK, proceeding...${NC}"; etcnginx=1;;
    [Nn]* ) echo -e "${RED}OK, ignoring...${NC}";;
    * ) echo -e "${GREEN}OK, proceeding...${NC}"; etcnginx=1;;
esac
echo

# Backup and create directories as needed
if [ $etcnginx -eq 1 ] ; then
    # Back up /etc/nginx
    newdir="${dest}/etc_nginx"
    createdir $newdir
    backup "/etc/nginx" $newdir
fi

if [ $varwww -eq 1 ] ; then
    # Back up /var/www
    newdir="${dest}/var_www"
    createdir $newdir
    backup "/var/www" $newdir
fi


# Final debug statements
if [ $debug -eq 1 ]
then
    echo "Printf says etcnginx is ${etcnginx} and varwww is ${varwww}."
fi

# backup "/var/www"

# Reset terminal color when done.
echo -e "${NC}Done."
