# pass in $SECTION_NAME
function parser_init () {
  if [[ "$1" == "timemachine" ]]; then
    SECTION_TYPE="timemachine"
#    FOUND_PATH="no";       FOUND_PATH_VALUE=""
    FOUND_SIZE_LIMIT="no"; FOUND_SIZE_LIMIT_VALUE=""
    FOUND_USER="no";       FOUND_USER_VALUE=""; FOUND_PASSWORD_VALUE=""
  elif [[ "$1" == "avahi" ]]; then
    SECTION_TYPE="avahi"
                          FOUND_ENABLE_VALUE="no"
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
#      path)
#        FOUND_PATH="yes"; FOUND_PATH_VALUE="$VAL"
#        ;;
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
        find_password "$FOUND_USER_VALUE"
        FOUND_PASSWORD_VALUE="$FOUND_PASSWORD"
        ;;
      *)
        echo "unknown key TIMEMACHINE section[$SEC] key [$KEY] value [$VAL]"
        exit -1
        ;;
    esac
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
        echo "unknown key GLOBAL section[$SEC] key [$KEY] value [$VAL]"
        exit -1
        ;;
    esac
  elif [[ "$SECTION_TYPE" == "avahi" ]]; then
    case "$KEY" in
      enable)
        if ! [[ "$VAL" =~ ^(yes|no)$ ]]; then
          echo "parse: section [$SEC] $KEY = $VAL -- invalid value, use only yes|no."
          exit -1
        fi
        FOUND_ENABLE_VALUE="$VAL"
        ;;
      *)
        echo "unknown key AVAHI section[$SEC] key [$KEY] value [$VAL]"
        exit -1
        ;;
    esac
  else # samba share section
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
        echo "unknown key SAMBA SHARE section [$SEC] [$KEY] value [$VAL]"
        exit -1
        ;;
    esac
  fi
#  echo "parse: section [$SEC] : $KEY = $VAL"
}

function gen_random_user() {
  RANDOM_USER="u"
  for randomlength in {1..12}; do
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
function generate_text_and_variables () {

  SEC="$1"
  if [[ "$SECTION_TYPE" == "timemachine" ]]; then
    SECTION_TEXT=$'\n'"[Time Machine]"$'\n'
  elif [[ "$SECTION_TYPE" == "global" ]]; then
    SECTION_TEXT="[global]"$'\n'
  else
    SECTION_TEXT=$'\n'"[""$SEC""]"$'\n'
  fi

  if [[ "$SECTION_TYPE" == "timemachine" ]]; then
#    # handle path
#    if [[ "$FOUND_PATH" == "yes" ]]; then
#      SECTION_TEXT="$SECTION_TEXT""  path = ""$FOUND_PATH_VALUE"$'\n'
#    else
#      echo "path for section $SECTION_NAME not found"
#      exit -1
#    fi
    # add time machine path
    SECTION_TEXT="$SECTION_TEXT""  path = /timemachine_data"$'\n'
    # add time machine = yes
    SECTION_TEXT="$SECTION_TEXT""  time machine = yes"$'\n'
    # handle vol size limit
    if [[ "$FOUND_SIZE_LIMIT" == "yes" ]]; then
       SECTION_TEXT="$SECTION_TEXT""  vol size limit = ""$FOUND_SIZE_LIMIT_VALUE"$'\n'
       TIMEMACHINE_SIZE_LIMIT="$FOUND_SIZE_LIMIT_VALUE"
    else
       unset TIMEMACHINE_SIZE_LIMIT
    fi
    # handle user
    if [[ "$FOUND_USER" != "yes" ]]; then
      echo "user for section $SECTION_NAME not found"
      exit -1
    fi
    SECTION_TEXT="$SECTION_TEXT"";  user = ""$FOUND_USER_VALUE"$'\n'
    SECTION_TEXT="$SECTION_TEXT"";  password = ""$FOUND_PASSWORD_VALUE"$'\n'
    AFP_USER="$FOUND_USER_VALUE"
    AFP_PASSWORD="$FOUND_PASSWORD_VALUE"
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
  elif [[ "$SECTION_TYPE" == "avahi" ]]; then
    if [[ "$FOUND_ENABLE_VALUE" == "yes" ]]; then
      SECTION_TEXT="$SECTION_TEXT""  enable = ""$FOUND_ENABLE_VALUE"$'\n'
      AVAHI=1
    else
      AVAHI=0
    fi
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
