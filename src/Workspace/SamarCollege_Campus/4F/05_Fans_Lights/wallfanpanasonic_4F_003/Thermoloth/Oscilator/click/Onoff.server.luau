function onClicked()
	if script.Parent.Parent.Value.Value == 0 then
		script.Parent.Parent.Value.Value = 1
		script.Parent.Speed.Disabled = false
	elseif script.Parent.Parent.Value.Value == 1 then
		script.Parent.Parent.Value.Value = 0
		script.Parent.Speed.Disabled = true
		script.Parent.Parent.oscillationflywheeltechnology.oscillator.AngularVelocity = 0
	end
end
script.Parent.ClickDetector.MouseClick:connect(onClicked)
