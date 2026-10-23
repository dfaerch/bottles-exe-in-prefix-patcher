# Bottles Runtime Patch

A runtime patch for [Bottles](https://usebottles.com/) that allows adding Windows executables located outside their Wine prefixes.

The Bottles GUI only allows you to select exe files inside Wine prefixes. So if you usually keep your games in a local dir, e.g. `~/Games/mygames/`, you have to copy or mount each game into the prefix. Umu or Proton themselves do not
have this restriction, so this patch just removes the check from the Bottles GUI.

This is __highly__ experimental and untested software, so *caution is advised*. I make no guarantees that this won't break anything. So far I haven't even found an official reason for Bottles to have this restriction and thus,
I can't say for sure if disabling it causes problems. I suspect the restriction is to make the "dedicated sandbox" filesystem management simpler, so bypassing it like this might make those sandboxes less secure. But that's just guesswork for now.

- This is for the Bottles **Flatpak** version only.
- The patch is applied only at runtime, without patching files on disk. It remains installed across Bottles updates, but compatibility with future versions isn't guaranteed.
- A small Python file is installed in Bottles' application data directory and loaded at startup.
- No files from the original installation, installed games or data (e.g. saves) are modified.

## Installation

Requires Bottles installed through Flatpak.

### Dir permissions

You must give the Bottles Flatpak access to your games directory. If you use, e.g., `~/Games/mygames`, you can add read-only access to that dir like so:

```bash
flatpak override --user --filesystem="$HOME/Games/mygames:ro" com.usebottles.bottles
```

If you also need write access, remove `:ro` from the end of the path in the command.

If you want a GUI for changing this permission instead, Flatseal is nice and simple.

### Installing patcher


```bash
./install.sh
```

Restart Bottles to activate the patch.

## Uninstallation

```bash
./uninstall.sh
```

## Notes


The patch currently expects five checks that restrict executables to the prefix. If Bottles changes its implementation, the patch will fail rather than silently applying to an unexpected number of checks.

This is an unofficial patch and is not affiliated with the Bottles project.

There's a "fake_game" dir in this repo. It contains source code for a small Windows executable that just pops up a dialog with its path. It simply allows developers to test Bottles without having any Windows games on the machine.
