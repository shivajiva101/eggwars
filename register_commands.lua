-- CHAT COMMANDS Definition
-- func has parameters, it receives @name and @param

local register_commands = {

    _init = function(ew)

        local _commands = {}

        if (ew == nil) then
            return { status = -1, message = "'ew' base not declared, commands will be useless" };
        end
        _commands[#_commands+1] = {
            cli = "register",
            body = {
                params = "",
                description = "Join match",
                func = ew.register_player
            }
        }

        _commands[#_commands+1] = {
            cli = "start",
            body = {
                params = "",
                description = "Starts the game",
                func = ew.begin_match
            }
        }

        _commands[#_commands+1] = {
            cli = "fakestart",
            body = {
                params = "",
                description = "[FAKE] Starts the game",
                func = ew.simulateStart
            }
        }

        _commands[#_commands+1] = {
            cli = "who",
            body = {
                params = "",
                description = "See players in match",
                func = ew.who_is_online
            }
        }
        -- Assign to main table
        ew.commands = _commands
        return {status = 0, message = "Ok"}
    end
}

return register_commands