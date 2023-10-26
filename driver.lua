EC = {}
OPC = {}
RFP = {}
DRV = {}
REQ = {}
PersistData["SensorBindings"] = {}
PersistData["DriverToBindingMapping"] = {}

function RFP.AMBIENT_LIGHT_LEVEL(idBinding, tParams)
    --for k,v in pairs(tParams) do Dbg:Trace(tostring(k) .. '=' .. tostring(v)) end
    dbg(string.format('Level received: %s, target: %s, group: %s', tostring(tParams.LEVEL), tostring(tParams.TARGET), tostring(tParams.GROUP)))
	local deviceID = tostring(tonumber(tParams.GROUP) + 1)
	deviceID = deviceID:sub(-3)
	C4:SetVariable(tostring(PersistData["SensorBindings"][tostring(deviceID)] .. " Value"), tParams.LEVEL)
end

function EC.AMBIENT_LIGHT_LEVEL(tParams)
    RFP.AMBIENT_LIGHT_LEVEL(0, tParams)
end

function EC.Set_backlight_color(tParams)
	local list = tParams["Device List"] or ""
	local rgb = tParams["Color"] or ""
	if (list == "") or (rgb == "") then return end
	for deviceID in string.gmatch(tParams["Device List"], '([^,]+)') do
		local numID = tonumber(deviceID) or 0
    	if (numID == 0) then break end
		C4:SendToDevice(numID, "SET_BACKLIGHT_COLOR", {COLOR = GetColor("", rgb)})
	end
end

function EC.Adjust_backlight_LED_configuration(tParams)
	local list = tParams["Device List"] or ""
	local minBrightness = tonumber(tParams["Min Backlight Brightness"]) or 0
	local maxBrightness = tonumber(tParams["Max Backlight Brightness"]) or 0
	local darkRoomThreshold = tonumber(tParams["Dark Room Threshold"]) or 0
	local dimRoomThreshold = tonumber(tParams["Dim Room Threshold"]) or 0
	local offInHighBrightness = tParams["Off in High Brightness"] or "False"
	local brightRoomThreshold = tonumber(tParams["Bright Room Threshold"]) or 0
	if (list == "") or (minBrightness == "") or (maxBrightness == "") or (darkRoomThreshold == "") or (dimRoomThreshold == "") or (offInHighBrightness == "") or (brightRoomThreshold == "") then dbg("one or more values blank, cancelling") return end
	if(minBrightness >= maxBrightness) then
		minBrightness = maxBrightness - 1
		dbg("minimum brightness was above or equal to max brightness, this will cause director crash. adjusted values to correct issue")
	end
	if(darkRoomThreshold >= dimRoomThreshold) then
		darkRoomThreshold = brightRoomThreshold - 1
		dbg("darkRoomThreshold was above or equal to brightRoomThreshold, this will cause director crash. adjusted values to correct issue")
	end
	if(offInHighBrightness == "False" and brightRoomThreshold ~= 255) then
		brightRoomThreshold = 255
		dbg("brightRoomThreshold was not set to 255 with offInHighBrightness false, this will cause director crash. adjusted value to correct issue")
	end
	if(offInHighBrightness == "True" and brightRoomThreshold > 245) then
		brightRoomThreshold = 245
		dbg("brightRoomThreshold was above 245 with offInHighBrightness true, this will cause director crash. adjusted value to correct issue")
	end
	local cmdParams = {
		MAX_BRIGHTNESS = tonumber(maxBrightness),
		MAX_LUX = tonumber(brightRoomThreshold),
		MIN_BRIGHTNESS = tonumber(minBrightness),
		MIN_LUX = tonumber(darkRoomThreshold),
	}
	local curveCommandParams = {
		LEVEL = tostring(dimRoomThreshold)
	}
	list = trim(list)
	for deviceID in string.gmatch(tParams["Device List"], '([^,]+)') do
		local numID = tonumber(deviceID) or 0
    	if (numID == 0) then break end
		dbg(dump(cmdParams))
		C4:SendToDevice(numID, "BACKLIGHT_LED_SETTINGS", cmdParams)
		dbg(dump(curveCommandParams))
		C4:SendToDevice(numID, "BACKLIGHT_CURVE", curveCommandParams)
	end
end

function EC.Adjust_status_LED_configuration(tParams)
	local list = tParams["Device List"] or ""
	local minBrightness = tonumber(tParams["Min LED Brightness"]) or 0
	local maxBrightness = tonumber(tParams["Max LED Brightness"]) or 0
	local darkRoomThreshold = tonumber(tParams["Dark Room Threshold"]) or 0
	local brightRoomThreshold = tonumber(tParams["Bright Room Threshold"]) or 0
	if (list == "") or (minBrightness == "") or (maxBrightness == "") or (darkRoomThreshold == "") or (brightRoomThreshold == "") then dbg("one or more values blank, cancelling") return end
	if(minBrightness >= maxBrightness) then
		minBrightness = maxBrightness - 1
		dbg("minimum brightness was above or equal to max brightness, this will cause director crash. adjusted values to correct issue")
	end
	if(darkRoomThreshold >= brightRoomThreshold) then
		darkRoomThreshold = brightRoomThreshold - 1
		dbg("darkRoomThreshold was above or equal to brightRoomThreshold, this will cause director crash. adjusted values to correct issue")
	end
	local cmdParams = {
		MAX_BRIGHTNESS = tonumber(maxBrightness),
		MAX_LUX = tonumber(brightRoomThreshold),
		MIN_BRIGHTNESS = tonumber(minBrightness),
		MIN_LUX = tonumber(darkRoomThreshold),
	}
	for deviceID in string.gmatch(tParams["Device List"], '([^,]+)') do
		local numID = tonumber(deviceID) or 0
		dbg("numID: " .. numID)
    	if (numID == 0) then break end
		dbg(dump(cmdParams))
		C4:SendToDevice(numID, "STATUS_LED_SETTINGS", cmdParams)
	end
end

function EC.Replace_keypad_status_LED_color(tParams)
	local list = tParams["Device List"] or ""
	local oldColor = tParams["Old Color"] or ""
	local newColor = tParams["New Color"] or ""
	if (list == "") or (oldColor == "") or (newColor == "") then return end
	list = trim(list) .. ","
	for id in list:gfind("(%d+),") do
	  local currentdeviceid = tonumber(id) or 0
	  dbg("Current ID Value: " .. currentdeviceid)
	  if (currentdeviceid == 0) then break end
	  local deviceProperties = GetPropertiesFromDevices(tostring(currentdeviceid))
		local t = {}                   -- table to store the indices
		local i = 0
		while true do
		  i = string.find(deviceProperties, "KEYPAD_BUTTON_INFO>(.-)</KEYPAD_BUTTON_INFO", i+1)    -- find 'next' line
		  if i == nil then break end
		  table.insert(t, i)
		end
		i = 1
		local buttonIDs = {}
		local buttonOnColors = {}
		local buttonCurrentColors = {}
		for keys,vals in pairs(t) do
			if t[i] == nil then break end
		  buttonIDs[i] = string.match(deviceProperties.sub(deviceProperties,t[i], t[i+1]), "<BUTTON_ID>(.-)</BUTTON_ID>")
		  dbg("Button ID: " .. buttonIDs[i])
		  buttonOnColors[i] = string.match(deviceProperties.sub(deviceProperties, t[i], t[i+1]), "<ON_COLOR>(.-)</ON_COLOR>")
		  buttonCurrentColors[i] = string.match(deviceProperties.sub(deviceProperties, t[i], t[i+1]), "<CURRENT_COLOR>(.-)</CURRENT_COLOR>")
		  if buttonOnColors[i] == GetColor("", oldColor) then
			C4:SendToDevice(id, "KEYPAD_BUTTON_COLOR", {ON_COLOR = GetColor("", newColor), BUTTON_ID = buttonIDs[i]})
			if buttonCurrentColors[i] == GetColor("", oldColor) then
			  C4:SendToDevice(id, "KEYPAD_BUTTON_COLOR", {CURRENT_COLOR = GetColor("", newColor), BUTTON_ID = buttonIDs[i]}) 
			else dbg("On color matched and replaced but button is currently a different color. Not setting current color.") 
			end
		  else
			dbg("Button color does not match, color not changing!")
		  end
		i=i+2
	  end
	  currentdeviceid = currentdeviceid + 1
	end
end

function EC.Dim_all_keypad_status_LEDs(tParams)
	local list = tParams["Device List"] or ""
    local factor = tParams["Dimming Factor"] or ""
    if (list == "") or (factor == "") then return end
    local divideFactor = tonumber(factor)
    list = trim(list) .. ","
    for id in list:gfind("(%d+),") do
      local currentdeviceid = tonumber(id) or 0
      dbg("Current ID Value: " .. currentdeviceid)
      if (currentdeviceid == 0) then break end
      local deviceProperties = GetPropertiesFromDevices(tostring(currentdeviceid))
        local t = {}                   -- table to store the indices
        local i = 0
        while true do
          i = string.find(deviceProperties, "KEYPAD_BUTTON_INFO>(.-)</KEYPAD_BUTTON_INFO", i+1)    -- find 'next' line
          if i == nil then break end
          table.insert(t, i)
        end
        i = 1
        local buttonIDs = {}
        local buttonCurrentColors = {}
        for keys,vals in pairs(t) do
            if t[i] == nil then break end
          buttonIDs[i] = string.match(deviceProperties.sub(deviceProperties,t[i], t[i+1]), "<BUTTON_ID>(.-)</BUTTON_ID>")
          dbg("Button ID: " .. buttonIDs[i])
          buttonCurrentColors[i] = string.match(deviceProperties.sub(deviceProperties, t[i], t[i+1]), "<CURRENT_COLOR>(.-)</CURRENT_COLOR>")
          if buttonCurrentColors[i] ~= "000000" then
            local hex = buttonCurrentColors[i]:gsub("#","")
            local red = tonumber("0x"..hex:sub(1,2))
            local green = tonumber("0x"..hex:sub(3,4))
            local blue = tonumber("0x"..hex:sub(5,6))
            red = math.floor(red / divideFactor)
            green = math.floor(green / divideFactor)
            blue = math.floor(blue / divideFactor)
            local rgb = red .. "," .. green .. "," .. blue
            dbg("Color: " .. rgb)
			C4:SendToDevice(id, "KEYPAD_BUTTON_COLOR", {CURRENT_COLOR = GetColor("", rgb), BUTTON_ID = buttonIDs[i]})
          else
            dbg("Button currently off, color not changing!")
          end
        i=i+2
      end
      currentdeviceid = currentdeviceid + 1
    end
end

function EC.Brighten_all_keypad_status_LEDs(tParams)
	local list = tParams["Device List"] or ""
    local factor = tParams["Brighten Factor"] or ""
    if (list == "") or (factor == "") then return end
    local multiplyFactor = tonumber(factor)
    list = trim(list) .. ","
    for id in list:gfind("(%d+),") do
      local currentdeviceid = tonumber(id) or 0
      dbg("Current ID Value: " .. currentdeviceid)
      if (currentdeviceid == 0) then break end
      local deviceProperties = GetPropertiesFromDevices(tostring(currentdeviceid))
        local t = {}                   -- table to store the indices
        local i = 0
        while true do
          i = string.find(deviceProperties, "KEYPAD_BUTTON_INFO>(.-)</KEYPAD_BUTTON_INFO", i+1)    -- find 'next' line
          if i == nil then break end
          table.insert(t, i)
        end
        i = 1
        local buttonIDs = {}
        local buttonCurrentColors = {}
        for keys,vals in pairs(t) do
            if t[i] == nil then break end
          buttonIDs[i] = string.match(deviceProperties.sub(deviceProperties,t[i], t[i+1]), "<BUTTON_ID>(.-)</BUTTON_ID>")
          dbg("Button ID: " .. buttonIDs[i])
          buttonCurrentColors[i] = string.match(deviceProperties.sub(deviceProperties, t[i], t[i+1]), "<CURRENT_COLOR>(.-)</CURRENT_COLOR>")
          if buttonCurrentColors[i] ~= "000000" then
            local hex = buttonCurrentColors[i]:gsub("#","")
            local red = tonumber("0x"..hex:sub(1,2))
            local green = tonumber("0x"..hex:sub(3,4))
            local blue = tonumber("0x"..hex:sub(5,6))
            red = math.floor(red * multiplyFactor)
            green = math.floor(green * multiplyFactor)
            blue = math.floor(blue * multiplyFactor)
            if (red > 255) then red = 255 end
            if (green > 255) then green = 255 end
            if (blue > 255) then blue = 255 end
            local rgb = red .. "," .. green .. "," .. blue
            dbg("Color: " .. rgb)
            C4:SendToDevice(id, "KEYPAD_BUTTON_COLOR", {CURRENT_COLOR = GetColor("", rgb), BUTTON_ID = buttonIDs[i]})
          else
            dbg("Button currently off, color not changing!")
          end
        i=i+2
      end
      currentdeviceid = currentdeviceid + 1
    end
end

function EC.Replace_lighting_status_LED_color(tParams)
	local list = tParams["Device List"] or ""
    local oldColor = tParams["Old Color"] or ""
    local newColor = tParams["New Color"] or ""
    if (list == "") or (oldColor == "") or (newColor == "") then return end
    list = trim(list) .. ","
    for id in list:gfind("(%d+),") do
      local currentdeviceid = tonumber(id) or 0
      dbg("Current ID Value: " .. currentdeviceid)
      if (currentdeviceid == 0) then break end
      local deviceProperties = GetPropertiesFromDevices(tostring(currentdeviceid))
        local t = {}                   -- table to store the indices
        local i = 0
        while true do
          i = string.find(deviceProperties, "BUTTON_INFO>(.-)</BUTTON_INFO", i+1)    -- find 'next' line
          if i == nil then break end
          table.insert(t, i)
        end
        i = 1
        local buttonIDs = {}
        local buttonOnColors = {}
        local buttonOffColors = {}
        local buttonCurrentColors = {}
        for keys,vals in pairs(t) do
            if t[i] == nil then break end
          buttonIDs[i] = string.match(deviceProperties.sub(deviceProperties,t[i], t[i+1]), "<BUTTON_ID>(.-)</BUTTON_ID>")
          dbg("Button ID: " .. buttonIDs[i])
          buttonOnColors[i] = string.match(deviceProperties.sub(deviceProperties, t[i], t[i+1]), "<ON_COLOR>(.-)</ON_COLOR>")
          buttonOffColors[i] = string.match(deviceProperties.sub(deviceProperties, t[i], t[i+1]), "<OFF_COLOR>(.-)</OFF_COLOR>")
          buttonCurrentColors[i] = string.match(deviceProperties.sub(deviceProperties, t[i], t[i+1]), "<CURRENT_COLOR>(.-)</CURRENT_COLOR>")
          if buttonOnColors[i] == GetColor("", oldColor) then
            C4:SendToDevice(id, "SET_BUTTON_COLOR", {ON_COLOR = GetColor("", newColor), BUTTON_ID = buttonIDs[i]})
            if buttonCurrentColors[i] == GetColor("", oldColor) then
              C4:SendToDevice(id, "SET_BUTTON_COLOR", {CURRENT_COLOR = GetColor("", newColor), BUTTON_ID = buttonIDs[i]}) 
            else dbg("On color matched and replaced but button is currently a different color. Not setting current color.") 
            end
          else
            dbg("Button color does not match, color not changing!")
          end
          if buttonOffColors[i] == GetColor("", oldColor) then
            C4:SendToDevice(id, "SET_BUTTON_COLOR", {OFF_COLOR = GetColor("", newColor), BUTTON_ID = buttonIDs[i]})
            if buttonCurrentColors[i] == GetColor("", oldColor) then
              C4:SendToDevice(id, "SET_BUTTON_COLOR", {CURRENT_COLOR = GetColor("", newColor), BUTTON_ID = buttonIDs[i]}) 
            else dbg("On color matched and replaced but button is currently a different color. Not setting current color.") 
            end
          else
            dbg("Button color does not match, color not changing!")
          end
        i=i+2
      end
      currentdeviceid = currentdeviceid + 1
    end
end

function OPC.Ambient_Light_Devices(tParams)
    dbg("device update time" .. dump(tParams))
    for deviceID in string.gmatch(tParams, '([^,]+)') do
        local bindingName = C4:GetDeviceDisplayName(tonumber(deviceID)) .. " Light Sensor"
        local bindingNumber = deviceID:sub(-3)
		if((string.find(Properties["Ambient Light Devices"],bindingNumber) ~= nil) and (PersistData["SensorBindings"][tostring(bindingNumber)] == nil)) then
			dbg("adding binding" .. bindingNumber)
			C4:AddDynamicBinding(tonumber(bindingNumber) or 0, "CONTROL", false, bindingName, "AMBIENT_LEVEL", false, false)
        	PersistData["SensorBindings"][bindingNumber] = bindingName
			C4:AddVariable(PersistData["SensorBindings"][bindingNumber] .. " Value", "", "INT", true, false)
		else
			dbg("doing nothing for binding" .. bindingNumber)
		end
    end
	for k, _ in pairs(PersistData["SensorBindings"]) do
		local bindingNumber = k:sub(-3)
		if((PersistData["SensorBindings"][tostring(bindingNumber)] ~= nil) and (string.find(Properties["Ambient Light Devices"],bindingNumber) == nil)) then
			dbg("removing binding" .. bindingNumber)
			C4:DeleteVariable(PersistData["SensorBindings"][bindingNumber] .. " Value")
			PersistData["SensorBindings"][bindingNumber] = nil
			C4:RemoveDynamicBinding(tonumber(bindingNumber) or 0)
		else
			dbg("doing nothing for binding" .. bindingNumber)
		end
	end
end

function OPC.Debug_Mode(tParams)
	gDbgTimer = C4:KillTimer(gDbgTimer or 0)
    gDbgPrint, gDbgLog = (Properties["Debug Mode"]:find("Print") ~= nil), (Properties["Debug Mode"]:find("Log") ~= nil)
    if (Properties["Debug Mode"] == "Off") then return end

    gDbgTimer = C4:AddTimer(8*60, "MINUTES")
    dbg("Enabled Debug Timer for 8 Hours")
end

function ReceivedFromProxy(idBinding, strCommand, tParams)
	strCommand = strCommand or ''
	tParams = tParams or {}
	local args = {}
	if (tParams.ARGS) then
		local parsedArgs = C4:ParseXml(tParams.ARGS)
		for _, v in pairs(parsedArgs.ChildNodes) do
			args[v.Attributes.name] = v.Value
		end
		tParams.ARGS = nil
	end

	dbg('ReceivedFromProxy: ' .. idBinding, strCommand)

	local success, ret

	if (RFP and RFP[strCommand] and type(RFP[strCommand]) == 'function') then
		success, ret = pcall(RFP[strCommand], idBinding, strCommand, tParams, args)
	elseif (RFP and RFP[idBinding] and type(RFP[idBinding]) == 'function') then
		success, ret = pcall(RFP[idBinding], idBinding, strCommand, tParams, args)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		dbg('ReceivedFromProxy error: ', ret, idBinding, strCommand)
	end
end

function ExecuteCommand(strCommand, tParams)
	tParams = tParams or {}
	dbg('ExecuteCommand: ' .. strCommand, dump(tParams))

	if (strCommand == 'LUA_ACTION') then
		if (tParams.ACTION) then
			strCommand = tParams.ACTION
			tParams.ACTION = nil
		end
	end

	strCommand = string.gsub(strCommand, '%s+', '_')

	local success, ret

	if (EC and EC[strCommand] and type(EC[strCommand]) == 'function') then
		success, ret = pcall(EC[strCommand], tParams)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		dbg('ExecuteCommand error: ', ret, strCommand)
	end
end

function OnPropertyChanged(strProperty)
	local value = Properties[strProperty]
	if (type(value) ~= 'string') then
		value = ''
	end

	dbg('OnPropertyChanged: ' .. strProperty .. " " .. value)

	strProperty = string.gsub(strProperty, '%s+', '_')

	local success, ret

	if (OPC and OPC[strProperty] and type(OPC[strProperty]) == 'function') then
		success, ret = pcall(OPC[strProperty], value)
	end

	if (success == true) then
		return (ret)
	elseif (success == false) then
		dbg('OnPropertyChanged error: '.. ret .. " " .. strProperty .. " " .. " " .. value)
	end
end

function OnDriverLateInit(init)
	dbg("--driver late init--")

	for property, _ in pairs(Properties) do
		OnPropertyChanged(property)
	end
	for id, name in pairs(PersistData["SensorBindings"]) do
		dbg(name)
		if(Variables[name] == nil) then
			C4:AddVariable(name .. " Value", "", "INT", true, false)
		end
	end
end

function OnBindingChanged(idBinding, strClass, bIsBound)
	dbg("--change binding--")
end

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

 function GetColor(colorstr, rgb)
	if (colorstr ~= "") then
	  colorstr = colorstr:upper()
	  colorstr = LED_COLOR[colorstr] or colorstr
	  colorstr = ValidColor(colorstr) or "000000"
	  return colorstr
	else
	  rgb = rgb .. ","
	  local _, _, r, g, b = rgb:find("(%d-),(%d-),(%d-),")
	  r = tonumber(r) or 0
	  g = tonumber(g) or 0
	  b = tonumber(b) or 0
	  return string.format("%02x%02x%02x", r, g, b)
	end
  end

  function trim(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
  end

  function ValidColor(strColor)
	-- Valid RGB is 6 bytes...
	if (string.len(strColor) ~= 6) then return nil end
	-- Check that each character is a hex digit (%X == non-hex digits)
	if (string.find(strColor, "%X") ~= nil) then return nil end
	return strColor
  end

  function GetPropertiesFromDevices(device)
	local deviceProperties = ""
	  local strProperties = C4:GetDeviceData(device, "properties")
	  local strValues = C4:SendUIRequest(device, "GET_PROPERTIES_SYNC", {}, true)
	  if (not strValues) then
		strValues = C4:SendUIRequest(device, "GET_PROPERTIES", {}, true)
	  end
	  return strValues
  end

 if (PersistData ~= nil) then
    for key,value in pairs(PersistData["SensorBindings"]) do
        C4:AddDynamicBinding(key, "CONTROL", false, value, "AMBIENT_LEVEL", false, false)
    end
  end

  function dbg(strDebugText)
	if (gDbgPrint) then print(strDebugText) end
	if (gDbgLog) then C4:DebugLog("\r\n" .. strDebugText) end
  end