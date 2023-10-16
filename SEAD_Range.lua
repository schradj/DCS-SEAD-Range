-- @field #RANGE
SEAD_RANGE = {
    ClassName = "SEAD_RANGE",
    Debug = false,
    verbose = 0,
    id = nil,
    rangename = nil,
    location = nil,
    messages = true,
    rangeradius = 5000,
    rangezone = nil,
    MenuAddedTo = {},
    planes = {},
    PlayerSettings = {},
    Tmsg = 30,
    examinergroupname = nil,
    examinerexclusive = nil,
    strafemaxalt = 914,
    eventmoose = true,
    defaultsmokebomb = true,
    autosave = false,
    instructorfreq = nil,
    instructor = nil,
    rangecontrolfreq = nil,
    rangecontrol = nil,
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
  SEAD_RANGE.version = "2.5.0"


  --- RANGE contructor. Creates a new RANGE object.
  -- @param #RANGE self
  -- @param #string RangeName Name of the range. Has to be unique. Will we used to create F10 menu items etc.
  -- @return #RANGE RANGE object.
  function SEAD_RANGE:New( RangeName )
  
    -- Inherit BASE.
    local self = BASE:Inherit( self, FSM:New() ) -- #RANGE
  
    -- Get range name.
    -- TODO: make sure that the range name is not given twice. This would lead to problems in the F10 radio menu.
    self.rangename = RangeName or "SEAD Range"
  
    -- Log id.
    self.id = string.format( "SEAD RANGE %s | ", self.rangename )
  
    -- Debug info.
    local text = string.format( "Script version %s - creating new RANGE object %s.", SEAD_RANGE.version, self.rangename )
    self:I( self.id .. text )
  
    -- Defaults
    self:SetDefaultPlayerSmokeBomb()
  
    -- Start State.
    self:SetStartState( "Stopped" )
  
    ---
    -- Add FSM transitions.
    --                 From State   -->   Event        -->     To State
    self:AddTransition("Stopped",         "Start",             "Running")     -- Start RANGE script.
    self:AddTransition("*",               "Status",            "*")           -- Status of RANGE script.
    self:AddTransition("*",               "Impact",            "*")           -- Impact of bomb/rocket/missile.
  
    ------------------------
    --- Pseudo Functions ---
    ------------------------
  
    --- Triggers the FSM event "Start". Starts the SEAD_RANGE. Initializes parameters and starts event handlers.
    -- @function [parent=#RANGE] Start
    -- @param #RANGE self
    -- Return object.
    return self
  end

