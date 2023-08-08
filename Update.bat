@echo off
title Sam's Valor Scripts Update

set "source=Y:\qc17\Process Engineering\DFx GROUP\NPI & DFx Sam Miles\Valor\Valor Scripts"
set "destination=C:\MentorGraphics\Scripts"

echo Copying files from %source% to %destination%...

xcopy "%source%" "%destination%" /S /I /Y

set "source=Y:\qc17\Process Engineering\DFx GROUP\NPI & DFx Sam Miles\Valor\Settings"
set "destination=C:\MentorGraphics\Valor\vNPI_HOME\.genesis"

echo Copying files from %source% to %destination%...

xcopy "%source%" "%destination%" /S /I /Y

set "source=Y:\qc17\Process Engineering\DFx GROUP\NPI & DFx Sam Miles\Valor\ERFS"
set "destination=C:\MentorGraphics\ERFS"

echo Copying files from %source% to %destination%...

xcopy "%source%" "%destination%" /S /I /Y

pasue
echo File copy complete.
