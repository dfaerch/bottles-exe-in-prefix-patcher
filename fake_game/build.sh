#!/bin/bash

# requires mingw32. On ubuntu:
# sudo apt install gcc-mingw-w64-x86-64

x86_64-w64-mingw32-gcc -mwindows -o fake_game.exe fake_game.c
