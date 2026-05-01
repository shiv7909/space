@echo off
echo Installing notification icons...

:: Define source and destination
set SRC_BASE=D:\habitz\assets\res
set DST_BASE=D:\habitz\android\app\src\main\res

:: Copy for MDPI
echo Copying MDPI...
copy /Y "%SRC_BASE%\drawable-mdpi\ic_stat_s.png" "%DST_BASE%\drawable-mdpi\ic_notification.png"

:: Copy for HDPI
echo Copying HDPI...
copy /Y "%SRC_BASE%\drawable-hdpi\ic_stat_s.png" "%DST_BASE%\drawable-hdpi\ic_notification.png"

:: Copy for XHDPI
echo Copying XHDPI...
copy /Y "%SRC_BASE%\drawable-xhdpi\ic_stat_s.png" "%DST_BASE%\drawable-xhdpi\ic_notification.png"

:: Copy for XXHDPI
echo Copying XXHDPI...
copy /Y "%SRC_BASE%\drawable-xxhdpi\ic_stat_s.png" "%DST_BASE%\drawable-xxhdpi\ic_notification.png"

:: Copy for XXXHDPI
echo Copying XXXHDPI...
copy /Y "%SRC_BASE%\drawable-xxxhdpi\ic_stat_s.png" "%DST_BASE%\drawable-xxxhdpi\ic_notification.png"

:: Remove the old XML vector file so the new PNGs are used
echo Removing old XML file...
del "%DST_BASE%\drawable\ic_notification.xml"

echo.
echo ========================================================
echo ✅ SUCCESS! Icons installed to Android system folders.
echo You can now run your app.
echo ========================================================
pause

