while true do
	script.Parent.Parent.oscillationflywheeltechnology.oscillator.AngularVelocity = script.Parent.Parent.Parent["Main motor"].Tip.RotVelocity.Magnitude/240
	wait(0.001)
end
