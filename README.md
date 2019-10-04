# Password Keeper

A simple password locker that works from the command line. 

NOTE: This is not in particularly secure because if someone knows you're using this
tool, they can also know the encryption protocol being used and brute force is
feasible. 

The idea is simple, each user is represented by a file saved somewhere. That
file contains combinations of password descriptions and actual passwords...
but before anything gets saved or recalled from the file, it's always
encrypted. The non-encrypted version of the password and description is never
available outside of the lifetime of the ruby script, which is intentionally
built to only ever do one thing and then kill itself. Thus, any lasting
records are purely encrypted. 


So for example, we might have the user Mike. Mike would be represented by
a `.Mike.kpr` file. This file would contain all of Mike's passwords and what
they are used for in a format like this (if it weren't encrypted):

```
{"cars.com": "MikeIsARealCoolGuy", "PNC.com": "thisIs@S3curePassw0rd"}
```

In reality what gets saved is:

```
{"aq453=91g": "awndOA@awnDoanwda/dwao2310e1", "912h3ui123i1":
"/343:1231nkajbwadka"}
```

The ruby code simply interacts exclusively with these encrypted strings and
has several abilities:

* Create a user
* Add a password to that user
* Get a password based on a description
* Delete a password from the user
* Purge a user

All of these are locked by a master password (except user creation) and
purging. The purging needs to be updated to only work with the master
password, but that's for another time.

Usage looks like:

`ruby locker.rb USERNAME ACTION`

Each action will prompt you for the necessary bits to complete the action.
