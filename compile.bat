@echo off

set SOURCEDIR=src
set SMINCLUDES=env\include
set BUILDDIR=build
set SPCOMP=env\win32\bin\spcomp-1.7.0.exe
set VERSIONDUMP=updateversion.bat

:: Dump version and revision information first.
echo Updating version and revision info...
start /wait %VERSIONDUMP%

:: Make build directory.
if not exist "%BUILDDIR%" (
    mkdir %BUILDDIR%
)

:: Compile.
echo Starting compiler:
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zombiereloaded.smx %SOURCEDIR%\zombiereloaded.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/core_zombieplague.smx %SOURCEDIR%\core_zombieplague.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_100hp.smx %SOURCEDIR%\zp_100hp.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_250hp.smx %SOURCEDIR%\zp_250hp.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_antidote.smx %SOURCEDIR%\zp_antidote.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_barrel.smx %SOURCEDIR%\zp_barrel.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_bomb_antidote.smx %SOURCEDIR%\zp_bomb_antidote.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_doublejump.smx %SOURCEDIR%\zp_doublejump.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_escudo.smx %SOURCEDIR%\zp_escudo.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_flametrower.smx %SOURCEDIR%\zp_flametrower.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_fury.smx %SOURCEDIR%\zp_fury.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_givecredits.smx %SOURCEDIR%\zp_givecredits.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_goldendeagle.smx %SOURCEDIR%\zp_goldendeagle.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_goldenm249.smx %SOURCEDIR%\zp_goldenm249.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_infiniteammo.smx %SOURCEDIR%\zp_infiniteammo.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_invisibility.smx %SOURCEDIR%\zp_invisibility.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_kamikaze.smx %SOURCEDIR%\zp_kamikaze.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_knifebomb.smx %SOURCEDIR%\zp_knifebomb.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_minigun.smx %SOURCEDIR%\zp_minigun.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_setcredits.smx %SOURCEDIR%\zp_setcredits.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_throwingknives.smx %SOURCEDIR%\zp_throwingknives.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_velocity.smx %SOURCEDIR%\zp_velocity.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_viewcredits.smx %SOURCEDIR%\zp_viewcredits.sp
%SPCOMP% -i%SOURCEDIR% -i%SOURCEDIR%/include -i%SMINCLUDES% -o%BUILDDIR%/zp_wincredits.smx %SOURCEDIR%\zp_wincredits.sp

echo Compiling done. This script is looped, close if you're done.
pause

compile.bat
