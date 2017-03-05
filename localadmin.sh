#!/bin/bash
# The most badass admin initializer ever, personally hand crafted for fidst, cheers!
# @author: dot_cipher

echo "Setting hidden user"

# Read through symlink if symlinked
SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
# Get running user
ACTIVE_USER=$(whoami)

# Defaults
DEFAULT_ADMIN_USERNAME="localadmin"
DEFAULT_ADMIN_FULL_NAME="Imgur Local IT"

print_usage() {
    echo "${SCRIPT_NAME} [OPTIONS]" >&2
    echo "OPTIONS:"
    echo -e "\t-u USERNAME\tSets the username for the new admin account (Default = ${DEFAULT_ADMIN_USERNAME})"
    echo -e "\t-n \"Full Name\"\tSets the full name, make sure to quote it if it has spaces (Default = \"${DEFAULT_ADMIN_FULL_NAME}\")"
    echo -e "\t-h\t\tPrints this awesome help message"
}

# Writes next unused unique user id to stdout via echo
get_next_unique_user_id() {
    LAST_ID=`dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1`
    echo $((LAST_ID + 1))
}

# $1 = username
# $2 = full name
# $3 = password
init_admin() {
    if [ -z "${1}" ]; then
        echo "[ERROR]: Must provide username for generating admin account"
        exit -1
    fi
    if [ -z "${2}" ]; then
        echo "[ERROR]: Must provide full name for generating admin account"
        exit -1
    fi
        if [ -z "${3}" ]; then
        echo "[ERROR]: Must provide password for generating admin account"
        exit -1
    fi
    USERNAME="${1}"
    USER_FULL_NAME="${2}"
    USER_PASSWORD="${3}"
    USER_ROOT="/Users/${USERNAME}"
    mkdir -p "${USER_ROOT}"
    dscl . -create "${USER_ROOT}" IsHidden 1
    dscl . -create "${USER_ROOT}" UserShell /bin/bash
    dscl . -create "${USER_ROOT}" RealName "${USER_FULL_NAME}"
    dscl . -create "${USER_ROOT}" UniqueID $(eval get_next_unique_user_id)
    dscl . -create "${USER_ROOT}" PrimaryGroupID 80
    dscl . -create "${USER_ROOT}" NFSHomeDirectory "${USER_ROOT}"
    dscl . -passwd "${USER_ROOT}" "${USER_PASSWORD}"
    dscl . -append /Groups/admin GroupMembership "${USERNAME}"
    dscl . -append /Groups/wheel GroupMembership "${USERNAME}"
    USER_HIDDEN_HOME="/var/${USERNAME}"
    # echo "Making ${USER_HIDDEN_HOME}"
    mkdir -p "${USER_HIDDEN_HOME}"
    # echo "mkdir -p ${USER_HIDDEN_HOME}"
    mv "${USER_ROOT}" "/var/${USERNAME}"
    dscl . -create "${USER_ROOT}" NFSHomeDirectory "${USER_HIDDEN_HOME}"
    # dscl . -delete "/SharePoints/${USERNAME}"
}

# Validate root user is running script
if [ "${ACTIVE_USER}" != "root" ]; then
    echo "[ERROR]: Must be root to run script, please rerun via: sudo ${SCRIPT_NAME}"
    exit 1
fi

# Get optargs
INPUT_USERNAME=""
INPUT_FULL_NAME=""
while getopts "u:n:h" opt; do
    case $opt in
        u)
            INPUT_USERNAME="${OPTARG}"
            ;;
        n)
            INPUT_FULL_NAME="${OPTARG}"
            ;;
        h)
            print_usage
            exit 1
            ;;
        \?)
            print_usage
            exit 1
            ;;
        :)
            echo "[ERROR]: Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# Use defaults if nothing is provided via cli
if [[ -z "${INPUT_USERNAME// }" ]]; then
    INPUT_USERNAME="${DEFAULT_ADMIN_USERNAME}"
fi
if [[ -z "${INPUT_FULL_NAME// }" ]]; then
    INPUT_FULL_NAME="${DEFAULT_ADMIN_FULL_NAME}"
fi

# Prompt for password
echo -n "Enter New Admin Password: "
read -s PASSWORD

# For debugging purposes only:
# echo "${INPUT_USERNAME} ${INPUT_FULL_NAME} ${PASSWORD}"

init_admin "${INPUT_USERNAME}" "${INPUT_FULL_NAME}" "${PASSWORD}"


#stuff by fidst
clear
#tells you that the user has been created and clears the screen for next section
echo "Congrats, ${DEFAULT_ADMIN_FULL_NAME} has been created. "
#current logged in full name username
CURRENT_LOGGED_IN_FN=$(id -F)
CURRENT_LOGGED_IN_UN=$(id -un)

# Ask for unit Tag
echo -n "Enter the unit Tag: "
read -e UNITTAG

#create the user txt file to the desktop with full name and Tag
echo "NAME: ${CURRENT_LOGGED_IN_FN}" > ./Desktop/${CURRENT_LOGGED_IN_FN}.txt
echo "TAG: ${UNITTAG}" >> ./Desktop/${CURRENT_LOGGED_IN_FN}.txt
echo " " >> ./Desktop/${CURRENT_LOGGED_IN_FN}.txt
echo "FILE VAULT INFO: " >> ./Desktop/${CURRENT_LOGGED_IN_FN}.txt
echo " " >> ./Desktop/${CURRENT_LOGGED_IN_FN}.txt


#enabling filefault. This also adds both the current user as well as the just created user into the allowed list. This forced the localadmin to show on the login screen
echo The next step will ask for the
fdesetup enable -user ${CURRENT_LOGGED_IN_UN} -usertoadd ${DEFAULT_ADMIN_USERNAME} >> ./Desktop/${CURRENT_LOGGED_IN_FN}.txt

echo "DOCUMENT THIS KEY! IT WILL BE THE FIRST AND ONLY TIME YOU WILL SEE IT."
read -rsp $'Press enter to continue...\n'
