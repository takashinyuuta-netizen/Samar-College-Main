function onClicked()
script.Parent.Sound:Play()
script.Parent.RopePull.Length = 2
	

wait(.3)
	
script.Parent.RopePull.Length = 1.833
script.Parent.Sound:Stop()
end
script.Parent.ClickDetector.MouseClick:connect(onClicked)
