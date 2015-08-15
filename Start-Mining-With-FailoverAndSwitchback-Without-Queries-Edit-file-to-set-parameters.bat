@setlocal enabledelayedexpansion
@echo off

Echo Welcome to FailoverAndSwitchback

set etherAddress=0x2d96cefbdec4c5a6ea88d9496fdeddefa561adcd
set miningDifficulty=5
set farmRecheckValue=5000

Echo %DATE% %TIME% Shutting down any active Geth node or ethminer instance to prevent conflicts | batchTee FailoverAndSwitchbackHistoryLog.txt +
taskkill /f /im geth.exe >nul 2>&1
taskkill /f /im ethminer.exe >nul 2>&1
Echo %DATE% %TIME% Starting Geth node to update blockchain so it is prepared for local ethmining if us1.Ethpool.org goes down | batchTee FailoverAndSwitchbackHistoryLog.txt +
Start /MIN "Geth" "geth"  --autodag -rpc --maxpeers 128 console 2>>geth.log 

set ipaddr=us1.ethpool.org

:start
ping -n 6 127.0.0.1 >nul: 2>nul:
set state=down
for /f "tokens=5,7" %%a in ('ping -n 1 !ipaddr!') do (
    	if "x%%a"=="xReceived" if "x%%b"=="x1," set state=up
	)
if "%state%"=="up" (
	taskkill /f /im "ethminer.exe" >nul 2>&1
	timeout /t 1 /nobreak 1>NUL
	taskkill /F /FI "WindowTitle eq  Administrator: ethminer" /T 1>NUL
	Echo %DATE% %TIME% Started Ethminer on EthPool | batchTee FailoverAndSwitchbackHistoryLog.txt +
	Start "ethminer" "ethminer.exe" -F http://us1.ethpool.org/miner/%etherAddress%/%miningDifficulty% --farm-recheck %farmRecheckValue% -G -t 6 
	:loopStillUpCheck
	ping -n 6 127.0.0.1 >nul: 2>nul:
	set state=down
	for /f "tokens=5,7" %%a in ('ping -n 1 us1.ethpool.org') do (
    		if "x%%a"=="xReceived" if "x%%b"=="x1," set state=up
		)
	if "%state%"=="down" (
		Echo %DATE% %TIME% Ethpool down.  Checking to see if I should switch to local Geth node ethmining. | batchTee FailoverAndSwitchbackHistoryLog.txt +
		goto start
		)
	goto loopStillUpCheck
	)
if "%state%"=="down" (
	taskkill /f /im "ethminer.exe" >nul 2>&1
	timeout /t 1 /nobreak 1>NUL
	taskkill /F /FI "WindowTitle eq  Administrator: ethminer" /T 1>NUL
	Echo %DATE% %TIME% Started Ethminer on your Local Geth node  | batchTee FailoverAndSwitchbackHistoryLog.txt +
	Start "ethminer" "ethminer.exe" -G -t 6 
	:loopStillDownCheck
	ping -n 6 127.0.0.1 >nul: 2>nul:
	set state=down
	for /f "tokens=5,7" %%a in ('ping -n 1 us1.ethpool.org') do (
    		if "x%%a"=="xReceived" if "x%%b"=="x1," set state=up
		)	
	if "%state%"=="up" (
		Echo %DATE% %TIME% Ethpool up. Checking to see if I should switch to ethpool ethmining. | batchTee FailoverAndSwitchbackHistoryLog.txt +
		goto start
		)
	goto loopStillDownCheck
	)
endlocal

