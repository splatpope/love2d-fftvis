# love2d-fftvis
![Screenshot](https://imgur.com/a/MCsid7m)
FFTVis a simple music player with a built in FFT calculator, designed to be used in music visualization.

It comes as a module exposing all the relevant fft options as well as some spectrum related attributes and functions.

##Dependencies
You'll need to install the following dependencies:
- love2d >=11.0 (love2d.org)
- luafft >= 1.2 (luarocks or https://github.com/h4rm/luafft)

##Setup
- Install love2D
- Install or clone luafft (make sure its folder is inside this one)
- Require fftvis on your love2D main.lua file

##Usage
- Call fftvis:load("FULLSONGFILENAME")
- Call fftvis:update() inside love:update, using a flag if you intend on using fft results to draw
- Use the calculated spectrums to your heart's content

The screenshot shows a little example showcasing the abilities of fftvis.

Run it by running love on the file example/main.lua

Based on previous work by Sulunia.

Music and visuals made by myself using LMMS.

