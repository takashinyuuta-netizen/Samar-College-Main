IsOn = false
function onClicked()
	if IsOn == false then
	IsOn = true
	script.Parent.Click:Play()	
 	script.Parent.Parent.Switch2.Transparency = 1
	script.Parent.Parent.Switch1.Transparency = 1
	script.Parent.Parent.IsOn.Value = true	
	elseif IsOn == true then
	IsOn = false
	script.Parent.Click:Play()		
	script.Parent.Parent.Switch2.Transparency = 1
	script.Parent.Parent.Switch1.Transparency = 1
	script.Parent.Parent.IsOn.Value = false
	end
end
script.Parent.ClickDetector.MouseClick:connect(onClicked)