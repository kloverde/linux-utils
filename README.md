# add-favorite.sh

This is a script for Gnome users that can 'favorite', or pin, an application if you don't see the option to do so when right-clicking the application's taskbar button, or if you just need to create a custom shortcut for something.  This script helps automate the process.

You'll need to create a .desktop launcher and then provide it as a command-line argument to the script; the script will take care of the rest.  If you don't already have a .desktop launcher, you can use `create-launcher.sh` instead of this script.  `Create-launcher.sh` will help you create a launcher and, if invoked with `--install`, will then call `add-favorite.sh` for you.

`Add-favorite.sh` has two modes of adding a favorite:  either "installing" or not installing the launcher.  Installing a launcher (by using the optional --install flag) will move the specified launcher to ~/.local/share/applications.  This option is intended to be used with launchers you create yourself and would therefore want to restore from a backup if the need should arise (presumably your /home is backed up).  It will then offer to create a symlink to it in /usr/share/applications if you want to share it with other accounts.


# create-launcher.sh

This script makes it easy to create a Gnome .desktop launcher by simply answering prompts.

If invoked with the `--install` flag, it invokes `add-favorite.sh --install`.

If invoked without `--install`, `add-favorite.sh` is not called.  In other words, this has the effect of just adding a shortcut to the Gnome menu.


# require

A helper script to check for script dependencies


# rotate-wallpaper.sh

This is a script for Gnome users that changes the desktop background on a schedule.  The directory, file types and rotation interval are provided as command-line arguments.  I wouldn't be surprised if plenty of distros have this functionality out of the box, but if yours doesn't, this does the job -- just call it from your .profile.

Since the script doesn't terminate, you have to be sure to run it in the background when calling it from your .profile, otherwise you won't be able to get to your desktop.

To run a command in the background, you include an ampersand as the last part of the command.  A complete example would look something like:

```shell
rotate-wallpaper.sh --directory ~/Pictures --file-types "*.png *.jpg" --interval 15 &
```


# turn-off-screen.sh

Turns off the monitor without putting the machine into suspend mode


# update-thunderbird.sh

Upgrades Thunderbird to the latest version.  This is useful if you don't manage Thunderbird via a package manager.


# yesno

A helper script to display a configurable yes/no prompt
