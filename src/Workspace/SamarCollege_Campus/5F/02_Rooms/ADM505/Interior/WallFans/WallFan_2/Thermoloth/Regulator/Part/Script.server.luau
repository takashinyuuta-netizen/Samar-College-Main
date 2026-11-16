function onClicked()
if script.Parent.Parent.Value.Value == 3 then
script.Parent.Parent.Value.Value = 0
script.Parent.Parent.Knob.Switch3.Transparency = 1
script.Parent.Parent.Knob.Switch2.Transparency = 0
script.Parent.Parent.Shaft.Fanmotor.MotorMaxAcceleration = 5
script.Parent.Parent.Shaft.FanHummingSFX.Playing = false
wait(.002)
script.Parent.Parent.Knob.Switch2.Transparency = 1
script.Parent.Parent.Knob.Switch1.Transparency = 0
wait(.002)
script.Parent.Parent.Knob.Switch1.Transparency = 1
script.Parent.Parent.Shaft.Fanmotor.AngularVelocity = -0
script.Parent.Parent.Knob.Switch0.Transparency = 0
elseif script.Parent.Parent.Value.Value == 0 then
script.Parent.Parent.Value.Value = 1
script.Parent.Parent.Knob.Switch0.Transparency = 1
script.Parent.Parent.Knob.Switch1.Transparency = 0
script.Parent.Parent.Shaft.Fanmotor.AngularVelocity = -80
script.Parent.Parent.Shaft.FanHummingSFX.Playing = true
script.Parent.Parent.Shaft.FanHummingSFX.Volume = 4
script.Parent.Parent.Shaft.Fanmotor.MotorMaxAcceleration = 5
elseif script.Parent.Parent.Value.Value == 1 then
script.Parent.Parent.Value.Value = 2
script.Parent.Parent.Knob.Switch1.Transparency = 1
script.Parent.Parent.Shaft.Fanmotor.AngularVelocity = -100
script.Parent.Parent.Shaft.Fanmotor.MotorMaxAcceleration = 10
script.Parent.Parent.Shaft.FanHummingSFX.Volume = 3
script.Parent.Parent.Knob.Switch2.Transparency = 0	
elseif script.Parent.Parent.Value.Value == 2 then
script.Parent.Parent.Value.Value = 3
script.Parent.Parent.Knob.Switch2.Transparency = 1
script.Parent.Parent.Shaft.Fanmotor.AngularVelocity = -120
script.Parent.Parent.Shaft.Fanmotor.MotorMaxAcceleration = 15
script.Parent.Parent.Shaft.FanHummingSFX.Volume = 2
script.Parent.Parent.Knob.Switch3.Transparency = 0
end
end
script.Parent.ClickDetector.MouseClick:connect(onClicked)
script.Parent.Parent.Clickhanger.ClickDetector.MouseClick:connect(onClicked)