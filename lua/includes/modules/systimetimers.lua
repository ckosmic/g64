--[[
	SysTimeTimers b1.0

	Functions:
		- systimetimers.Adjust( string timerName, number timerDelay, number timerRepeat, function timerFunction, boolean pauseOnRun )
		- .Check() - Does nothing, just like timer.Check ;(
		- .Create( string timerName, number timerDelay, number timerRepeat, function timerFunction, boolean pauseOnRun )
		- .Destroy( string timerName )
		- .Exists( string timerName )
		- .GetQueue() - This contains all the timers with all their statuses and whatnot, don't modify these values unless you know what you're doing!
		- .Pause( string timerName )
		- .Remove( string timerName )
		- .RepsLeft( string timerName )
		- .Resume( string timerName )
		- .Simple( string timerName, function timerFunction )
		- .Start( string timerName )
		- .Stop( string timerName )
		- .TimeLeft( string timerName )
		- .Toggle( string timerName )

	todo:
		- Better error handling
		- (M) make in C++

]]

AddCSLuaFile() -- ;(
module("systimetimers", package.seeall)

if SERVER then
	CreateConVar("stt_ignore_hibernation_warning", 0, bit.bor(FCVAR_ARCHIVE), "If set to 1, will not show a warning about hibernation on timer creation", 0, 1)
end

-- own

systimetimers.Queue = {

}

function systimetimers.GetQueue()
	return systimetimers.Queue or {}
end

function systimetimers.Resume(timerName)
	if not timerName then ErrorNoHaltWithStack("[SysTimeTimers] You didn't specify a timer name!") return false end
	if not systimetimers.Queue[timerName] then ErrorNoHaltWithStack(string.format("[SysTimeTimers] There is no timer named \"%s\"", tostring(timerName))) return false end

	if systimetimers.Queue[timerName]["Paused"] == false then
		return false -- Already running
	end

	systimetimers.Queue[timerName]["Paused"] = false

	return true
end

-- timer.*

function systimetimers.Adjust(timerName, timerDelay, timerRepeat, timerFunction, pauseOnRun)
	if not timerName then error("[SysTimeTimers] You didn't specify a timer name!") return end
	if not systimetimers.Queue[timerName] then error(string.format("[SysTimeTimers] There is no timer named \"%s\"", tostring(timerName))) return end

	timerDelay = timerDelay or systimetimers.Queue[timerName]["RunEvery"]
	timerRepeat = timerRepeat or systimetimers.Queue[timerName]["RunAmount"]
	timerFunction = timerFunction or systimetimers.Queue[timerName]["Func"]
	pauseOnRun = pauseOnRun or systimetimers.Queue[timerName]["Paused"]

	systimetimers.Create(timerName, timerDelay, timerRepeat, timerFunction, pauseOnRun)
end

function systimetimers.Check() -- Yes, when i said i will "Add all of the functions from timer.*", i seriously meant that.
	return
end

function systimetimers.Create(timerName, timerDelay, timerRepeat, timerFunction, pauseOnRun)
	if not timerName then error("[SysTimeTimers] You didn't specify a timer name!") return end
	if not timerDelay then error("[SysTimeTimers] You didn't specify a timer delay!") return end
	if not timerRepeat then error("[SysTimeTimers] You didn't specify a timer repeat amount (0 = Infinite)!") return end
	if not timerFunction then error("[SysTimeTimers] You didn't specify a timer function!") return end

	if timerRepeat <= 0 then timerRepeat = math.huge end

	systimetimers.Queue[timerName] = {
		["RunEvery"] = math.Clamp(timerDelay, 0.01, math.huge),
		["LastRun"] = SysTime(),
		["RunAmount"] = timerRepeat,
		["RunAmountTotal"] = 0,
		["Paused"] = pauseOnRun or false,
		["Func"] = timerFunction
	}

	if SERVER then
		if (GetConVar_Internal("stt_ignore_hibernation_warning"):GetString() ~= "1") and (GetConVar_Internal("sv_hibernate_think"):GetString() ~= "1") then
			ErrorNoHalt("[SysTimeTimers - WARN] Please ensure \"sv_hibernate_think\" is set to \"1\" as timers will not progress when the server is empty, you can also use stt_ignore_hibernation_warning 1 to disable this warning!")
		end
	end
end

function systimetimers.Destroy(timerName)
	if not timerName then error("[SysTimeTimers] You didn't specify a timer name!") return end
	if not systimetimers.Queue[timerName] then error(string.format("[SysTimeTimers] There is no timer named \"%s\"", tostring(timerName))) return end

	table.Empty(systimetimers.Queue[timerName])
	systimetimers.Queue[timerName] = nil
	collectgarbage("collect")
end

function systimetimers.Exists(timerName)
	if not timerName then error("[SysTimeTimers] You didn't specify a timer name!") return end
	return systimetimers.Queue[timerName] and true or false
end

function systimetimers.Pause(timerName)
	if not timerName then ErrorNoHaltWithStack("[SysTimeTimers] You didn't specify a timer name!") return false end
	if not systimetimers.Queue[timerName] then ErrorNoHaltWithStack(string.format("[SysTimeTimers] There is no timer named \"%s\"", tostring(timerName))) return false end

	if systimetimers.Queue[timerName]["Paused"] == true then
		return false -- Already paused
	end

	systimetimers.Queue[timerName]["Paused"] = true

	return true
end

systimetimers.Remove = systimetimers.Destroy

function systimetimers.RepsLeft(timerName)
	if not timerName then error("[SysTimeTimers] You didn't specify a timer name!") return end
	if not systimetimers.Queue[timerName] then error(string.format("[SysTimeTimers] There is no timer named \"%s\"", tostring(timerName))) return end

	return systimetimers.Queue[timerName]["RunAmount"] - systimetimers.Queue[timerName]["RunAmountTotal"]
end

function systimetimers.Simple(timerDelay, timerFunction)
	if not timerDelay then error("[SysTimeTimers] You didn't specify a timer delay!") return end
	if not timerFunction then error("[SysTimeTimers] You didn't specify a timer function!") return end

	systimetimers.Create("_stt_simple_"..tostring(SysTime())..tostring(math.random()), timerDelay, 1, timerFunction, false)
end

function systimetimers.Start(timerName)
	if not timerName then error("[SysTimeTimers] You didn't specify a timer name!") return end

	if systimetimers.Queue[timerName] then
		systimetimers.Queue[timerName]["LastRun"] = SysTime()
		systimetimers.Queue[timerName]["RunAmountTotal"] = 0
		systimetimers.Queue[timerName]["Paused"] = false
	end

	return systimetimers.Queue[timerName] and true or false
end

function systimetimers.Stop(timerName)
	if not timerName then error("[SysTimeTimers] You didn't specify a timer name!") return end
	if not systimetimers.Queue[timerName] then ErrorNoHaltWithStack(string.format("[SysTimeTimers] There is no timer named \"%s\"", tostring(timerName))) return false end
	if (systimetimers.Queue[timerName]["RunAmountTotal"] == 0) and (systimetimers.Queue[timerName]["Paused"] == true) then
		return false  -- Already stopped
	end

	systimetimers.Queue[timerName]["LastRun"] = SysTime()
	systimetimers.Queue[timerName]["RunAmountTotal"] = 0
	systimetimers.Queue[timerName]["Paused"] = true

	return true
end

function systimetimers.TimeLeft(timerName)
	if not timerName then error("[SysTimeTimers] You didn't specify a timer name!") return end
	if not systimetimers.Queue[timerName] then error(string.format("[SysTimeTimers] There is no timer named \"%s\"", tostring(timerName))) return end

	local timeleft_ = (systimetimers.Queue[timerName]["LastRun"] + systimetimers.Queue[timerName]["RunEvery"]) - SysTime()
	if systimetimers.Queue[timerName]["Paused"] == true then
		timeleft_ = -timeleft_
	end

	return timeleft_
end

function systimetimers.Toggle(timerName)
	if not timerName then error("[SysTimeTimers] You didn't specify a timer name!") return end
	if not systimetimers.Queue[timerName] then error(string.format("[SysTimeTimers] There is no timer named \"%s\"", tostring(timerName))) return end

	systimetimers.Queue[timerName]["Paused"] = (not systimetimers.Queue[timerName]["Paused"])
end

local function systimetimers_doTimers()
	for k, v in pairs(systimetimers.Queue) do
		if not v["Paused"] == true then
			local nextRun = v["LastRun"] + v["RunEvery"]
			if SysTime() >= nextRun then
				v["LastRun"] = SysTime()
				v["RunAmountTotal"] = v["RunAmountTotal"] + 1
				
				local t_s, t_o = pcall(function()
					v["Func"]()
				end)

				if t_s ~= true then
					systimetimers.Destroy(k)
					ErrorNoHaltWithStack(string.format("SysTimeTimers Error: %s", tostring(t_o)))
					return
				end

				if v["RunAmountTotal"] >= v["RunAmount"] then
					systimetimers.Destroy(k)
				end
			end
		end
	end
end

hook.Add("Think", "_systimers_doTimers_", systimetimers_doTimers)

concommand.Add("stt_dumptimers", function()
	print("SysTimeTimers:\n")
	PrintTable(systimetimers.GetQueue())
end, nil, "Shows all the timers along with their information")
