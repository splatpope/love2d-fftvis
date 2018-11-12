luafft = require("LuaFFT/src/luafft")
abs = math.abs 
newC = complex.new 

local debugging = false

local function msg(...)
	if debugging == true then
		print(...)
	end
	return ...
end


fftvis = {}
function fftvis.load(self, song)
	assert(song)
	
	
	
	self.player = {}

	player = self.player
	player.setSong = function (self, name) self.song = name; self.soundData = love.sound.newSoundData(self.song) end
	player:setSong(song)

	player.music = love.audio.newSource(player.soundData)
	player.musicSize = player.soundData:getSampleCount() --Per channel !!
	player.tellTime = function (self) return self.music:tell("samples") end
	player.channelCount = player.music:getChannelCount()
	player.sampleRate = player.soundData:getSampleRate()

	player.setMono = true
	player.samples = self:loadSamples(player.soundData)
	msg("diff : "..#player.samples-player.musicSize)

	self.conf = {}
	local conf = self.conf

	conf.fftBinNum = 1024
	conf.setfftBinNum = function (self, size) self.fftBinNum = size
			self:initfftbinWidth() 
		end
	conf.initfftBinWidth = function (self) self.fftBinWidth = self.fftBinNum / self.sampleRate end

	conf.setDisplayRange = function (self, fraction) self.displayRange = self.fftBinNum*fraction end
	conf:setDisplayRange(1/8)
	conf.setBarNum = function (self, num) if num > self.displayRange then num = self.displayRange end self.barNum = num 
			self:initBarWidth()
			self:initBarStep()
		end
	conf.initBarWidth = function (self) self.barWidth = love.graphics.getWidth() / self.barNum end
	conf.initBarStep = function (self) self.barStep =  love.graphics.getWidth() / self.displayRange end
	conf:setBarNum(64) --Some values may average badly
	
	conf.smoothNum = 1
	conf.smoothCoeff = 0.8 --Fiddle with this at your heart's content
	
	self.fft = {[false] = 0}
	local fft = self.fft
	
	fft.maxSpecVal = 0 --Unused for now, will eventually help for normalization
	fft.minSpecVal = 0


	fft.filter = true

	fft.spectrum = {} --Raw spectrum as calculated by the fft
	fft.fitSpectrum = {} --Averaged and fit to the display range
	fft.sFitSpectrum = {} --Smoothed spectrum for fluid display
	fft.smoothBuffer = {}
	
	player.music:play()
end

function fftvis.loadSamples(self)
	local samples = {}
	local snd = self.player.soundData
	local musicSize = self.player.musicSize
	local channelCount = self.player.channelCount
	
	for i=1, musicSize - 1 do
		local curSample = 0
		for j=1, channelCount do
			curSample = curSample + snd:getSample(i, j)
		end
		samples[#samples + 1] = curSample
	end
	return samples
end

function fftvis.process(self, time)
	local musicSize = self.player.musicSize
	local musicPos = time or self.player:tellTime()
	local fftSize = self.conf.fftBinNum
	local samples = self.player.samples
	
	local getfft = luafft.fft
	local sampleBuffer = {}

	for i = musicPos, musicPos + fftSize - 1 do
	  	sampleBuffer[#sampleBuffer + 1] = newC(samples[i], 0) 
	end
	
	return getfft(sampleBuffer, false)
	
end

function fftvis.fitToDisplay(self)
	local spectrum = self.fft.spectrum
	local avgSpectrum = {}
	local barNum = self.conf.barNum
	local displayRange = self.conf.displayRange

	for i = 1, displayRange, displayRange/barNum do 
		local curSpecVal = 0
		for j = 1, displayRange/barNum do
			curSpecVal = curSpecVal + spectrum[i+j-1]:abs() 
		end
		avgSpectrum[#avgSpectrum + 1] = curSpecVal
	end 
	return avgSpectrum
end 

function fftvis.smoothFitSpectrum(self)
	local fit = self.fft.fitSpectrum
	local sFit = {}
	local smoothBuffer = self.fft.smoothBuffer
	local smoothCoeff = self.conf.smoothCoeff
	for i = 1, #fit do
		if smoothBuffer[i] == nil then smoothBuffer[i] = 0 end
		smoothBuffer[i] = smoothCoeff * smoothBuffer[i] + ((1-smoothCoeff) * fit[i])
	end
	self.smoothBuffer = smoothBuffer
	return smoothBuffer
	
end

function fftvis.normalize(self, spectrum, displayBound, clampBound)
	local maxSpecVal = displayBound - clampBound
	local rs = {}
	for i = 1, #spectrum do
		rs[i] = (displayBound - clampBound) * (spectrum[i] / maxSpecVal)
	end
	return rs
end

function fftvis.update(self)
	local musicPos = self.player:tellTime()
	local musicSize = self.player.musicSize
	local fftSize = self.conf.fftBinNum
	local music = self.player.music


	if musicPos >= musicSize - fftSize + 1 then music:seek(1, "samples") end

	self.fft.spectrum = self:process()
	self.fft.fitSpectrum = self:fitToDisplay()
	for i=1, self.conf.smoothNum do
		self.fft.sFitSpectrum = self:smoothFitSpectrum()
	end
end

return fftvis
