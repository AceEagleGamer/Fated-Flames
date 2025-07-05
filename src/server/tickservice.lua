--[[

    serves as the "heartbeat" of the game. this will dictate when a "unit" of time has passed, allowing for things like
    regen of stuff or possible status effects to occur over time.

    not sure what other use cases this could get but this is here because why not.

    tickspeed: 20/s?

]]

--- Private Variables
local UpdateEvent = nil

--- Public Variables ---
local TickService = {}
TickService.CurrentTickThread = nil
TickService.context = nil

-- configs
TickService.DesiredTPS = 20
TickService.LastTick = time()
TickService.CurrentTPS = 20 -- analytics case

-- references
TickService.Update = nil

--- Public Functions ---
function TickService:Init(context)
    self.context = context

    -- set up events
    UpdateEvent = Instance.new("BindableEvent")
    self.Update = UpdateEvent.Event -- set to readonly

    -- setup loop
    local TickWaitTime = 1 / self.DesiredTPS
    TickService.CurrentTickThread = task.spawn(function()
        while true do
            task.wait(TickWaitTime)
            local currentTick = time()
            
            -- fire the event
            local dt = currentTick - self.LastTick
            UpdateEvent:Fire(dt)

            -- update last tick
            self.LastTick = currentTick

            -- analytics
            TickService.CurrentTPS = 1 / dt
        end
    end)
end

function TickService:Start()

end

return TickService