local mod	= DBM:NewMod("Nefarian-Classic", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 7007 $"):sub(12, -3))
mod:SetCreatureID(11583)

mod:SetModelID(11380)
mod:RegisterCombat("yell", L.YellP1)--ENCOUNTER_START appears to fire when he lands, so start of phase 2, ignoring all of phase 1
mod:SetWipeTime(50)--guesswork

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 22539 22686 22664 22665 22666",
	"SPELL_AURA_APPLIED 22687 22667",
	"UNIT_DIED",
	"UNIT_HEALTH mouseover target",
	"PARTY_KILL"
)

local WarnAddsLeft			= mod:NewAnnounce("WarnAddsLeft", 2, "136116")
local warnClassCall			= mod:NewAnnounce("WarnClassCall", 3, "136116")
local warnPhase				= mod:NewPhaseChangeAnnounce()
local warnPhase3Soon		= mod:NewPrePhaseAnnounce(3)
local warnShadowFlame		= mod:NewCastAnnounce(22539, 2)
local warnFear				= mod:NewCastAnnounce(22686, 2)
local warnSBVolley			= mod:NewCastAnnounce(22665, 2)

local specwarnShadowCommand	= mod:NewSpecialWarningTarget(22667, nil, nil, 2, 1, 2)
local specwarnVeilShadow	= mod:NewSpecialWarningDispel(22687, "RemoveCurse", nil, nil, 1, 2)
local specwarnClassCall		= mod:NewSpecialWarning("specwarnClassCall", nil, nil, nil, 1, 2)

local timerPhase			= mod:NewPhaseTimer(15)
local timerShadowFlameCD	= mod:NewCDTimer(12, 22539, nil, nil)
local timerVeilShadowCD		= mod:NewCDTimer(25, 22687, nil, nil)
local timerClassCall		= mod:NewTimer(30, "TimerClassCall", "136116", nil, nil, 5)
local timerFearNext			= mod:NewCDTimer(25, 22686, nil, nil, 3, 2)--26-42.5
local timerAddsSpawn		= mod:NewTimer(10, "TimerAddsSpawn", 19879, nil, nil, 1)
local timerMindControlCD	= mod:NewCDTimer(24, 22667, nil, nil)
local timerSBVolleyCD		= mod:NewCDTimer(19, 22665, nil, nil)
local timerSilenceCD		= mod:NewCDTimer(14, 22666, nil, nil)
local timerShadowblinkCD	= mod:NewCDTimer(30, 22664, nil, nil)

mod.vb.addLeft = 42
local addsGuidCheck = {}


function mod:OnCombatStart(delay, yellTriggered)
	table.wipe(addsGuidCheck)
	self.vb.addLeft = 42
	self:SetStage(1)
	timerAddsSpawn:Start(15-delay)
	timerMindControlCD:Start(30-delay)
	timerSBVolleyCD:Start(13-delay)
	timerSilenceCD:Start(20-delay)
end


function mod:SPELL_CAST_START(args)
	if args.spellId == 22539 then
		warnShadowFlame:Show()
		timerShadowFlameCD:Start()
	elseif args.spellId == 22686 then
		warnFear:Show()
		timerFearNext:Start()
	elseif args.spellId == 22667 then
		timerMindControlCD:Start(24)
	elseif args.spellId == 22665 then
		warnSBVolley:Show()
		timerSBVolleyCD:Start(19)
	elseif args.spellId == 22664 then
		timerShadowblinkCD:Start(30)
	elseif args.spellId == 22666 then
		timerSilenceCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 22687 then
		if self:CheckDispelFilter() then
			specwarnVeilShadow:Show(args.destName)
			specwarnVeilShadow:Play("dispelnow")
		end
	elseif args.spellId == 22667 then
		specwarnShadowCommand:Show(args.destName)
		specwarnShadowCommand:Play("findmc")
	end
end


function mod:PARTY_KILL(args)
	local guid = args.destGUID
	local cid = self:GetCIDFromGUID(guid)
	if cid == 14264 or cid == 14263 or cid == 14261 or cid == 14265 or cid == 14262 or cid == 14302 then--Red, Bronze, Blue, Black, Green, Chromatic
		if not addsGuidCheck[guid] then
			addsGuidCheck[guid] = true
			self.vb.addLeft = self.vb.addLeft - 1
			--40, 35, 30, 25, 20, 15, 12, 9, 6, 3
			if self.vb.addLeft >= 15 and (self.vb.addLeft % 5 == 0) or self.vb.addLeft >= 1 and (self.vb.addLeft % 3 == 0) and self.vb.addLeft < 15 then
				WarnAddsLeft:Show(self.vb.addLeft)
			end
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if UnitHealth(uId) / UnitHealthMax(uId) <= 0.25 and self:GetUnitCreatureId(uId) == 11583 and self.vb.phase < 2.5 then
		warnPhase3Soon:Show()
		self:SetStage(2.5)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellDK or msg:find(L.YellDK) then--This mod will likely persist all the way til Classic WoTLK, don't remove DK
		self:SendSync("ClassCall", "DEATHKNIGHT")
	elseif (msg == L.YellDruid or msg:find(L.YellDruid)) and self:AntiSpam(5, "ClassCall") then
		self:SendSync("ClassCall", "DRUID")
	elseif (msg == L.YellHunter or msg:find(L.YellHunter)) and self:AntiSpam(5, "ClassCall")  then
		self:SendSync("ClassCall", "HUNTER")
	elseif (msg == L.YellWarlock or msg:find(L.YellWarlock)) and self:AntiSpam(5, "ClassCall")  then
		self:SendSync("ClassCall", "WARLOCK")
	elseif (msg == L.YellMage or msg:find(L.YellMage)) and self:AntiSpam(5, "ClassCall")  then
		self:SendSync("ClassCall", "MAGE")
	elseif (msg == L.YellPaladin or msg:find(L.YellPaladin)) and self:AntiSpam(5, "ClassCall")  then
		self:SendSync("ClassCall", "PALADIN")
	elseif (msg == L.YellPriest or msg:find(L.YellPriest)) and self:AntiSpam(5, "ClassCall")  then
		self:SendSync("ClassCall", "PRIEST")
	elseif (msg == L.YellRogue or msg:find(L.YellRogue)) and self:AntiSpam(5, "ClassCall")  then
		self:SendSync("ClassCall", "ROGUE")
	elseif (msg == L.YellShaman or msg:find(L.YellShaman)) and self:AntiSpam(5, "ClassCall")  then
		self:SendSync("ClassCall", "SHAMAN")
	elseif (msg == L.YellWarrior or msg:find(L.YellWarrior)) and self:AntiSpam(5, "ClassCall")  then
		self:SendSync("ClassCall", "WARRIOR")
	elseif msg == L.YellP2 or msg:find(L.YellP2) then
		self:SendSync("Phase", 2)
	elseif msg == L.YellP3 or msg:find(L.YellP3) then
		self:SendSync("Phase", 3)
	end
end

do
	local playerClass = UnitClass("player")

	function mod:OnSync(msg, arg)
		if self:AntiSpam(5, msg) then
			--Do nothing, this is just an antispam threshold for syncing
		end
		if msg == "Phase" and arg then
			local phase = tonumber(arg) or 0
			if phase == 2 then
				self:SetStage(2)
				timerShadowblinkCD:Stop()
				timerSilenceCD:Stop()
				timerSBVolleyCD:Stop()
				timerMindControlCD:Stop()
				timerPhase:Start(15)--15 til encounter start fires, not til actual land?
				timerShadowFlameCD:Start(27)
				timerFearNext:Start(40)
				timerClassCall:Start(45)
			elseif phase == 3 then
				self:SetStage(3)
			end
			warnPhase:Show(DBM_CORE_L.AUTO_ANNOUNCE_TEXTS.stage:format(arg))
		end
		if not self:IsInCombat() then return end
		if msg == "ClassCall" and arg then
			local className = LOCALIZED_CLASS_NAMES_MALE[arg]
			if playerClass == className then
				specwarnClassCall:Show()
				specwarnClassCall:Play("targetyou")
			else
				warnClassCall:Show(className)
			end
			timerClassCall:Start(30, className)
		end
	end
end
