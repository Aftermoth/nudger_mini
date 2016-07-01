minetest.register_craft({
	output = "nudger_mini:nudger",
	recipe = {
		{"default:copper_ingot"},
		{"group:stick"}
	}
})

local function face(ptd)
	local a, u = ptd.above.x, ptd.under.x
	if a > u then return 0,1
	elseif u > a then return 0,-1
	else
		a, u = ptd.above.y, ptd.under.y
		if a > u then return 1,1
		elseif u > a then return 1,-1
		else
			a, u = ptd.above.z, ptd.under.z
			if a > u then return 2,1
			elseif u > a then return 2,-1
			end
		end
	end
end

local function axsgn(d)
	if d%2 == 0 then return 2, 1-d
	else return 0, 2-d
	end
end
local function choose_axis(plr, ptd, mode)
	local axis, sign = face(ptd)
	if mode == 0 then return axis, sign
	elseif axis ~= 1 then
		if mode == 1 then return 1, 1
		else return 2-axis, (axis-1)*sign 
		end
	else
		local hdir = (5 - math.floor(plr:get_look_yaw()/1.571+.5))%4
		if mode == 2 then return axsgn((hdir+3)%4)
		elseif sign == 1 then return axsgn(hdir)
		else return axsgn((hdir+2)%4)
		end
	end

end

local map = {
	{  -- x
		{0, 1, 3, -1, -2, 2},
		{0, 4, 20, 8},
		{0, 0, 2, 0}, 12, 20,
	},
	{  --y
		{-1, 0, 2, 1, 3, -2},
		{4, 12, 8, 16},
		{0, 3, 2, 1}, 0, 24,
	},
	{  --z
		{0, -1, -2, 3, 1, 2},
		{0, 16, 20, 12},
		{0, 0, 0, 0}, 4, 12,
	},
}

local function rotate(istk, plr, ptd, mode, sgn)
	local pos = ptd.under
	local node = minetest.get_node(pos)
	local ndef = minetest.registered_nodes[node.name]
	if not ndef or not (ndef.paramtype2 == "facedir") or node.param2 == nil
	or (ndef.drawtype == "nodebox" and not (ndef.node_box.type == "fixed")) then
		minetest.chat_send_player(plr:get_player_name(),"Target can't be nudged.")
		return
	end
	local p = (node.param2)%24
	local q, r = math.floor(p/4), p%4
	local a, s = choose_axis(plr,ptd,mode)
	local t = map[a+1]
	local k = t[1][q+1]
	s = s*sgn
	if k == -1 then p = t[4] + (p + 4 + s)%4
	elseif k == -2 then p = t[5] - (t[5] - p + 3 + s)%4 - 1
	else
		local o, i = t[3], (k + 4 + s)%4 + 1
		p = t[2][i] + (r + o[k+1] + 4 - o[i])%4
	end
	node.param2 = p
	minetest.swap_node(pos, node)
	local wear = tonumber(istk:get_wear()) + 257
	if wear > 65535 then istk:clear() else istk:set_wear(wear) end
end

local function edit_ok(pos, plr)
	if minetest.is_protected(pos, plr:get_player_name()) then
		minetest.record_protection_violation(pos, plr:get_player_name())
		minetest.chat_send_player(plr:get_player_name(),"Permission denied.")
	else return true
	end
end

local function do_on_use(istk, plr, ptd, rt)
	local rm = tonumber(istk:get_metadata())
	if rm then
		if rt then rm = 3*(1 - math.floor(rm/3)) + rm%3
		else
			local sr, dr = math.floor(rm/3), rm%3
			if plr:get_player_control().sneak then rm = 3*sr + (dr + 1)%3
			else
				local pos = ptd.type == "node" and ptd.under
				if pos and edit_ok(pos, plr) then
					rotate(istk, plr, ptd, dr, 1-2*sr)
				end
				return istk
			end
		end
	else rm = 0
		minetest.chat_send_player(plr:get_player_name(),"Shift click axes. Right click directions.")
	end
	istk:set_name("nudger_mini:nudger"..rm)
	istk:set_metadata(rm)
	return istk
end

minetest.register_tool("nudger_mini:nudger", {
	description = "Nudger",
	inventory_image = "nudger.png",
	on_use = function(istk, plr, ptd)
		return do_on_use(istk, plr, ptd)
	end,
	on_place = function(istk, plr, ptd)
		return do_on_use(istk, plr, ptd, 1)
	end,
})

local adj={"+cw","lf","dn","-cw","rt","up"}
for i = 0, 5 do
	minetest.register_tool("nudger_mini:nudger"..i, {
		description = "Nudger ("..adj[i+1]..")",
		inventory_image = "nudger.png^nudge"..i..".png",
		wield_image = "nudger.png",
		groups = {not_in_creative_inventory=1},
		on_use = function(istk, plr, ptd)
			return do_on_use(istk, plr, ptd)
		end,
		on_place = function(istk, plr, ptd)
			return do_on_use(istk, plr, ptd, 1)
		end,
	})
end
