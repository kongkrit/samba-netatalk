#!/bin/bash

# pass filename as $1 and section_name as $2
function get_user_list () {

# 1. change \r\n to \n
# 2. get rid of comments (lines that start with either # of ; )
# 3. get rid of everything before and including [section_name]
# 4. get rid of everything after and including the next [
# 5. get rid of empty lines

#    cat $1 | \
           sed -E 's/\r$//g' "$1" | \
           sed -E 's/^\s*[#;].*$//g' | \
           sed -nE '/\s*\['"$2"'\]/,$p' | sed -E '/\s*\['"$2"'\]/d' | \
           sed -n '/\s*\[/q;p' | \
           sed -E '/^\s*$/d'
}

# pass username and return password for that user
function find_password() {
  # trick from https://stackoverflow.com/questions/19771965/split-bash-string-by-newline-characters
  readarray -t USER_PASS_ARRAY <<< "$SAMBA_USER_PASSWORD"
  for upass in "${USER_PASS_ARRAY[@]}"; do
     readarray -d " " -t USER_PASS <<< "$upass"
     MATCH_FOUND="no"
     POINTING="user"
     for up in "${USER_PASS[@]}"; do
       up2=$(echo "$up" | tr -d '\n')
       [[ "$POINTING" == "user" && "$up2" == "$1" ]] && MATCH_FOUND="yes"
       if [[ "$POINTING" == "pass" && "$MATCH_FOUND" == "yes" ]]; then
         FOUND_PASSWORD="$up2"
         break
       fi
       POINTING="pass"
     done
     if [[ "$MATCH_FOUND" == "yes" ]]; then
       break
     fi
  done

  if [[ "$MATCH_FOUND" != "yes" ]]; then
    echo "find_password: user $1 not found"
    exit -1
  fi
  echo "found password of user $1 as $FOUND_PASSWORD"
}

# pass filename as $1 and section to ignore as $2
function read_section_list() {

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
    groupadd sambausers

    USER_LIST=" "

    i=1
    while [ "$i" -le "$#" ]; do
        u=${!i}
        USER_LIST="$USER_LIST""$u"" "
        i=$((i+1))
        p=${!i}
        i=$((i+1))
        echo "==== username [$u] password [$p]"
        echo " useradd -M -s /usr/sbin/nologin $u"
        useradd -M -s /usr/sbin/nologin $u
        echo " echo \"$u:$p\" | chpasswd"
        echo "$u:$p" | chpasswd
        echo " changing user [$u] userid to $PUID and usergroup to $PGID..."
        SEDEX="s/${u}:x:[0-9]+:[0-9]+:/${u}:x:${PUID}:${PGID}:/g"
        echo " SEDEX is $SEDEX"
        cat /etc/passwd | sed -E $SEDEX > /tmp/passy
        cp /tmp/passy /etc/passwd && rm /tmp/passy
        echo " (echo \"$p\"; echo \"$p\") | smbpasswd -s -a $u"
        (echo "$p"; echo "$p") | smbpasswd -s -a $u
        echo " smbpasswd -e $u"
        smbpasswd -e $u
        echo " usermod -aG sambausers $u"
        usermod -aG sambausers $u
    done
    echo "**** done add_samba_users ****"
}

# add functions:
#   parser_init, parse, gen_random_user,
#   union_users, generate_text_and variables

## . $(dirname "$0")/scripts/parser.sh
. parser.sh

if [ "$#" -eq "1" ] && [ -f "$1" ]; then
  echo "starting script. processing [""$1""]..."
else
  echo "missing filename"
  exit -1
fi

CONFIG_FILENAME="$1"

USER_SECTION="username-password-list"

SAMBA_USER_PASSWORD="$(get_user_list "$CONFIG_FILENAME" "$USER_SECTION")"
#echo "SAMBA_USER_PASSWORD = [$SAMBA_USER_PASSWORD]"

add_samba_users $SAMBA_USER_PASSWORD

echo "user list is [$USER_LIST]"

gen_random_user

SECTION_TEXT=""

#echo "---- share_list ----"
IFS=";" read -ra SECTION_LIST <<< "$(read_section_list "$CONFIG_FILENAME" "$USER_SECTION")"

ALL_SMB_GLOBAL_TEXT=""
ALL_SMB_SHARE_TEXT=""
ALL_AFPD_TEXT=""
ALL_AVAHI_TEXT=""
for i in "${SECTION_LIST[@]}"; do
    SECTION_NAME="$i"
    parser_init "$SECTION_NAME"
    IFS=";" read -ra SECTION_LIST <<< "$(read_section "$1" "$i")"
    for j in "${SECTION_LIST[@]}"; do
      KEY="$(echo "$j" | cut -d'=' -f1 | sed -E 's/^[ \t]*//;s/[ \t]*$//' )"
      VAL="$(echo "$j" | cut -d'=' -f2 | sed -E 's/^[ \t]*//;s/[ \t]*$//' )"
      parse "$SECTION_NAME" "$KEY" "$VAL"
    done
    generate_text_and_variables "$SECTION_NAME"
    if [[ "$SECTION_TYPE" == "timemachine" ]]; then
      ALL_AFPD_TEXT="$ALL_AFPD_TEXT""$SECTION_TEXT"
    elif [[ "$SECTION_TYPE" == "global" ]]; then
      ALL_SMB_GLOBAL_TEXT="$ALL_SMB_GLOBAL_TEXT""$SECTION_TEXT"
    elif [[ "$SECTION_TYPE" == "avahi" ]]; then
      ALL_AVAHI_TEXT="$ALL_AVAHI_TEXT""$SECTION_TEXT"
    else
      ALL_SMB_SHARE_TEXT="$ALL_SMB_SHARE_TEXT""$SECTION_TEXT"
   fi
#    echo "---- SECTION: $SECTION_NAME TIME MACHINE: $SECTION_TYPE ----"
#    echo "$SECTION_TEXT""----"
done

echo "---- ALL_AVAHI ----"
echo "     AVAHI=""$AVAHI"
echo "---- ALL_AFPD ----"
echo "     PUID=$PUID"
echo "     PGID=$PGID"
echo "     AFP_USER=$AFP_USER"
echo "     AFP_PASSWORD=$AFP_PASSWORD"
echo "     TIMEMACHINE_SIZE_LIMIT=$TIMEMACHINE_SIZE_LIMIT"
cat afp-head.conf > afp.conf
echo "$ALL_AFPD_TEXT" >> afp.conf
echo "     ---- afp-out.conf ----"
cat afp.conf
#echo "$ALL_AFPD_TEXT"
echo "---- ALL_SAMBA_TEXT ----"
echo "$ALL_SMB_GLOBAL_TEXT" > smb.conf
cat smb-head.conf >> smb.conf
echo "$ALL_SMB_SHARE_TEXT" >> smb.conf
echo "     ---- smb-out.conf ----"
cat smb.conf
#echo "$ALL_SMB_GLOBAL_TEXT"
#echo "---- ALL_AVAHI_TEXT ----"
#echo "     AVAHI=""$AVAHI"
#echo "$ALL_AVAHI_TEXT"
#echo "---- ALL_SMB_SHARE_TEXT ----"
#echo "$ALL_SMB_SHARE_TEXT"
