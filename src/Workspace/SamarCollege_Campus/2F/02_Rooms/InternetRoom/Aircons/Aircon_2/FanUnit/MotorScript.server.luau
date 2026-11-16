Switch = script.Parent.Parent.PowerSwitch.IsOn
Motor = script.Parent.Motor
Process = script.Parent.Parent.Refrigeration.Condensation.Waterdrops

function Active()
	if Switch.Value == true then
		Motor.Fan:Play()
		Motor.Hum:Play()
		Motor.Startup:Play()
		Motor.Fan.PlaybackSpeed = 0
		
			while true do
			Motor.BottomParamB = Motor.BottomParamB + 0.018
			Motor.Fan.PlaybackSpeed =  Motor.BottomParamB
			wait()
			if  Motor.BottomParamB >= 1.1 then 
			wait(20)
			Process.Enabled = true
			break end
			if Switch.Value == false then break end			
			end		

	elseif Switch.Value == false then
			Motor.Hum:Stop()
			while true do
			script.Parent.Motor.BottomParamB = Motor.BottomParamB - 0.004
			Motor.Fan.PlaybackSpeed =  Motor.BottomParamB
			wait()
			if Switch.Value == true then break end
			if Motor.BottomParamB <= 0 then break end
			end
			Motor.BottomParamB = 0
			wait(20)
			Process.Enabled = false
	end
	end
Switch.Changed:connect(Active)