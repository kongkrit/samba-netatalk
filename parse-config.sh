#!/bin/bash

function get_user_list () {
# pass filename as $1 and section_name as $2"

# 1. get rid of comments (lines that start with either # of ; )
# 2. get rid of everything before and including [section_name]
# 3. get rid of everything after and including the next [
# 4. get rid of empty lines

#    cat $1 | \
           sed -E 's/^\s*[#;].*$//g' "$1" | \
           sed -nE '/\s*\['"$2"'\]/,$p' | sed -E '/\s*\['"$2"'\]/d' | \
           sed -n '/\s*\[/q;p' | \
           sed -E '/^\s*$/d'
}

function read_section_list() {
# pass filename as $1 and section to ignore as $2

# sed 1. get rid of comment and blank lines
# sed 2. keep only section names and remove []
# sed 3. remove section $2 & remove leading-trailing spaces
# sed 4. remove blank lines and replace newline with semicolon
#  cat $1 | \
         sed -E 's/^\s*[#;].*$//g' "$1" | sed -E '/^\s*$/d' | \
         sed -nE '/\s*\[(.+)\].*$/p' | sed -E 's/\[(.+)\]/\1/g' | \
         sed -E 's/'"$2"'//g' | sed -E 's/^[ \t]*//;s/[ \t]*$//' | \
         sed -E '/^\s*$/d' | sed -z 's/\n/;/g;s/;$/\n/'
}

function read_section() {
# pass filename as $1 and section name as $2

# sed 1. get rid of comment and blank lines
# sed 2. get rid of white space before and after section name
# sed 3. get rid of everything before the specified section
# sed 4. get rid of everything after the current section & replace newline with semicolon
  SECTION_NAME=$2

  echo $(
         cat $1 | \
         sed -E 's/^\s*[#;].*$//g' "$1" | sed -E '/^\s*$/d' | \
         sed -E 's/\s*\[[ \t]*(.+)\].*$/\[\1\]/g'| sed -E 's/\[(.+)[ \t]+\]/\[\1\]/g' |
         sed -E '0,/\['"$SECTION_NAME"'\].*$/d' |
         sed -nE '/^[ \t]*\[/q;p' |  sed -z 's/\n/;/g;s/;$/\n/'
        )
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
  if [[ "$1" == "timemachine" ]]; then
    SECTION_TYPE="timemachine"
    FOUND_PATH="no";       FOUND_PATH_VALUE=""
    FOUND_SIZE_LIMIT="no"; FOUND_SIZE_LIMIT_VALUE=""
    FOUND_USER="no";       FOUND_USER_VALUE=""
  elif [[ "$1" == "global" ]]; then
    SECTION_TYPE="global"
                                 FOUND_WORKGROUP_VALUE="WORKGROUP"
                                 FOUND_SERVER_STRING_VALUE="Samba Ubuntu"
    FOUND_NETBIOS_NAME="no";     FOUND_NETBIOS_NAME_VALUE=""
    FOUND_WINS_SUPPORT="no";     FOUND_WINS_SUPPORT_VALUE="no"
    FOUND_PREFERRED_MASTER="no"; FOUND_PREFERRED_MASTER_VALUE="auto"
  else
    SECTION_TYPE="smb-share"
    FOUND_PATH="no";         FOUND_PATH_VALUE=""
    FOUND_COMMENT="no";      FOUND_COMMENT_VALUE=""
                             FOUND_BROWSABLE_VALUE="yes"
                             FOUND_GUEST_ACCESS_VALUE="no"
                             FOUND_RO_USERS_VALUE=""
                             FOUND_RW_USERS_VALUE=""
  fi
}

# pass SECTION KEY VALUE
function parse () {
  SEC=$1
  KEY=$2
  VAL=$3
  if [[ "$SECTION_TYPE" == "timemachine" ]]; then
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
        VAL=$(echo "$VAL" | sed -E 's/,+/ /g' | sed -E 's/[ \t]{2,}/ /g' )
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
  elif [[ "$SECTION_TYPE" == "global" ]]; then
    case "$KEY" in
      workgroup)
        if [[ "$VAL" =~ ^.+$ ]]; then
          FOUND_WORKGROUP_VALUE="$VAL"
        fi
        ;;
      "server string")
        if [[ "$VAL" =~ ^.+$ ]]; then
          FOUND_SERVER_STRING_VALUE="$VAL"
        fi
        ;;
      "netbios name")
        if [[ "$VAL" =~ ^.+$ ]]; then
          FOUND_NETBIOS_NAME="yes"; FOUND_NETBIOS_NAME_VALUE="$VAL"
        fi
        ;;
      "wins support")
        if ! [[ "$VAL" =~ ^(yes|no)$ ]]; then
          echo "parse: section [$SEC] $KEY = $VAL -- invalid value, use only yes|no."
          exit -1
        elif [[ "$VAL" == "yes" ]]; then
          FOUND_WINS_SUPPORT="yes"; FOUND_WINS_SUPPORT_VALUE="yes"
        fi
        ;;
      "preferred master")
        if ! [[ "$VAL" =~ ^(yes|auto)$ ]]; then
          echo "parse: section [$SEC] $KEY = $VAL -- invalid value, use only yes|auto."
          exit -1
        elif [[ "$VAL" == "yes" ]]; then
          FOUND_PREFERRED_MASTER="yes"; FOUND_PREFERRED_MASTER_VALUE="yes"
        fi
        ;;
      *)
    esac
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
        FOUND_BROWSABLE_VALUE="$VAL"
        ;;
      guest_access | "guest access")
        if ! [[ "$3" =~ ^(no|ro|rw)$ ]]; then
          echo "parse: section [$SEC] $KEY = $VAL -- invalid value, use only no|ro|rw."
          exit -1
        fi
        FOUND_GUEST_ACCESS_VALUE="$VAL"
        ;;
      ro_users | "read list")
        VAL=$(echo "$VAL" | sed -E 's/,+/ /g' | sed -E 's/[ \t]{2,}/ /g' )
        IFS=" " read -ra NAME_ARRAY <<< "$VAL"
        for name in "${NAME_ARRAY[@]}"; do
          if ! [[ "$USER_LIST" =~ (" $name ") ]]; then
            echo "parse: [$SEC] [$KEY] user [$name] is not in USER_LIST [$USER_LIST]"
            exit -1
          fi
        done
        FOUND_RO_USERS_VALUE="$VAL"
        ;;
      rw_users | "write list")
        VAL=$(echo "$VAL" | sed -E 's/,+/ /g' | sed -E 's/[ \t]{2,}/ /g' )
        IFS=" " read -ra NAME_ARRAY <<< "$VAL"
        for name in "${NAME_ARRAY[@]}"; do
          if ! [[ "$USER_LIST" =~ (" $name ") ]]; then
            echo "parse: [$SEC] [$KEY] user [$name] is not in USER_LIST [$USER_LIST]"
            exit -1
          fi
        done
        FOUND_RW_USERS_VALUE="$VAL"
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
    RANDOM_USER="$RANDOM_USER""$((RANDOM%10))"
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
  RO_RW_USERS=$(echo "$RO_RW_USERS" | sed -E 's/[ \t]+$//g')
}

# pass in section name
function generate_text () {

SECTION_TEXT=$'\n'"[""$1""]"$'\n'
#  SECTION_TEXT="$SECTION_TEXT""[""$1""]"$'\n'
  if [[ "$SECTION_TYPE" == "timemachine" ]]; then
    # handle path
    if [[ "$FOUND_PATH" == "yes" ]]; then
      SECTION_TEXT="$SECTION_TEXT""  path = ""$FOUND_PATH_VALUE"$'\n'
    else
      echo "path for section $SECTION_NAME not found"
    fi
    # handle vol size limit
    [[ "$FOUND_SIZE_LIMIT" == "yes" ]] && SECTION_TEXT="$SECTION_TEXT""  vol size limit = ""$FOUND_SIZE_LIMIT_VALUE"$'\n'
    # handle user
    [[ "$FOUND_USER" == "yes" ]] && SECTION_TEXT="$SECTION_TEXT"";  user = ""$FOUND_USER_VALUE"$'\n'
  elif [[ "$SECTION_TYPE" == "global" ]]; then
    # handle workgroup
    SECTION_TEXT="$SECTION_TEXT""  workgroup = ""$FOUND_WORKGROUP_VALUE"$'\n'
    # handle server string
    SECTION_TEXT="$SECTION_TEXT""  server string = ""$FOUND_SERVER_STRING_VALUE"$'\n'
    # handle netbios name
    [[ "$FOUND_NETBIOS_NAME" == "yes" ]] && SECTION_TEXT="$SECTION_TEXT""  netbios name = ""$FOUND_NETBIOS_NAME_VALUE"$'\n'
    # handle wins support
    [[ "$FOUND_WINS_SUPPORT" == "yes" ]] && SECTION_TEXT="$SECTION_TEXT""  wins support = ""$FOUND_WINS_SUPPORT_VALUE"$'\n'
    # handle preferred master
    [[ "$FOUND_PREFERRED_MASTER" == "yes" ]] && \
      SECTION_TEXT="$SECTION_TEXT""  preferred master = ""$FOUND_PREFERRED_MASTER_VALUE"$'\n'
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

CONFIG_FILENAME="$1"

USER_SECTION="username-password-list"

SAMBA_USER_PASSWORD="$(get_user_list "$CONFIG_FILENAME" "$USER_SECTION")"
add_samba_users $SAMBA_USER_PASSWORD

echo "user list is [$USER_LIST]"

gen_random_user

SECTION_TEXT=""

#echo "---- share_list ----"
IFS=";" read -ra SECTION_LIST <<< "$(read_section_list "$CONFIG_FILENAME" "$USER_SECTION")"

ALL_SMB_GLOBAL_TEXT=""
ALL_SMB_SHARE_TEXT=""
ALL_AFPD_TEXT=""
for i in "${SECTION_LIST[@]}"; do
    SECTION_NAME="$i"
    parser_init "$SECTION_NAME"
    IFS=";" read -ra SECTION_LIST <<< "$(read_section "$1" "$i")"
    for j in "${SECTION_LIST[@]}"; do
      KEY="$(echo "$j" | cut -d'=' -f1 | sed -E 's/^[ \t]*//;s/[ \t]*$//' )"
      VAL="$(echo "$j" | cut -d'=' -f2 | sed -E 's/^[ \t]*//;s/[ \t]*$//' )"
      parse "$SECTION_NAME" "$KEY" "$VAL"
    done
    generate_text "$SECTION_NAME"
    if [[ "$SECTION_TYPE" == "timemachine" ]]; then
      ALL_AFPD_TEXT="$ALL_AFPD_TEXT""$SECTION_TEXT"
    elif [[ "$SECTION_TYPE" == "global" ]]; then
      ALL_SMB_GLOBAL_TEXT="$ALL_SMB_GLOBAL_TEXT""$SECTION_TEXT"
    else
      ALL_SMB_SHARE_TEXT="$ALL_SMB_SHARE_TEXT""$SECTION_TEXT"
   fi
#    echo "---- SECTION: $SECTION_NAME TIME MACHINE: $SECTION_TYPE ----"
#    echo "$SECTION_TEXT""----"
done

echo "---- ALL_AFPD_TEXT ----"
echo "$ALL_AFPD_TEXT"
echo "---- ALL_SMB_GLOBAL_TEXT ----"
echo "$ALL_SMB_GLOBAL_TEXT"
echo "---- ALL_SMB_SHARE_TEXT ----"
echo "$ALL_SMB_SHARE_TEXT"
