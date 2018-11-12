# love2d-fftvis
![Screenshot](https://i.imgur.com/pwZVgb3.png)
FFTVis a simple music player with a built in FFT calculator, designed to be used in music visualization.

It comes as a module exposing all the relevant fft options as well as some spectrum related attributes and functions.

# Dependencies
You'll need to install the following dependencies:
* love2d >= 11.0 ([love2d.org](https://love2d.org))
* luafft >= 1.2 (luarocks or [on github](https://github.com/h4rm/luafft))

# Setup
* Install love2D
* Install or clone luafft (make sure its folder is inside this one). fftvis will look for luafft at LuaFFT/src/luafft.lua
* Call require("fftvis") on your love2D main.lua file

# Usage
* Call fftvis:load() with the song's full filename as its argument. fftvis will not work if not loaded with a valid song name.
* Call fftvis:update() inside love:update, using any kind of flag if you intend on using fft results inside love:draw.
* Use the calculated spectrums to your heart's content

The screenshot shows a little example showcasing the abilities of fftvis.
Run it by running löve on the file example/main.lua

Based on previous work by Sulunia.

Music made by myself using LMMS.
Visuals for the cover art inspired by a sticker made by CamiSArt.
