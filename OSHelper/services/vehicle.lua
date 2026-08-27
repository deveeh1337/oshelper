function plusWLoop()
    while true do
        if checkboxes.plusw[0]
            and sampGetGamestate() == 3
            and isCharOnAnyBike(playerPed)
            and not sampIsChatInputActive()
            and not sampIsDialogActive()
            and not isSampfuncsConsoleActive()
            and isKeyDown(0x57) then

            local car = storeCarCharIsInNoSave(playerPed)
            if car and doesVehicleExist(car) then
                local model = getCarModel(car)

                if bike[model] then
                    setGameKeyState(16, 255)
                    wait(50)
                    setGameKeyState(16, 0)
                elseif moto[model] then
                    setGameKeyState(1, -128)
                    wait(50)
                    setGameKeyState(1, 0)
                end
            end
        end
        wait(0)
    end
end
