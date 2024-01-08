-- @field #RANGE
SEAD_RANGE = {
    ClassName = "SEAD_RANGE",
    Debug = false,
    verbose = 0,
    id = nil,
    rangename = nil,
    location = nil,
    messages = true,
    Tmsg = 30,
    examinergroupname = nil,
    examinerexclusive = nil,
    instructorfreq = nil,
    instructor = nil,
    rangecontrolfreq = nil,
    rangecontrol = nil,

    coalition = nil,
    fox = nil,
    iads = nil,
    menus = { main = nil, sites = nil},
    spawners = {},
    sites = {},
    templates = {},
    support_categories = {},
    threat_categories = {},
    zones = {
      boundary = nil,
      spawn = nil
    }
  }


  --- Global list of all defined range names.
  -- @field #table Names
  SEAD_RANGE.Names = {}
  
  --- Main radio menu on group level.
  -- @field #table MenuF10 Root menu table on group level.
  SEAD_RANGE.MenuF10 = {}
  
  --- Main radio menu on mission level.
  -- @field #table MenuF10Root Root menu on mission level.
  SEAD_RANGE.MenuF10Root = nil
  
  --- Range script version.
  -- @field #string version
  SEAD_RANGE.version = "0.1.0"


  --- RANGE contructor. Creates a new RANGE object.
  -- @param #RANGE self
  -- @param #string RangeName Name of the range. Has to be unique. Will we used to create F10 menu items etc.
  -- @return #RANGE RANGE object.
  function SEAD_RANGE:New( RangeName, Coalition )
  
    -- Inherit BASE.
    local self = BASE:Inherit( self, FSM:New() ) -- #RANGE
  
    -- Get range name.
    self.rangename = RangeName or "SEAD Range"
  
    -- Set Coalition
    self.coalition = Coalition or coalition.side.BLUE

    -- Log id.
    self.log_id = string.format( "SEAD RANGE %s | ", self.rangename )
  
    -- Set Main Menu
    self.menus.main = MENU_COALITION:New( self.coalition, self.rangename, nil )
    self.menus.sites = MENU_COALITION:New( self.coalition, "Edit Existing Site", self.menus.main)
    MENU_COALITION_COMMAND:New(self.coalition, "Clear Range", self.menus.main, SEAD_RANGE._ClearRange, self)

    -- Debug info.
    --local text = string.format( "Script version %s - creating new RANGE object %s.", SEAD_RANGE.version, self.rangename )
    --self:I( self.id .. text )
  
    -- Defaults
    --self:SetDefaultPlayerSmokeBomb()
  
    -- Start State.
    self:SetStartState( "Stopped" )
  
    ---
    -- Add FSM transitions.
    --                 From State   -->   Event        -->     To State
    self:AddTransition("Stopped",         "Start",             "Running")     -- Start RANGE script.
    self:AddTransition("*",               "Status",            "*")           -- Status of RANGE script.
  
    ------------------------
    --- Pseudo Functions ---
    ------------------------
  
    --- Triggers the FSM event "Start". Starts the SEAD_RANGE. Initializes parameters and starts event handlers.
    -- @function [parent=#RANGE] Start
    -- @param #RANGE self
    -- Return object.
    return self
  end

--- Initializes number of targets and location of the range. Starts the event handlers.
-- @param #RANGE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SEAD_RANGE:onafterStart()

  -- Starting range.
  local text = string.format( "Starting SEAD_RANGE %s.", self.rangename)
  self:I( self.log_id .. text )

  -- Init Categories
  if next(self.threat_categories) == nil then
    self:SetThreatCategories("EW", "STRATSAM", "TACSAM", "ADA", "MANPAD")
  end

  -- Init New Site Sub-menus
  for _,cat in pairs(self.threat_categories) do
    local _menu_name = "New " .. cat .. " Site" 
    MENU_COALITION:New( self.coalition, _menu_name, self.menus.main)
  end 

  -- Init Fox Trainer
  if self.fox ~= nil then
    local _start_active = self.fox
    MENU_COALITION_COMMAND:New(self.coalition, "Toggle Missile Trainer", self.menus.main, SEAD_RANGE._ToggleMissileTrainerActive, self)

    self.fox = FOX:New()
    self.fox:AddSafeZone(self.zones.boundary)
    self.zones.spawn:ForEachZone(
      function(zone)
        self.fox:AddLaunchZone(zone)
      end
    )
    if _start_active then self.fox:Start() end
  end

  -- Register Templates
  for _,val in ipairs(self.templates) do
    self:_RegisterTemplate(val.template, val.name, val.cat)
  end

  -- Define a MOOSE zone of the range.
  ---if self.rangezone == nil then
   -- self.rangezone = ZONE_RADIUS:New( self.rangename, { x = self.location.x, y = self.location.z }, self.rangeradius )
  --end


  -- Event handling.
  --self:HandleEvent( EVENTS.Birth )
  --self:HandleEvent( EVENTS.Hit )
  --self:HandleEvent( EVENTS.Shot )

  --[[
  --Init range control.
  if self.rangecontrolfreq and not self.useSRS then

    -- Radio queue.
    self.rangecontrol = RADIOQUEUE:New( self.rangecontrolfreq, nil, self.rangename )
    self.rangecontrol.schedonce = true

    -- Set location where the messages are transmitted from.
    --self.rangecontrol:SetSenderCoordinate( self.location )
    --self.rangecontrol:SetSenderUnitName( self.rangecontrolrelayname )

    -- Start range control radio queue.
    self.rangecontrol:Start( 1, 0.1 )

    -- Init range control.
    if self.instructorfreq and not self.useSRS then

      -- Radio queue.
      self.instructor = RADIOQUEUE:New( self.instructorfreq, nil, self.rangename )
      self.instructor.schedonce = true

      -- Init numbers.
      self.instructor:SetDigit( 0, RANGE.Sound.IR0.filename, RANGE.Sound.IR0.duration, self.soundpath )
      self.instructor:SetDigit( 1, RANGE.Sound.IR1.filename, RANGE.Sound.IR1.duration, self.soundpath )
      self.instructor:SetDigit( 2, RANGE.Sound.IR2.filename, RANGE.Sound.IR2.duration, self.soundpath )
      self.instructor:SetDigit( 3, RANGE.Sound.IR3.filename, RANGE.Sound.IR3.duration, self.soundpath )
      self.instructor:SetDigit( 4, RANGE.Sound.IR4.filename, RANGE.Sound.IR4.duration, self.soundpath )
      self.instructor:SetDigit( 5, RANGE.Sound.IR5.filename, RANGE.Sound.IR5.duration, self.soundpath )
      self.instructor:SetDigit( 6, RANGE.Sound.IR6.filename, RANGE.Sound.IR6.duration, self.soundpath )
      self.instructor:SetDigit( 7, RANGE.Sound.IR7.filename, RANGE.Sound.IR7.duration, self.soundpath )
      self.instructor:SetDigit( 8, RANGE.Sound.IR8.filename, RANGE.Sound.IR8.duration, self.soundpath )
      self.instructor:SetDigit( 9, RANGE.Sound.IR9.filename, RANGE.Sound.IR9.duration, self.soundpath )

      -- Set location where the messages are transmitted from.
      self.instructor:SetSenderCoordinate( self.location )
      self.instructor:SetSenderUnitName( self.instructorrelayname )

      -- Start instructor radio queue.
      self.instructor:Start( 1, 0.1 )

    end

  end
  --]]

  self:__Status( -60 )
end

function SEAD_RANGE:AddSpawnZone(...)
  local _args = {...}
  if self.zones.spawn == nil then self.zones.spawn = SET_ZONE:New() end
  for _,zone in ipairs(_args) do
    if type(zone) == "string" then
      zone = ZONE:FindByName(zone)
    end
    if zone.ZoneName ~= nil then
      self.zones.spawn:AddZone(zone)
    end
  end
  return self
end

function SEAD_RANGE:AddTemplate( template_name, menu_name, category)
  table.insert(self.templates, {template = template_name, name = menu_name, cat = category})
  return self
end

function SEAD_RANGE:AddMissileTrainer(active_at_start)
  active_at_start = active_at_start or false
  self.fox = active_at_start
  return self
end

function SEAD_RANGE:EnableSkynetIADS(include_menu)
  self.iads = SkynetIADS:create(self.rangename)
  if include_menu == true then
    local iadsMenu = MENU_COALITION:New(self.coalition, "IADS Info", self.menus.main)
    MENU_COALITION_COMMAND:New(self.coalition, 'show IADS Status', iadsMenu, SkynetIADS.updateDisplay, {self = self.iads, value = true, option = 'IADSStatus'})
    MENU_COALITION_COMMAND:New(self.coalition, 'hide IADS Status', iadsMenu, SkynetIADS.updateDisplay, {self = self.iads, value = false, option = 'IADSStatus'})
    MENU_COALITION_COMMAND:New(self.coalition, 'show contacts', iadsMenu, SkynetIADS.updateDisplay, {self = self.iads, value = true, option = 'contacts'})
    MENU_COALITION_COMMAND:New(self.coalition, 'hide contacts', iadsMenu, SkynetIADS.updateDisplay, {self = self.iads, value = false, option = 'contacts'})
  end
  return self
end

function SEAD_RANGE:SetRangeZone(zone)
  if type(zone) == "string" then
    zone = ZONE:FindByName(zone)
  end
  if zone.ZoneName ~= nil then
    self.zones.boundary = zone
  end
end

function SEAD_RANGE:SetSupportCategories(...)
  local _args = {...}
  for _,arg in ipairs(_args) do
      self.support_categories[arg] = arg
  end
  return self
end

function SEAD_RANGE:SetThreatCategories(...)
  local _args = {...}
  for _,arg in ipairs(_args) do
      self.threat_categories[arg] = arg
  end
  return self
end

function SEAD_RANGE:_AddSiteMenu( PriSiteName )
  local SiteMenu = MENU_COALITION:New(self.coalition, PriSiteName, self.menus.sites)
  MENU_COALITION_COMMAND:New(self.coalition, "Respawn", SiteMenu, SEAD_RANGE._RespawnSite, self, PriSiteName) 
  MENU_COALITION_COMMAND:New(self.coalition, "Remove", SiteMenu, SEAD_RANGE._RemoveSite, self, PriSiteName) 

  if self.iads ~= nil then 
    local behavior_menu = MENU_COALITION:New(self.coalition, "Modify Site Behavior", SiteMenu)

    -- Behavior Menu 
    function toggle_autonomous_emcon_doctrine(PriSiteName) 
        iads_site = self.iads:getSAMSiteByGroupName(PriSiteName)
        if (iads_site:getAutonomousBehaviour() == SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK) then
            iads_site:setAutonomousBehaviour(SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DCS_AI)
            MESSAGE:New(PriSiteName.." set to ACTIVE when AUTONOMOUS",15,Info):ToAll()
        else
            iads_site:setAutonomousBehaviour(SkynetIADSAbstractRadarElement.AUTONOMOUS_STATE_DARK)
            MESSAGE:New(PriSiteName.." set to EMCON when AUTONOMOUS",15,Info):ToAll()
      end 
        iads_site:setToCorrectAutonomousState()
    end
    function toggle_integration_state(PriSiteName) 
        iads_site = self.iads:getSAMSiteByGroupName(PriSiteName)
        if (iads_site:getAutonomousState()) then
            iads_site:setToCorrectAutonomousState()
            MESSAGE:New(PriSiteName.." is now INTEGRATED",15,Info):ToAll()
        else 
            iads_site:goAutonomous()
            MESSAGE:New(PriSiteName.." is now AUTONOMOUS",15,Info):ToAll()
        end
    end
    function toggle_act_as_ew(PriSiteName) 
        iads_site = self.iads:getSAMSiteByGroupName(PriSiteName)
        if (iads_site:getActAsEW()) then
            iads_site:setActAsEW(false)
            MESSAGE:New(PriSiteName.." is NOT acting as EW",15,Info):ToAll()
        else 
            iads_site:setActAsEW(true)
            MESSAGE:New(PriSiteName.." is acting as EW",15,Info):ToAll()
        end
    end
    MENU_COALITION_COMMAND:New(self.coalition, "Toggle Autonomous Behavior", behavior_menu, toggle_autonomous_emcon_doctrine, PriSiteName) 
    MENU_COALITION_COMMAND:New(self.coalition, "Toggle Integration State", behavior_menu, toggle_integration_state, PriSiteName) 
    MENU_COALITION_COMMAND:New(self.coalition, "Toggle Acting as EW", behavior_menu, toggle_act_as_ew, PriSiteName) 
  end
  
  for label,cat in pairs(self.support_categories) do
    BASE:E(label .. ", " .. cat)
    local menu_name = "Add " .. label
    local _cat_menu1 = MENU_COALITION:New(self.coalition, menu_name, SiteMenu)
    for i,val in ipairs(self.templates) do
      if string.find(cat, val.cat) ~= nil then
        local _spawner_name = string.gsub(val.name, "[%s|-]", "_")
        if _cat_menu1.MenuCount < 9 then
          MENU_COALITION_COMMAND:New(self.coalition, val.name, _cat_menu1, SEAD_RANGE._SpawnSecondary, self, PriSiteName, _spawner_name, 66)
        else 
          local _cat_menu2 _cat_menu1:GetMenu("More...")
          if _cat_menu2 == nil then 
            _cat_menu2 = MENU_COALITION:New(self.coalition, "More...", _cat_menu1)
          end
          if _cat_menu2.MenuCount < 9 then
            MENU_COALITION_COMMAND:New(self.coalition, val.name, _cat_menu2, SEAD_RANGE._SpawnSecondary, self, PriSiteName, _spawner_name, 66)
          else
            local _cat_menu3 _cat_menu2:GetMenu("More...")
            if _cat_menu3 == nil then 
              _cat_menu3 = MENU_COALITION:New(self.coalition, "More...", _cat_menu2)
            end
            if _cat_menu3.MenuCount < 9 then
              MENU_COALITION_COMMAND:New(self.coalition, val.name, _cat_menu3, SEAD_RANGE._SpawnSecondary, self, PriSiteName, _spawner_name, 66)
            else 
              local _cat_menu4 _cat_menu3:GetMenu("More...")
              if _cat_menu4 == nil then 
                _cat_menu4 = MENU_COALITION:New(self.coalition, "More...", _cat_menu3)
              end
              if _cat_menu4.MenuCount < 10 then
                MENU_COALITION_COMMAND:New(self.coalition, val.name, _cat_menu4, SEAD_RANGE._SpawnSecondary, self, PriSiteName, _spawner_name, 66)
              else  
                self:E("You've reached you limit of types within the " .. category .. "category")
              end
            end
          end
        end
      end
    end
  end
end

function SEAD_RANGE:_ClearRange()
  for _,set in pairs(self.sites) do
    set:GetFirst():GetName()
    self:_RemoveSite(set:GetFirst():GetName())
  end 
end
  
function SEAD_RANGE:_GetSystemRange(group)
  local n = group:GetSize()
  local radar_count = 0
  local tel_count = 0
  local max_ammo_range = 0
  local max_radar_range = 0
  for i=1,n do
      local unit = group:GetUnit(i)
      if (unit:GetUnitCategory() == 2) then -- is a ground unit
          local unit_sensors = unit:GetSensors()
          local unit_weaps = unit:GetAmmo()
          if unit_weaps ~= nil then 
              for w=1,#unit_weaps do
                  if unit_weaps[w]["desc"]["category"] == Weapon.Category.MISSILE then
                  max_ammo_range =  math.max(max_ammo_range, unit_weaps[w]["desc"]["rangeMaxAltMax"])
                  elseif unit_weaps[w]["desc"]["category"] == Weapon.Category.SHELL then 
                  max_ammo_range =  5000
                  end
              end
          end
          if unit_sensors ~= nil then 
              for s=1,#unit_sensors do
                  if unit_sensors[s][1]["type"] == 1 then
                      max_radar_range = math.max(max_radar_range, unit_sensors[s][1]["detectionDistanceAir"]["upperHemisphere"]["headOn"])
                  end
              end
          end
      end
  end
  return {max_radar_range, max_ammo_range}
end
  
function SEAD_RANGE:_RegisterTemplate(template_name, menu_name, category)
    if self.threat_categories[category] == nil then
      self:E( self.log_id .. "ERROR: Invalid threat category" .. template_name .. "not added")
    else
      local _alias = self.rangename .. category .. menu_name .. "-"
      local _spawner_name = string.gsub(menu_name, "[%s|-]", "_")
      local _cat_menu1 = self.menus.main:GetMenu(string.format("New " .. category .. " Site"))
      
      self.spawners[_spawner_name] = SPAWN:NewWithAlias(template_name, _alias):InitLimit(0,0):InitAIOn():InitCoalition(self.coalition)
      if _cat_menu1.MenuCount < 9 then
        MENU_COALITION_COMMAND:New(self.coalition, menu_name, _cat_menu1, SEAD_RANGE._SpawnPrimary, self, _spawner_name)
      else
        local _cat_menu2 _cat_menu1:GetMenu("More...")
        if _cat_menu2 == nil then 
          _cat_menu2 = MENU_COALITION:New(self.coalition, "More...", _cat_menu1)
        end
        if _cat_menu2.MenuCount < 9 then
          MENU_COALITION_COMMAND:New(self.coalition, menu_name, _cat_menu2, SEAD_RANGE._SpawnPrimary, self, _spawner_name)
        else
          local _cat_menu3 _cat_menu2:GetMenu("More...")
          if _cat_menu3 == nil then 
            _cat_menu3 = MENU_COALITION:New(self.coalition, "More...", _cat_menu2)
          end
          if _cat_menu3.MenuCount < 9 then
            MENU_COALITION_COMMAND:New(self.coalition, menu_name, _cat_menu3, SEAD_RANGE._SpawnPrimary, self, _spawner_name)
          else 
            local _cat_menu4 _cat_menu3:GetMenu("More...")
            if _cat_menu4 == nil then 
              _cat_menu4 = MENU_COALITION:New(self.coalition, "More...", _cat_menu3)
            end
            if _cat_menu4.MenuCount < 10 then
              MENU_COALITION_COMMAND:New(self.coalition, menu_name, _cat_menu4, SEAD_RANGE._SpawnPrimary, self, _spawner_name)
            else  
              self:E("You've reached you limit of types within the " .. category .. "category")
            end
          end
        end
      end
    end
end
  
function SEAD_RANGE:_RemoveSite(site_name)
  local function destroy_group(grp)
      --if (self.iads ~= nil) then 
      --  self.iads:getSAMSiteByGroupName(grp:GetName()):cleanUp()
      --end
      grp:Destroy(false)

  end
  self.sites[site_name]:ForEachGroup(destroy_group)
  self.sites[site_name] = nil
  self.menus.sites:GetMenu(site_name):Remove()

end

function SEAD_RANGE:_RespawnSite(site_name)
  local function respawn(grp)
    grp:Respawn()
  end
  self.sites[site_name]:ForEachGroup(respawn)
end

function SEAD_RANGE:_SpawnPrimary(spawner_name)
  local _coal = coalition.side.RED
  if (self.coalition == _coal) then
    _coal = coalition.side.BLUE
  end
  local _zone = self.zones.spawn:GetRandomZone()
  self.spawners[spawner_name]:InitGroupHeading(40, 100):SpawnInZone(_zone, true  )
  
  local new_site = self.spawners[spawner_name]:GetLastAliveGroup()
  self.sites[new_site.GroupName] = SET_GROUP:New()
  self.sites[new_site.GroupName]:AddGroup(new_site)

  self:_AddSiteMenu(new_site.GroupName)

  if self.iads ~= nil then
    if new_site:HasAttribute("EWR") then 
      self.iads:addEarlyWarningRadar(new_site:GetUnit(1).UnitName) 
    --elseif new_site:HasAttribute("SAM CC") then
      --self.iads:addEarlyWarningRadar(new_site:GetUnit(1).UnitName) 

      --self.iads:addSAMSite(new_site.GroupName)
      --self.iads:getSAMSiteByGroupName(new_site.GroupName):setActAsEW(true)
    else --if new_site:HasAttribute("SAM") then
       self.iads:addSAMSite(new_site.GroupName)
    --else 
      --local text = string.format( "%s could not be mapped to a specific AD role for SkyNet", new_site.GroupName)
      --self:I( self.log_id .. text )
    end 
    self.iads:activate()
  end
  MESSAGE:New(new_site.GroupName.." Site Spawned",15,Info):ToAll()
end

function SEAD_RANGE:_SpawnSecondary(pri_site_name, spawner_name, max_dist_pcnt)
  max_dist_pcnt = max_dist_pcnt/100
  local pri_site = GROUP:FindByName(pri_site_name)
  local pri_site_rad =  300 --pri_site:GetBoundingRadius()
  local pri_site_coords = pri_site:GetCoordinate()      -- local get
  local template_group = GROUP:FindByName(self.spawners[spawner_name].SpawnTemplatePrefix)
  local max_ranges = self:_GetSystemRange(template_group)
  local max_spawn_radius = pri_site_rad * 3
  if (max_ranges[2] == 0) then 
      if (max_ranges[1] ~= 0) then 
          max_spawn_radius = max_ranges[1] * max_dist_pcnt
      end
  else max_spawn_radius = max_ranges[2] * max_dist_pcnt
  end
  local min_spawn_radius = math.max(pri_site_rad, max_spawn_radius * .3)
  self.spawners[spawner_name]
      :InitRandomizePosition(true, min_spawn_radius, max_spawn_radius)
      :InitGroupHeading(pri_site:GetHeading())
      :SpawnFromCoordinate(pri_site_coords)
  local new_component = self.spawners[spawner_name]:GetLastAliveGroup()
  self.sites[pri_site_name]:AddGroup(new_component)

  if self.iads ~= nil then
    if new_component:HasAttribute("EWR") then 
      self.iads:addEarlyWarningRadar(new_component:GetUnit(1).UnitName) 
    elseif new_component:HasAttribute("SAM CC") then
      self.iads:addEarlyWarningRadar(new_component:GetUnit(1).UnitName) 
      --self.iads:addSAMSite(new_component.GroupName)
      --self.iads:getSAMSiteByGroupName(new_component.GroupName):setActAsEW(true)
    else 
      --local text = string.format( "%s could not be mapped to a specific AD role for SkyNet", new_site.GroupName)
      --self:I( self.log_id .. text )
      local priSite = self.iads:getSAMSiteByGroupName(pri_site_name)
      self.iads:addSAMSite(new_component.GroupName)
      local supportSite = self.iads:getSAMSiteByGroupName(new_component.GroupName)
      if (priSite ~= nil and supportSite ~= nil) then 
        self.iads:getSAMSiteByGroupName(pri_site_name):addPointDefence(new_component.GroupName) 
      end
    end 
    self.iads:activate()

  end
  MESSAGE:New(new_component.GroupName.." site spawned supporting " .. pri_site_name,15,Info):ToAll()
end

function SEAD_RANGE:_ToggleMissileTrainerActive()
  local status = self.fox:GetState()
  
  if status == "Stopped" then
    self.fox:Start()
    MESSAGE:New(self.rangename .." Missile Trainer Enabled",15,Info):ToAll()
  elseif status == "Running" then 
    self.fox:Stop()
    MESSAGE:New(self.rangename .." Missile Trainer Disabled",15,Info):ToAll()
  end
end
