-- functions

-- [ online ] --
function time()
	startTime = os.time() -- "Точка отсчёта"
    connectingTime = 0
    while true do
        wait(1000)
        nowTime = os.date("%H:%M:%S", os.time())
        if sampGetGamestate() == 3 then 								--                      "Подключён к серверу" (                            ,      ,                        )
	        sesOnline[0] = sesOnline[0] + 1 								--                               
	        sesFull[0] = os.time() - startTime 							--                       
	        sesAfk[0] = sesFull[0] - sesOnline[0]							--              

	        cfg.onDay.online = cfg.onDay.online + 1 					--                             
	        cfg.onDay.full = dayFull[0] + sesFull[0] 						--                     
	        cfg.onDay.afk = cfg.onDay.full - cfg.onDay.online			--            
			
	    else
            connectingTime = connectingTime + 1                        --                            
	    	startTime = startTime + 1									--                                 
	    end
    end
end

function get_clock(time)
    -- During game startup some timers are not initialized yet.
    time = tonumber(time) or 0
    local timezone_offset = 86400 - tonumber(os.date('%H', 0)) * 3600
    if time >= 86400 then onDay = true else onDay = false end
    return os.date((onDay and math.floor(time / 86400)..'д ' or '')..'%H:%M:%S', time + timezone_offset)
end

-- [ online ] --
