-- Active PLAYER : keep only active players data on server
--(c) 2015-2016 rnd
-- Took some code from rnd
-- noob delete by ManElevation

noob = {}
minetest.register_privilege("nnoob", {description = "Active player Priv.", give_to_singleplayer = true})
minetest.register_privilege("mnoob", {description = "Active player Priv.", give_to_singleplayer = true})

-- SETTINGS 

noob.requirement = {"default:dirt 1", "default:steel_ingot 1"};
noob.welcome = "*** IMPORTANT *** dig 1 dirt and 1 steel_ingot and keep in inventory before leaving the server for the first time, or your player data will be deleted";
--dig
minetest.override_item("default:dirt", {
   after_place_node = function(pos, placer, itemstack, pointed_thing)
      local player_name = placer:get_player_name()
      local privs = minetest.get_player_privs(player_name)
      if not privs['nnoob'] == true then
         privs['nnoob'] = true
         minetest.set_player_privs(player_name, privs)
         minetest.chat_send_player(player_name, 'Your now a active player!')
      end
   end,
})

minetest.override_item("default:stone_with_iron", {
   after_place_node = function(pos, placer, itemstack, pointed_thing)
      local player_name = placer:get_player_name()
      local privs = minetest.get_player_privs(player_name)
      if not privs['mnoob'] == true then
         privs['mnoob'] = true
         minetest.set_player_privs(player_name, privs)
         minetest.chat_send_player(player_name, 'Your now a active player!')
      end
   end,
})
--
noob.players = {};
local worldpath = minetest.get_worldpath();


minetest.register_on_joinplayer(function(player) 
	local name = player:get_player_name(); if name == nil then return end 
	
	-- read player inventory data
	local inv = player:get_inventory();
	local isnoob = inv:get_stack("noob", 1):get_count();
	inv:set_size("noob", 2);
	local ip = minetest.get_player_ip(name); if not ip then return end
	inv:set_stack("noob", 2, ItemStack("IP".. ip)) -- string.gsub(ip,".","_")));
	
	if isnoob > 0 then
		noob.players[name] = 1
		minetest.chat_send_player(name, "#Active Place: welcome back");
	else
		local privs = minetest.get_player_privs(name);
		if privs.mnoob then
			inv:set_stack("noob", 1, ItemStack("noob"));
			minetest.chat_send_player(name, "#Notnoob!: setting as active player.");
			noob.players[name] = 1
		else
			noob.players[name] = 0
			local form = "size [6,2] textarea[0,0;6.6,3.5;help;NOOB WELCOME;".. noob.welcome.."]"
			minetest.show_formspec(name, "noob:welcome", form)
	--		minetest.chat_send_player(name, noob.welcome);
		end
	end
	
	
end)

minetest.register_on_leaveplayer(function(player, timed_out)
	local name = player:get_player_name(); if name == nil then return end
	if noob.players[name] == 1 then return end -- already active, do nothing

	local delete = false; -- should we delete player?
	
	-- read player inventory data
	local inv = player:get_inventory();

	-- does player have all the required items in inventory?
	for _,item in pairs(noob.requirement) do
		if not inv:contains_item("main", item)	then 
			delete = true
		end
	end
	
	if not delete then -- set up active player inventory so we know player is active next time
		inv:set_size("noob", 2);
		inv:set_stack("noob", 1, ItemStack("noob"));
	else -- delete player profile
		
		local filename = worldpath .. "\\players\\" .. name;
		
		-- PROBLEM: deleting doesnt always work? seems minetest itself is saving stuff.
		-- so we wait a little and then delete
		minetest.after(10,function() 
			print("[noob] removing player filename " .. filename)
			local err,msg = os.remove(filename) 
			if err==nil then 
				print ("[noob] error removing player data " .. filename .. " error message: " .. msg) 
			end
			-- TO DO: how to remove players from auth.txt easily without editing file manually like below
		end);
	end
end
)

-- delete file if not active player
local function remove_non_active_player_file(name)
	local filename = worldpath.."\\players\\"..name;
	local f=io.open(filename,"r")
	local s = f:read("*all"); f:close();
	if string.find(s,"Item noob") then return false else os.remove(filename) return true end
end

-- deletes data with no corresponding playerfiles from auth.txt and creates auth_new.txt
local function player_file_exists(name)
	local f=io.open(worldpath.."\\players\\"..name,"r")
	if f~=nil then io.close(f) return true else return false end
end

local function remove_missing_players_from_auth()
	
	local playerfilelist = minetest.get_dir_list(worldpath.."\\players", false);
	
	local f = io.open(worldpath.."\\auth.txt", "r");
	if not f then return end
	local s = f:read("*a");f:close();
	local p1,p2;

	f = io.open(worldpath.."\\auth_new.txt", "w");
	if not f then return end
	
	local playerlist = {};
	for _,name in ipairs(playerfilelist) do
		playerlist[name]=true;
	end
	
	local i=0;
	local j=0; local k=0;
	local name;
	local count = 0;
	-- parse through auth and remove missing players data
	

	while j do
		j=string.find(s,":",i);
		if j then
			if i ~= 1 then
				name = string.sub(s,i+1,j-1) 
			else
				name = string.sub(s,1,j-1)
			end
			if j then 
				k=string.find(s,"\n",i+1);
				if not k then 
					j = nil
					if playerlist[name] then 
						f:write(string.sub(s,i+1)) 
					else 
						count = count+1 
					end
				else
					if playerlist[name] then 
						f:write(string.sub(s,i+1,k)) 
					else 
						count = count + 1 
					end
					i=k;
				end
			end
		end
	end
	f:close();
	print("#NOOB : removed " .. count .. " entries from auth.txt. Replace auth.txt with auth_new.txt");
end

local function remove_non_active_player_files()
	local playerfilelist = minetest.get_dir_list(worldpath.."\\players", false);

	local count = 0;
	for _,name in ipairs(playerfilelist) do
		if remove_non_active_player_file(name) then
			count = count + 1
		end
	end
	print("#NOOB:  removed " .. count .. " non active player files");
end

minetest.register_on_shutdown(function() remove_non_active_player_files();remove_missing_players_from_auth() end)