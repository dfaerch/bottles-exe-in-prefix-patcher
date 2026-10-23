# Bottles Runtime Patch

A runtime patch for [Bottles](https://usebottles.com/) that allows adding Windows executables located outside their Proton prefixes.

Bottles GUI only allows you to select exe files inside wine-prefixes. So if you usually keep your games in a local dir, eg. `~/Games/mygames/`, you have to copy or mount each game into the prefix. Umu or proton themselves do
have this restriction, so this patch just removes the check from the Bottles GUI.

This is __highly__ experimental and untested software, so *caution is adviced*. I make no guarantees that this wont break anything. So far i havent even found an official reason for Bottles to have this restriction and thus,
i cant say for sure if disabling it causes problems. I suspect the restiction is to make the "dedicated sandbox" filesystem management simpler, so bypassing it like this, might make those sandboxes less secure. But thats just guesswork for now.

- This is for the Bottles **Flatpak** version only.
- The patch is done runtime and should survive future updates of Bottles.
- A small python file gets copied into the flatpak container and is loaded at Bottles start-up.
- No files from the original installation, installed games or data (eg saves) is modified.

## Installation

Requires Bottles installed through Flatpak.

You must give the Bottles flatpak access to your games directory. If you use eg. `~/Games/mygames` you can add read-only access to that dir like so:
```bash
TODO: add flatpak command
```

If you for some reason need write access also, remove ":ro" from dirname.

Then install the runtime patcher.


```bash
./install.sh
```

## Uninstallation

```bash
./uninstall.sh
```

## Notes


The patch currently expects five path-containment checks. If Bottles changes its implementation, the patch will fail rather than silently applying to an unexpected number of checks.

This is an unofficial patch and is not affiliated with the Bottles project.
