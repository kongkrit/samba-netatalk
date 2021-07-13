# config to smb.conf

- X = whatever value, **rlist** = read user list, **wlist** = write user list
- **guest_access** or **guest access** possible values = no | ro (readonly) | rw (read-write)
- RANDOMVAL = some random username just added to make **valid users** list not empty
- samba's default values are **in bold**
  - **guest ok** = **no** | yes
  - **read only** = **yes** | no
  - **browsable** = **yes** | no
  - **valid users** = _empty list means everyone_

| case | guest access | ro_users (read list) | wr_users (write list) | guest ok | read only | read list | write list | valid users   | force directory mode | force create mode |
| :--: | :----------: | :-------: | :--------: | :------: | :-------: | :-------: | :--------: | :-----------: | :---------------------: | :---------------: |
| 1    |     rw       |     X     |     X      |  yes     |    no     |    -      |      -     |      -        | 2777 | 0666 |
| 2    |     ro       |     X     |     -      |  yes     |    yes    |    -      |      -     |      -        | 2775 | 0664 |
| 3    |     ro       |     X     |   wlist    |  yes     |    yes    |    -      |  wlist     |      -        | 2775 | 0664 |
| 4    |     no       |   rlist   |     -      |  no      |    yes    | rlist     |      -     |      rlist    | 2770 | 0660 |
| 5    |     no       |   rlist   |   wlist    |  no      |    yes    | rlist     |  wlist     | rlist + wlist | 2770 | 0660 |
| 6    |     no       |     -     |     -      |  no      |    yes    |    -      |      -     |   RANDOMVAL   | 2770 | 0660 |
| 7    |     no       |     -     |   wlist    |  no      |    yes    |    -      |  wlist     | wlist         | 2770 | 0660 |

- passthrough parameters:
  - comment
  - browsable | browseable
