# emoji-patch
A couple scripts to export and then import the contents of a Plex DB.

These scripts are adapted from another called `pumpanddump,sh` that exported and rebuilt the DB in one go.  I split it in two and did a little refactoring.

That script was written by the guys at [REDACTED].

## What is this for?

Recent version of Plex have problems with labels containing emoji.  Such labels can be *set*, but _cannot be removed_ either via the API [including the Plex UI] or a script.

A lot of Kometa users run into this since the default seasonal collections include emoji in their names:

```
🎊 New Year's Day Movies
💘 Valentine's Day Movies
☘ St. Patrick's Day Movies
🐰 Easter Movies
🤱 Mother's Day Movies
🪖 Memorial Day Movies
👨 Father's Day Movies
🎆 Independence Day Movies
⚒ Labor Day Movies
🎃 Halloween Movies
🎖 Veteran's Day Movies
🦃 Thanksgiving Movies
🎅 Christmas Movies
🌊🌺 Asian American Pacific Islander Movies
♿ Disability Month Movies
✊ 🏿 Black History Month Movies
🏳️‍🌈 LGBTQ Month Movies
🪅 National Hispanic Heritage Movies
🚺 Women's History Month Movies
```

The result is that once a movie goes into one of these seasonal collections it can't be removed.

The fix going forward is to set a template variable removing the emoji from the collection names:
```yaml
libraries:
  Movies:
    collection_files:
      - default: seasonal
        template_variables:
          emoji: ""
```

But that doesn't address the existing collections.

That's what these two scripts are for.  The first exports the database content into a text file, which the user can then edit to remove the emoji, then the second script rebuilds the database.

## How do I use it?

### Assumptions:

1. Plex is running in docker
2. You can run a bash script

### part one:

Run the first script:
```
./01-dump-db.sh kometa-plex
OK, you have jq installed. We will use that.
perms on db are seed:seed
/opt//kometa-plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases
kometa-plex
stopping kometa-plex
kometa-plex
copying plex app
Successfully copied 216MB to /opt/plexsql
backing up current database: /opt//kometa-plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db
duplicating current database: /opt//kometa-plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db
removing current database: /opt//kometa-plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db
removing pointless items from database
dumping and removing old database
dump.sql is now ready for you to edit; make any required changes then run 02-build-db.sh
total 2383156
drwxr-xr-x 35 seed seed      4096 Nov 25 19:31 .
drwxr-xr-x  3 root root        18 Aug 12 22:02 ..
-rwxr-xr-x  1 seed seed      2360 Nov 25 19:30 01-dump-db.sh
-rwxr-xr-x  1 seed seed      1714 Nov 25 19:14 02-build-db.sh
-rw-r--r--  1 seed seed 593920000 Nov 25 19:30 com.plexapp.plugins.library.db
-rw-rw-r--  1 seed seed 639652079 Nov 25 19:31 dump.sql
```

### part two:

Open the file in a text editor and remove the emoji from the collection labels.  For example, you would change this sort of thing:
```
INSERT INTO tags VALUES(367936,NULL,'🎅 Christmas Movies',11,'','','',NULL,NULL,NULL,NULL,'',NULL);
```
to:
```
INSERT INTO tags VALUES(367936,NULL,'EMOJI Christmas Movies',11,'','','',NULL,NULL,NULL,NULL,'',NULL);
```
Save the file.

### part three:

Run the second script:
```
./02-build-db.sh kometa-plex
OK, you have jq installed. We will use that.
perms on db are seed:seed
/opt//kometa-plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases
kometa-plex
making adustments to new db
importing old data
optimize database and fix times
reown to seed:seed
start applications
kometa-plex
```
Now the labels in Plex will have no emoji and you can remove them in the UI:

![image](https://github.com/user-attachments/assets/6baab557-34bf-4509-adf6-e8edb0ba9142)
