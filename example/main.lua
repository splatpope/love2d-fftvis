print(love.filesystem.getRequirePath())
require "imgui"
fftvis = require("fftvis")
UpdateSpectrum = false --oops lets not draw shit that dont exist yo

function love.load(arg)
	gfx = love.graphics
	Window = love.window.setMode(1024, 500, {resizable=true, vsync=true})
	ScreenSizeW = gfx.getWidth() --gets screen dimensions.
	ScreenSizeH = gfx.getHeight() --gets screen dimensions.
	
	fftvis:load("trompettes.mp3")
	print("fftvis has been loaded")

	col = {}
	col.white = {1, 1, 1}
	col.black = {0, 0, 0}	

	tribby = gfx.newImage("tribby.jpg")

	gui = {}
	local process = function (s) 
			if s then
				fftvis.conf:update(s) 
				gui.bins = math.log(fftvis.conf.fftBinNum)/math.log(2)
				gui.bars = math.log(fftvis.conf.barNum)/math.log(2)
				gui.range = math.log(fftvis.conf.displayRange)/math.log(2)
			end
	end
	process(true)
	gui.draw = function (self) 
		gfx.setColor(col.white)
		
		if imgui.BeginMainMenuBar() then
			if imgui.BeginMenu("File") then
				imgui.MenuItem("Test")
				imgui.EndMenu()
			end
			if imgui.BeginMenu("Options") then
				if imgui.BeginMenu("FFT Configuration") then
					gui.bins, s = imgui.InputInt("FFT Bin Amount (octaves)", gui.bins, 1)
					if s then fftvis.conf:setfftBinNum(math.pow(2, gui.bins)) end
					process(s)
	
					gui.range, s = imgui.InputInt("Fraction to display (octaves) ", gui.range, 1)
					if s then fftvis.conf:setDisplayRange(math.pow(2, gui.range)) end
					process(s)


					gui.bars, s = imgui.InputInt("Amount of bars to display (octaves)", gui.bars, 1)
					if s then fftvis.conf:setBarNum(math.pow(2, gui.bars)) end
					process(s)

					imgui.EndMenu()
				end
				imgui.EndMenu()
			end
			imgui.EndMainMenuBar()
		end
		imgui.Render()
		
	end

	time = 0

	--REGARDEZ COMME IL ONDULE
	--IL A TOUT DU SERPENT
	--MERDE
	--Ce haiku est sponsorisé par la communauté des shaders inutiles
	bgShader = gfx.newShader[[
	#define PI 3.1415926538
	uniform float delta;
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
	

		vec4 pixel = Texel(texture, texture_coords);
		pixel.r = 20/255.0;
		pixel.g = texture_coords.x;
		pixel.b = 130/255.0 + 0.3*sin(delta*PI/8);
	
		return pixel;
	}
	]]
	beatShader = gfx.newShader[[
	#define PI 3.1415926538
	uniform float delta;
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
	

		vec4 pixel = Texel(texture, texture_coords);
		pixel.r = 200/255.0;
		pixel.g = 1 - abs((10/255.0)*sin(delta*PI*2));
		pixel.b = 0;
	
		return pixel;
	}
	]]
	

	gfx.setBackgroundColor(200/255,200/255,200/255)

	seekOffset = fftvis.player.seekOffset
	
end


function love.update(dt)
	time = time + dt

	fftvis:update(dt)
	imgui.NewFrame()
	UpdateSpectrum = true --Tells the draw function it already has data to draw
end

function love.draw()

	local spectrum = fftvis.fft.sFitSpectrum --We used the smoothed spectrum because it's ~nice~
	local tell = fftvis.player:tellTime()
	local musicSize = fftvis.player.musicSize
	local barWidth = fftvis.conf.barWidth
	
	

	gfx.setShader(bgShader)
		bgShader:send("delta",time)
		love.graphics.setColor(75/255,0,130/255)
		love.graphics.rectangle("fill", 0,0,ScreenSizeW, ScreenSizeH)
		love.graphics.setColor(col.white)
	gfx.setShader()
	--BG image (cover art)
	gfx.draw(tribby, ScreenSizeW/2, ScreenSizeH/2, 0, 1.5,1.5, tribby:getWidth()/2, tribby:getHeight()/2)
	gfx.setColor(10/255,10/255,10/255)

	--Letterboxing
--	love.graphics.rectangle("fill", 0, 0, ScreenSizeW, (ScreenSizeH - tribby:getHeight())/(2*1.5))
--	love.graphics.rectangle("fill", 0, (ScreenSizeH-(ScreenSizeH - tribby:getHeight())/(2*1.5)), ScreenSizeW, (ScreenSizeH - tribby:getHeight())/(2*1.5))
  
--Draw screenspace frequency bins

		
  if UpdateSpectrum then	
		--Draw the visualizations
		--This is arbitrary.
		gfx.setShader(beatShader)
			beatShader:send("delta",time)
			gfx.setColor(200/255,100/255,0)
			--Circle mapped to the mean of the first quarter of frequency bins, with a coefficient (i.e. bass)
			gfx.circle("line", ScreenSizeW/2, ScreenSizeH/2, -(stats.mean({unpack(spectrum, 1, math.floor(#spectrum/4))})*5 ), 16)
			--Triangle mapped to the highest bin, with a quite higher coefficient (i.e. treble)			
			gfx.circle("line", (ScreenSizeW/2 - 1.5*tribby:getWidth()/2)/2, ScreenSizeH/2, -spectrum[#spectrum]*30, 3 )
			--Square mapped to the midle bin, whatever that possibly means
			gfx.circle("line", ScreenSizeW - (ScreenSizeW/2 - 1.5*tribby:getWidth()/2)/2, ScreenSizeH/2, -spectrum[#spectrum/2]*15, 4 )
			gfx.setColor(col.white)
		gfx.setShader()
	
    for i = 1, #spectrum do	
		local barHeight = -5-spectrum[i]*2
		
		--Actually draw the bins
		gfx.setColor(-barHeight/ScreenSizeH * 2, 1 + 2 *barHeight/ScreenSizeH,10/255)
		gfx.rectangle("fill", (i-1)*barWidth+1, ScreenSizeH+5, barWidth-1, -5-spectrum[i]*2, 5, -5) --iterate over the list, and draws a rectangle for each band value.
		gfx.setColor(col.white)
		
    end
    
  end
 	gfx.setColor(50/255, 50/255, 50/255)
	gfx.rectangle("fill", ScreenSizeH, 0, 20, 0)

	local ssw = ScreenSizeW
	local tgw = tribby:getWidth()
	gfx.setColor(0.1, 0.8, 0.1)
	gfx.rectangle("fill", ssw/2 - tgw/2, 5, tribby:getWidth()*tell/musicSize, 20)	
	gfx.setColor(col.white)
	gfx.rectangle("line", ssw/2 - tgw/2, 5, tribby:getWidth(), 20)
	gfx.print(math.ceil(10000 * tell/musicSize) / 100 .. "%", ScreenSizeW / 2- 15, 10)
	--Display little arrows showing seeking direction
	if fftvis.player.seekDirection < 0 then 
		gfx.push()
			gfx.setColor(0.9, 0.9, 0.9)
			gfx.translate(ssw/2 - tgw/2 - 20, 15)
			gfx.rotate(math.pi)
			gfx.circle("fill", 0, 0, 10, 3) 
		gfx.pop()
	elseif fftvis.player.seekDirection > 0 then 
		gfx.circle("fill", ssw/2 + tgw/2 + 20, 15, 10, 3) 
	end

	gfx.print("Current Sample : "..tell, 25, 10) 
	gfx.print("Total Size : "..musicSize, 25, 40)
	gfx.print("Time Elapsed : "..math.ceil(time).." s", 25, 70)
	gfx.print("FPS : "..math.ceil(1/love.timer.getDelta()), 175, 70)
	
	--TODO : offload this to fftvis, implement maximum value calculations in preprocessing (spectrum related values)
	local energy = stats.mean(spectrum, 2, #spectrum/2)
	local maxEnergy = 500
	local dispEnergy = energy/maxEnergy
	gfx.print("Energy : "..energy, 25, 90)
	gfx.setColor(dispEnergy, 1 - dispEnergy, 0.1)
	gfx.rectangle("fill", 25, 110, 100 * dispEnergy, 10)

	gui:draw()
	
end

function love.quit()
    imgui.ShutDown();
end

function love.textinput(t)
    imgui.TextInput(t)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.keypressed(btn)
	imgui.KeyPressed(btn)
	if not imgui.GetWantCaptureKeyboard() then
	-- Pass event to the game
	end
end

function love.keyreleased(key)
    imgui.KeyReleased(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.mousemoved(x, y)
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousepressed(x, y, button)
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousereleased(x, y, button)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.wheelmoved(x, y)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

stats={}

-- Get the mean value of a table
function stats.mean( t, pow, stop )
  local pow = pow or 1
  local stop = stop or #t
  local sum = 0
  local count= 0

  for k,v in pairs(t) do
    if type(v) == 'number' then
      sum = sum + math.pow(v, pow)
      count = count + 1
    end
    if k == stop then break end
  end

  return (sum / count)
end

function math.clamp(low, n, high) return math.min(math.max(n, low), high) end
