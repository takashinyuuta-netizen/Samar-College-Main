Speed = 1.5
Time = 5
Running = false
for x,z in pairs(script.Parent.Parent:getChildren()) do
if z.Name == "Button" then
z.CD.MouseClick:connect(function ()
if Running == true then return end
Running = true
for i=1,script.Parent.Size.x/Speed*10+1 do 
script.Parent.CFrame = script.Parent.CFrame*CFrame.new(-0.1,0*Speed,0)
wait()
end 
wait(Time)
for i=1,script.Parent.Size.x/Speed*10+1 do 
script.Parent.CFrame = script.Parent.CFrame*CFrame.new(0.1,0*Speed,0)
wait()
end 
Running = false
end)
end
end 