#!/bin/bash

function get_user_list () {
#    echo "filename=$1 section_name=$2 $#"

# 1. get rid of comments (lines that start with either # of ; )
# 2. get rid of everything before and including [section_name]
# 3. get rid of everything after and including the next [
# 4. get rid of empty lines

    echo $(cat $1 | \
           sed -E 's/^\s*[#;].*$//g' | \
           sed -nE '/\s*\['"$2"'\]/,$p' | sed -E '/\s*\['"$2"'\]/d' | \
           sed -n '/\s*\[/q;p' | \
           sed -E '/^\s*$/d' )
}

function read_section_list() {
# sed 1. get rid of comment and blank lines
# sed 2. keep only section names and remove []
# sed 3. remove section $USER_SECTION & remove leading-trailing spaces
# sed 4. remove blank lines and replace newline with semicolon
  echo $(cat $1 | \
         sed -E 's/^\s*[#;].*$//g' | sed -E '/^\s*$/d' | \
         sed -nE '/\s*\[(.+)\].*$/p' | sed -E 's/\[(.+)\]/\1/g' | \
         sed -E 's/'"$USER_SECTION"'//g' | sed -E 's/^[ \t]*//;s/[ \t]*$//' | \
         sed -E '/^\s*$/d' | sed -z 's/\n/;/g;s/;$/\n/' )
}

function read_section() {

# sed 1. get rid of comment and blank lines
# sed 2. get rid of white space before and after section name
# sed 3. get rid of everything before the specified section
# sed 4. get rid of everything after the current section & replace newline with semicolon
  SECTION_NAME=$2

  echo $(cat $1 | \
         sed -E 's/^\s*[#;].*$//g' | sed -E '/^\s*$/d' | \
         sed -E 's/\s*\[[ \t]*(.+)\].*$/\[\1\]/g'| sed -E 's/\[(.+)[ \t]+\]/\[\1\]/g' |
         sed -E '0,/\['"$SECTION_NAME"'\].*$/d' |
         sed -nE '/^[ \t]*\[/q;p' |  sed -z 's/\n/;/g;s/;$/\n/' )
}

function add_samba_users () {
    echo "**** add_samba_users ****"
    echo " groupadd sambausers ****"
##    groupadd sambausers

    USER_LIST=" "

    i=1
    while [ "$i" -le "$#" ]; do
        u=${!i}
        USER_LIST="$USER_LIST""$u"" "
        i=$((i+1))
        p=${!i}
        i=$((i+1))
        echo "==== username [$u] password [$p]"
##        echo " useradd -M -s /usr/sbin/nologin $u"
##        useradd -M -s /usr/sbin/nologin $u
##        echo " echo \"$u:$p\" | chpasswd"
##        echo "$u:$p" | chpasswd
##        echo " changing user [$u] userid to $PUID and usergroup to $PGID..."
##        SEDEX="s/${u}:x:[0-9]+:[0-9]+:/${u}:x:${PUID}:${PGID}:/g"
##        echo " SEDEX is $SEDEX"
##        cat /etc/passwd | sed -E $SEDEX > /tmp/passy
##        cp /tmp/passy /etc/passwd && rm /tmp/passy
##        echo " (echo \"$p\"; echo \"$p\") | smbpasswd -s -a $u"
##        (echo "$p"; echo "$p") | smbpasswd -s -a $u
##        echo " smbpasswd -e $u"
##        smbpasswd -e $u
##        echo " usermod -aG sambausers $u"
##        usermod -aG sambausers $u
    done
    echo "**** done add_samba_users ****"
}

# pass in $SECTION_NAME
function parser_init () {
#  SECTION_TEXT="[""$1""]"$'\n'
  if [ "$1" == "timemachine" ]; then
    IS_TIME_MACHINE="yes"
    FOUND_PATH="no";       FOUND_PATH_VALUE=""
    FOUND_SIZE_LIMIT="no"; FOUND_SIZE_LIMIT_VALUE=""
    FOUND_USER="no";       FOUND_USER_VALUE=""
  else
    IS_TIME_MACHINE="no"
    FOUND_PATH="no";         FOUND_PATH_VALUE=""
    FOUND_COMMENT="no";      FOUND_COMMENT_VALUE=""
    FOUND_BROWSABLE="no";    FOUND_BROWSABLE_VALUE="yes"
    FOUND_GUEST_ACCESS="no"; FOUND_GUEST_ACCESS_VALUE="no"
    FOUND_RO_USERS="no";     FOUND_RO_USERS_VALUE=""
    FOUND_RW_USERS="no";     FOUND_RW_USERS_VALUE=""
  fi
}

# pass SECTION KEY VALUE
function parse () {
  SEC=$1
  KEY=$2
  VAL=$3
  if [ "$IS_TIME_MACHINE" == "yes" ]; then
    case "$KEY" in
      path)
        FOUND_PATH="yes"; FOUND_PATH_VALUE="$VAL"
        ;;
      size_limit | "vol size limit")
        FOUND_SIZE_LIMIT="yes"; FOUND_SIZE_LIMIT_VALUE="$VAL"
        if ! [[ "$VAL" =~ ^[0-9]+$ ]]; then
          echo "parse: section [$SEC] vol size limit is [$VAL] not integer"
          exit -1
        fi
        ;;
      user)
        VAL=$(echo $VAL | sed -E 's/,+/ /g' | sed -E 's/[ \t]{2,}/ /g' )
        if ! [[ "$USER_LIST" =~ (" $VAL ") ]]; then
          echo "parse: [$SEC] [$KEY] user [$VAL] is not in USER_LIST [$USER_LIST]"
          exit -1
        fi
        FOUND_USER="yes"; FOUND_USER_VALUE="$VAL"
        ;;
      *)
        echo "unknown key TIMEMACHINE section[$SEC] key [$KEY] value [$VAL]"
        exit -1
        ;;
    esac
#    echo "parse: section [$SEC] : $KEY = $VAL"
  else
    case "$KEY" in
      path)
        FOUND_PATH="yes"; FOUND_PATH_VALUE="$VAL"
        ;;
      comment)
        FOUND_COMMENT="yes"; FOUND_COMMENT_VALUE="$VAL"
        ;;
      browsable | browseable)
        if ! [[ "$VAL" =~ ^(yes|no)$ ]]; then
          echo "parse: section [$SEC] $KEY = $VAL -- invalid value, use only yes|no."
          exit -1
        fi
        FOUND_BROWSABLE="yes";  FOUND_BROWSABLE_VALUE="$3"
        ;;
      guest_access | "guest access")
        if ! [[ "$3" =~ ^(no|ro|rw)$ ]]; then
          echo "parse: section [$SEC] $KEY = $VAL -- invalid value, use only no|ro|rw."
          exit -1
        fi
        FOUND_GUEST_ACCESS="yes"; FOUND_GUEST_ACCESS_VALUE="$VAL"
        ;;
      ro_users | "read list")
        VAL=$(echo $VAL | sed -E 's/,+/ /g' | sed -E 's/[ \t]{2,}/ /g' )
        IFS=" " read -ra NAME_ARRAY <<< "$VAL"
        for name in "${NAME_ARRAY[@]}"; do
          if ! [[ "$USER_LIST" =~ (" $name ") ]]; then
            echo "parse: [$SEC] [$KEY] user [$name] is not in USER_LIST [$USER_LIST]"
            exit -1
          fi
        done
        FOUND_RO_USERS="yes"; FOUND_RO_USERS_VALUE="$VAL"
        ;;
      rw_users | "write list")
        VAL=$(echo $VAL | sed -E 's/,+/ /g' | sed -E 's/[ \t]{2,}/ /g' )
        IFS=" " read -ra NAME_ARRAY <<< "$VAL"
        for name in "${NAME_ARRAY[@]}"; do
          if ! [[ "$USER_LIST" =~ (" $name ") ]]; then
            echo "parse: [$SEC] [$KEY] user [$name] is not in USER_LIST [$USER_LIST]"
            exit -1
          fi
        done
        FOUND_RW_USERS="yes"; FOUND_RW_USERS_VALUE="$VAL"
        ;;
      *)
        echo "unknown key section[$SEC] [$KEY] value [$VAL]"
        exit -1
        ;;
    esac
#    echo "parse: section [$SEC] : $KEY = $VAL"
  fi
}

function gen_random_user() {
  RANDOM_USER="u"
  for randomlength in {1..11}; do
    RANDOM_USER="$RANDOM_USER""$(($RANDOM%10))"
  done
  echo "RANDOM_USER is $RANDOM_USER"
}

function union_users() {
  IFS=" " read -ra arr1 <<< "$FOUND_RO_USERS_VALUE"
  IFS=" " read -ra arr2 <<< "$FOUND_RW_USERS_VALUE"

  declare -A arr4
  for k in "${arr1[@]}" "${arr2[@]}"; do arr4["$k"]=1; done
  arr5=("${!arr4[@]}")
  RO_RW_USERS=""
  for ro_rw_username in "${arr5[@]}"; do
    RO_RW_USERS="$RO_RW_USERS"" ""$ro_rw_username"
  done
  RO_RW_USERS=$(echo $RO_RW_USERS | sed -E 's/[ \t]+$//g')
}

# pass in section name
function generate_text () {

SECTION_TEXT=$'\n'"[""$1""]"$'\n'
#  SECTION_TEXT="$SECTION_TEXT""[""$1""]"$'\n'
  if [ "$IS_TIME_MACHINE" == "yes" ]; then
    # handle path
    if [ "$FOUND_PATH" == "yes" ]; then
      SECTION_TEXT="$SECTION_TEXT""  path = ""$FOUND_PATH_VALUE"$'\n'
    else
      echo "path for section $SECTION_NAME not found"
    fi
    # handle vol size limit
    [[ "$FOUND_SIZE_LIMIT" == "yes" ]] && SECTION_TEXT="$SECTION_TEXT""  vol size limit = ""$FOUND_SIZE_LIMIT_VALUE"$'\n'
  else
    # handle comment
    [[ "$FOUND_COMMENT" == "yes" ]] && SECTION_TEXT="$SECTION_TEXT""  comment = ""$FOUND_COMMENT_VALUE"$'\n'
    # handle path
    if [ "$FOUND_PATH" == "yes" ]; then
      SECTION_TEXT="$SECTION_TEXT""  path = ""$FOUND_PATH_VALUE"$'\n'
    else
      echo "path for section $SECTION_NAME not found"
    fi
    # handle browsable
    [[ "$FOUND_BROWSABLE_VALUE" == "no" ]] && SECTION_TEXT="$SECTION_TEXT""  browsable = no"$'\n'
    # handle guest ok
    [[ "$FOUND_GUEST_ACCESS_VALUE" != "no" ]] && SECTION_TEXT="$SECTION_TEXT""  guest ok = yes"$'\n'
    # handle read only
    [[ "$FOUND_GUEST_ACCESS_VALUE" == "rw" ]] && SECTION_TEXT="$SECTION_TEXT""  read only = no"$'\n'
    # handle read list
    [[ "$FOUND_GUEST_ACCESS_VALUE" == "no" && "$FOUND_RO_USERS_VALUE" != "" ]] && \
      SECTION_TEXT="$SECTION_TEXT""  read list = ""$FOUND_RO_USERS_VALUE"$'\n'
    # handle write list
    [[ "$FOUND_GUEST_ACCESS_VALUE" != "rw" && "$FOUND_RW_USERS_VALUE" != "" ]] && \
      SECTION_TEXT="$SECTION_TEXT""  write list = ""$FOUND_RW_USERS_VALUE"$'\n'
    # handle valid users
    if [ "$FOUND_GUEST_ACCESS_VALUE" == "no" ]; then
      if [[ "$FOUND_RO_USERS_VALUE" == "" && "$FOUND_RW_USERS_VALUE" == "" ]]; then
        SECTION_TEXT="$SECTION_TEXT""  valid users = ""$RANDOM_USER"$'\n'
      else
        union_users
        SECTION_TEXT="$SECTION_TEXT""  valid users = ""$RO_RW_USERS"$'\n'
      fi
    fi
    # handle force directory mode and force create mode
    [[ "$FOUND_GUEST_ACCESS_VALUE" == "no" ]] && \
      SECTION_TEXT="$SECTION_TEXT""  force directory mode = 2770"$'\n'"  force create mode = 0660"$'\n'
    [[ "$FOUND_GUEST_ACCESS_VALUE" == "ro" ]] && \
      SECTION_TEXT="$SECTION_TEXT""  force directory mode = 2775"$'\n'"  force create mode = 0664"$'\n'
    [[ "$FOUND_GUEST_ACCESS_VALUE" == "rw" ]] && \
      SECTION_TEXT="$SECTION_TEXT""  force directory mode = 2777"$'\n'"  force create mode = 0666"$'\n'
  fi
#  SECTION_TEXT="$SECTION_TEXT"$'\n'
}

if [ "$#" -eq "1" ] && [ -f "$1" ]; then
  echo "starting script. processing [""$1""]..."
else
  echo "missing filename"
  exit -1
fi

USER_SECTION="username-password-list"

SAMBA_USER_PASSWORD="$(get_user_list "$1" "$USER_SECTION")"
add_samba_users $SAMBA_USER_PASSWORD

echo "user list is [$USER_LIST]"

gen_random_user

SECTION_TEXT=""

#echo "---- share_list ----"
IFS=";" read -ra SECTION_LIST <<< "$(read_section_list "$1")"

ALL_SAMBA_TEXT=""
ALL_AFPD_TEXT=""
for i in "${SECTION_LIST[@]}"; do
    SECTION_NAME="$i"
    parser_init "$SECTION_NAME"
    IFS=";" read -ra SECTION_LIST <<< "$(read_section "$1" "$i")"
    for j in "${SECTION_LIST[@]}"; do
      KEY="$(echo $j | cut -d'=' -f1 | sed -E 's/^[ \t]*//;s/[ \t]*$//' )"
      VAL="$(echo $j | cut -d'=' -f2 | sed -E 's/^[ \t]*//;s/[ \t]*$//' )"
      parse "$SECTION_NAME" "$KEY" "$VAL"
    done
    generate_text "$SECTION_NAME"
    if [[ "$IS_TIME_MACHINE" == "yes" ]]; then
      ALL_AFPD_TEXT="$ALL_AFPD_TEXT""$SECTION_TEXT"
    else
      ALL_SAMBA_TEXT="$ALL_SAMBA_TEXT""$SECTION_TEXT"
   fi
#    echo "---- SECTION: $SECTION_NAME TIME MACHINE: $IS_TIME_MACHINE ----"
#    echo "$SECTION_TEXT""----"
done

echo "---- ALL_AFPD_TEXT ----"
echo "$ALL_AFPD_TEXT"
echo "---- ALL_SAMBA_TEXT ----"
echo "$ALL_SAMBA_TEXT"
