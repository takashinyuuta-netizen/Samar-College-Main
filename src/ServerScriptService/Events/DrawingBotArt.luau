--[[ DrawingBotArt — pictures the 🤖 Art Bot can draw in Guess the Drawing (solo games).
  SERVER ONLY (the word is the key, so guessers can't read it).
  Each picture = list of strokes { c = color, w = width, pts = { x1, y1, x2, y2, ... } } on a 0..1 canvas (y goes DOWN).
  Colors: 1 black, 2 red, 3 blue, 4 green, 5 yellow, 6 orange, 7 purple. Max 30 points per stroke.
  Add a picture: M.Art["word"] = function() return { strokes } end, using the helpers below. ]]
local M = {}
local pi = math.pi

local function S(c, w, pts) return { c = c, w = w or 2, pts = pts } end
local function line(c, w, x1, y1, x2, y2) return S(c, w, { x1, y1, x2, y2 }) end
local function poly(c, w, list, close)
	local pts = {}
	for _, v in ipairs(list) do table.insert(pts, v) end
	if close then table.insert(pts, list[1]) table.insert(pts, list[2]) end
	return S(c, w, pts)
end
local function rect(c, w, x1, y1, x2, y2) return poly(c, w, { x1, y1, x2, y1, x2, y2, x1, y2 }, true) end
-- ellipse / arc (angles in radians, 0 = right, pi/2 = down because y goes down)
local function arc(c, w, cx, cy, rx, ry, a1, a2, seg)
	seg = seg or 24
	local pts = {}
	for k = 0, seg do
		local a = a1 + (a2 - a1) * k / seg
		table.insert(pts, cx + math.cos(a) * rx) table.insert(pts, cy + math.sin(a) * ry)
	end
	return S(c, w, pts)
end
local function circle(c, w, cx, cy, r, seg) return arc(c, w, cx, cy, r, r, 0, 2 * pi, seg or 26) end

M.Art = {
	sun = function()
		local s = { circle(5, 3, 0.5, 0.5, 0.17) }
		for k = 0, 7 do
			local a = k / 8 * 2 * pi
			table.insert(s, line(6, 2, 0.5 + math.cos(a) * 0.23, 0.5 + math.sin(a) * 0.23, 0.5 + math.cos(a) * 0.36, 0.5 + math.sin(a) * 0.36))
		end
		return s
	end,
	star = function()
		local pts = {}
		for k = 0, 9 do
			local r = (k % 2 == 0) and 0.36 or 0.15
			local a = -pi / 2 + k / 10 * 2 * pi
			table.insert(pts, 0.5 + math.cos(a) * r) table.insert(pts, 0.53 + math.sin(a) * r)
		end
		return { poly(5, 3, pts, true) }
	end,
	house = function()
		return { rect(1, 2, 0.25, 0.47, 0.75, 0.85), poly(2, 3, { 0.18, 0.48, 0.5, 0.18, 0.82, 0.48 }, false),
			rect(6, 2, 0.45, 0.65, 0.56, 0.85), rect(3, 2, 0.31, 0.55, 0.4, 0.64), rect(3, 2, 0.61, 0.55, 0.7, 0.64) }
	end,
	tree = function()
		return { rect(6, 3, 0.45, 0.6, 0.55, 0.9), circle(4, 3, 0.5, 0.4, 0.22), arc(4, 2, 0.42, 0.42, 0.08, 0.06, pi, 2 * pi, 10), arc(4, 2, 0.58, 0.36, 0.07, 0.05, pi, 2 * pi, 10) }
	end,
	clock = function()
		local s = { circle(1, 3, 0.5, 0.5, 0.33), line(1, 3, 0.5, 0.5, 0.5, 0.27), line(2, 2, 0.5, 0.5, 0.67, 0.5) }
		for k = 0, 11 do
			local a = k / 12 * 2 * pi
			table.insert(s, line(1, 1, 0.5 + math.cos(a) * 0.28, 0.5 + math.sin(a) * 0.28, 0.5 + math.cos(a) * 0.31, 0.5 + math.sin(a) * 0.31))
		end
		return s
	end,
	flag = function()
		return { line(1, 3, 0.25, 0.12, 0.25, 0.9), rect(3, 2, 0.25, 0.15, 0.78, 0.31), rect(2, 2, 0.25, 0.31, 0.78, 0.47), poly(1, 2, { 0.25, 0.15, 0.45, 0.31, 0.25, 0.47 }, false), circle(5, 2, 0.31, 0.31, 0.03, 10) }
	end,
	rainbow = function()
		local s = {}
		local cols = { 2, 6, 5, 4, 3, 7 }
		for k, c in ipairs(cols) do table.insert(s, arc(c, 3, 0.5, 0.72, 0.4 - (k - 1) * 0.04, 0.4 - (k - 1) * 0.04, pi, 2 * pi, 24)) end
		return s
	end,
	umbrella = function()
		return { arc(2, 3, 0.5, 0.48, 0.34, 0.26, pi, 2 * pi, 24), arc(2, 2, 0.27, 0.48, 0.115, 0.05, 0, pi, 8), arc(2, 2, 0.5, 0.48, 0.115, 0.05, 0, pi, 8),
			arc(2, 2, 0.73, 0.48, 0.115, 0.05, 0, pi, 8), line(1, 3, 0.5, 0.22, 0.5, 0.8), arc(1, 3, 0.45, 0.8, 0.05, 0.05, 0, pi, 8) }
	end,
	rocket = function()
		return { poly(1, 2, { 0.42, 0.32, 0.58, 0.32, 0.58, 0.72, 0.42, 0.72 }, true), poly(2, 3, { 0.42, 0.32, 0.5, 0.12, 0.58, 0.32 }, false),
			poly(2, 2, { 0.42, 0.6, 0.32, 0.76, 0.42, 0.72 }, false), poly(2, 2, { 0.58, 0.6, 0.68, 0.76, 0.58, 0.72 }, false),
			circle(3, 2, 0.5, 0.45, 0.05, 12), poly(6, 3, { 0.45, 0.72, 0.5, 0.88, 0.55, 0.72 }, false) }
	end,
	book = function()
		return { poly(3, 2, { 0.5, 0.3, 0.2, 0.25, 0.2, 0.75, 0.5, 0.8 }, false), poly(3, 2, { 0.5, 0.3, 0.8, 0.25, 0.8, 0.75, 0.5, 0.8 }, false), line(1, 2, 0.5, 0.3, 0.5, 0.8),
			line(1, 1, 0.26, 0.38, 0.44, 0.41), line(1, 1, 0.26, 0.48, 0.44, 0.51), line(1, 1, 0.56, 0.41, 0.74, 0.38), line(1, 1, 0.56, 0.51, 0.74, 0.48) }
	end,
	planet = function()
		return { circle(6, 3, 0.5, 0.5, 0.2), arc(7, 3, 0.5, 0.52, 0.38, 0.09, 0, 2 * pi, 26), circle(1, 1, 0.82, 0.2, 0.02, 8), circle(1, 1, 0.18, 0.78, 0.02, 8) }
	end,
	heart = function()
		local pts = {}
		for k = 0, 28 do
			local t = k / 28 * 2 * pi
			local x = 16 * math.sin(t) ^ 3
			local y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
			table.insert(pts, 0.5 + x / 45) table.insert(pts, 0.48 - y / 45)
		end
		return { S(2, 3, pts) }
	end,
	fish = function()
		return { arc(3, 3, 0.45, 0.5, 0.25, 0.14, 0, 2 * pi, 26), poly(3, 3, { 0.69, 0.5, 0.85, 0.38, 0.85, 0.62 }, true), circle(1, 2, 0.32, 0.47, 0.02, 8), arc(1, 1, 0.38, 0.5, 0.05, 0.08, -pi / 2, pi / 2, 8) }
	end,
	pencil = function()
		return { rect(5, 2, 0.2, 0.45, 0.7, 0.55), poly(1, 2, { 0.7, 0.45, 0.85, 0.5, 0.7, 0.55 }, false), rect(2, 2, 0.13, 0.45, 0.2, 0.55), line(1, 2, 0.81, 0.48, 0.85, 0.5) }
	end,
	ruler = function()
		local s = { rect(6, 2, 0.12, 0.4, 0.88, 0.58) }
		for k = 0, 12 do
			local x = 0.16 + k * 0.06
			table.insert(s, line(1, 1, x, 0.4, x, (k % 2 == 0) and 0.5 or 0.45))
		end
		return s
	end,
	bell = function()
		return { poly(5, 3, { 0.3, 0.7, 0.36, 0.62, 0.38, 0.42, 0.44, 0.3, 0.5, 0.27, 0.56, 0.3, 0.62, 0.42, 0.64, 0.62, 0.7, 0.7 }, false), line(5, 3, 0.3, 0.7, 0.7, 0.7),
			circle(6, 2, 0.5, 0.75, 0.04, 10), circle(1, 2, 0.5, 0.24, 0.025, 8) }
	end,
	cat = function()
		return { circle(1, 2, 0.5, 0.55, 0.24), poly(1, 2, { 0.3, 0.42, 0.32, 0.2, 0.44, 0.33 }, false), poly(1, 2, { 0.56, 0.33, 0.68, 0.2, 0.7, 0.42 }, false),
			circle(4, 2, 0.42, 0.5, 0.03, 8), circle(4, 2, 0.58, 0.5, 0.03, 8), poly(2, 2, { 0.48, 0.6, 0.52, 0.6, 0.5, 0.63 }, true),
			line(1, 1, 0.44, 0.63, 0.24, 0.6), line(1, 1, 0.44, 0.65, 0.24, 0.68), line(1, 1, 0.56, 0.63, 0.76, 0.6), line(1, 1, 0.56, 0.65, 0.76, 0.68) }
	end,
	trophy = function()
		return { poly(5, 3, { 0.35, 0.22, 0.65, 0.22, 0.62, 0.45, 0.55, 0.55, 0.45, 0.55, 0.38, 0.45 }, true), arc(5, 2, 0.35, 0.33, 0.07, 0.08, pi / 2, 3 * pi / 2, 10),
			arc(5, 2, 0.65, 0.33, 0.07, 0.08, -pi / 2, pi / 2, 10), line(5, 3, 0.5, 0.55, 0.5, 0.68), rect(6, 2, 0.38, 0.68, 0.62, 0.78) }
	end,
	globe = function()
		return { circle(3, 3, 0.5, 0.45, 0.25), arc(4, 2, 0.5, 0.45, 0.1, 0.25, 0, 2 * pi, 20), line(4, 2, 0.25, 0.45, 0.75, 0.45),
			arc(1, 2, 0.5, 0.45, 0.31, 0.31, pi / 4, 3 * pi / 4, 12), line(1, 3, 0.5, 0.76, 0.5, 0.86), line(1, 3, 0.38, 0.86, 0.62, 0.86) }
	end,
	balloon = function()
		return { arc(2, 3, 0.5, 0.38, 0.17, 0.22, 0, 2 * pi, 24), poly(2, 2, { 0.48, 0.6, 0.5, 0.63, 0.52, 0.6 }, false), S(1, 1, { 0.5, 0.63, 0.47, 0.7, 0.53, 0.76, 0.47, 0.82, 0.5, 0.9 }) }
	end,
	car = function()
		return { poly(2, 3, { 0.15, 0.62, 0.15, 0.5, 0.3, 0.48, 0.38, 0.36, 0.62, 0.36, 0.72, 0.48, 0.85, 0.5, 0.85, 0.62 }, true),
			circle(1, 3, 0.3, 0.64, 0.06, 12), circle(1, 3, 0.7, 0.64, 0.06, 12), poly(3, 2, { 0.4, 0.4, 0.49, 0.4, 0.49, 0.47, 0.35, 0.47 }, true), poly(3, 2, { 0.53, 0.4, 0.6, 0.4, 0.66, 0.47, 0.53, 0.47 }, true) }
	end,
	moon = function()
		return { arc(5, 3, 0.5, 0.5, 0.28, 0.28, pi / 3, 5 * pi / 3, 24), arc(5, 3, 0.6, 0.5, 0.2, 0.24, 2 * pi / 3 + 0.25, 4 * pi / 3 - 0.25, 16) }
	end,
	apple = function()
		return { circle(2, 3, 0.5, 0.55, 0.24), S(6, 3, { 0.5, 0.33, 0.51, 0.25, 0.54, 0.2 }), arc(4, 2, 0.6, 0.25, 0.07, 0.035, 0, 2 * pi, 12) }
	end,
	cup = function()
		return { poly(3, 3, { 0.3, 0.35, 0.34, 0.75, 0.62, 0.75, 0.66, 0.35 }, false), line(3, 3, 0.3, 0.35, 0.66, 0.35), arc(3, 3, 0.68, 0.53, 0.09, 0.11, -pi / 2, pi / 2, 12),
			S(1, 1, { 0.42, 0.28, 0.44, 0.22, 0.42, 0.16 }), S(1, 1, { 0.52, 0.28, 0.54, 0.22, 0.52, 0.16 }) }
	end,
	chair = function()
		return { line(6, 3, 0.35, 0.2, 0.35, 0.88), line(6, 3, 0.35, 0.55, 0.68, 0.55), line(6, 3, 0.68, 0.55, 0.68, 0.88), line(6, 3, 0.35, 0.2, 0.42, 0.2), line(6, 2, 0.35, 0.35, 0.4, 0.35) }
	end,
	scissors = function()
		return { circle(2, 3, 0.32, 0.62, 0.08, 14), circle(2, 3, 0.32, 0.38, 0.08, 14), line(1, 2, 0.39, 0.6, 0.85, 0.36), line(1, 2, 0.39, 0.4, 0.85, 0.64), circle(1, 1, 0.55, 0.5, 0.015, 6) }
	end,
	backpack = function()
		return { poly(3, 3, { 0.3, 0.32, 0.36, 0.25, 0.64, 0.25, 0.7, 0.32, 0.7, 0.85, 0.3, 0.85 }, true), arc(3, 2, 0.5, 0.25, 0.08, 0.08, pi, 2 * pi, 10),
			rect(2, 2, 0.37, 0.56, 0.63, 0.76), line(1, 2, 0.37, 0.63, 0.63, 0.63) }
	end,
}

function M.words()
	local list = {}
	for w in pairs(M.Art) do table.insert(list, w) end
	return list
end

function M.strokes(word)
	local f = M.Art[word]
	return f and f() or nil
end

return M
