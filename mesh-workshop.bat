@echo off

set confpath=%1
set nodename=%2
set HOSTNAMES="bathurst bayview bloor broadview chester christie college coxwell davisville donlands dufferin dundas dupont eglinton ellesmere finch greenwood islington jane keele kennedy king kipling lawrence leslie midland museum osgoode ossington pape queen rosedale runnymede spadina summerhill union warden wilson woodbine yorkdale"

rem Check required inputs
IF [%confpath%] == [] GOTO VARMISSING
IF [%confpath%] == [] GOTO VARMISSING
rem Make sure the node name is valid
if NOT exist custom\conf.d\%nodename%\30-mesh-workshop.tar.gz goto VARMISSING
rem Make sure destination is valid
if NOT exist %confpath%\ goto VARMISSING
GOTO VARNOTMISSING
:VARMISSING
  echo Usage:   mesh-workshop.sh confpath nodename
  echo Example: mesh-workshop.sh e:\conf.d\ bloor
  echo Hostnames available: %HOSTNAME
goto END
:VARNOTMISSING

xcopy /y /e shared\conf.d\* "%confpath%"
xcopy /y /e custom\conf.d\%nodename%\*.tar.gz "%confpath%"
echo Installed node profile %nodename to %confpath%

:END
