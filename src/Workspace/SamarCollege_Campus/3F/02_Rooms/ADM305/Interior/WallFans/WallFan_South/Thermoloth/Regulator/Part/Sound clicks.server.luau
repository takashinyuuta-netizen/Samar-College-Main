function onClicked()
script.Parent.Sound:Play()
script.Parent.Clickhanger.RopePull.Length = 3
	

wait(.3)
	
script.Parent.Clickhanger.RopePull.Length = 2
script.Parent.Sound:Stop()
end
script.Parent.ClickDetector.MouseClick:connect(onClicked)
