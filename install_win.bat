@echo off
setlocal EnableExtensions DisableDelayedExpansion
title PixelArtistry Image-to-3D-Print installer
cd /d "%~dp0"

rem ===================================================================
rem  PixelArtistry Image-to-3D-Print installer
rem
rem  Put this file into your ComfyUI-Easy-Install folder (next to
rem  "python_embeded") or its "Add-ons" folder, and double-click it.
rem  Works for ComfyUI portable too.
rem  Safe to run again: everything is set back to the tested versions.
rem ===================================================================

set "SELF=%~f0"
set "ROOT=%~dp0"
rem  Also works from a subfolder such as Easy-Install's "Add-ons" folder
if not exist "%ROOT%python_embeded\python.exe" if exist "%~dp0..\python_embeded\python.exe" for %%I in ("%~dp0..") do set "ROOT=%%~fI\"
if not exist "%ROOT%python_embeded\python.exe" if exist "%~dp0..\..\python_embeded\python.exe" for %%I in ("%~dp0..\..") do set "ROOT=%%~fI\"
set "PY=%ROOT%python_embeded\python.exe"
set "COMFY=%ROOT%ComfyUI"
set "NODES=%COMFY%\custom_nodes"
set "MODELS=%COMFY%\models"
set "GH=Mstafa-awad"

rem -------------------------------------------------------------------
rem  Pinned versions: the exact commits tested for the video.
rem  To update one, paste its new FULL commit hash from GitHub below.
rem  To try the newest versions instead: open cmd, run
rem      set MOSTAAD_LATEST=1
rem  and start this file from that same window.
rem  To test the RTX 20/30/40 build on an RTX 50 card, run
rem      set MOSTAAD_MULTIGPU=1
rem  the same way. Run again without it to go back to the default build.
rem -------------------------------------------------------------------
set "PIN_DATE=2026-09-26"
set "SHA_WTIVO=fb9e9ea6a7deec965d3a4bf43ba7a4a9ff3856f3"
set "SHA_QUAD=74048b3415537e26cc72b46b082a010cd0e357ce"
set "SHA_CUMESH=c4edeb96bf637239cecb731d2869469a3025d742"
set "SHA_MEMCLEAN=3357282290278c96ffa0da180d43bc5eac5f2286"
set "SHA_LODTAILOR=3d25b7d4aa382fa5dac210eb5d8d0eadc4a4f183"
set "SHA_FASTMERGE=5392949165ceed1e74448b1949d6e0dc9b34dd92"
set "FAILS=0"
set "MISSING=0"
set "DL=0"

echo.
echo  PixelArtistry Image-to-3D-Print installer
echo  ========================================
echo  Folder: %ROOT%
echo.

if not exist "%PY%" goto :no_python
if not exist "%NODES%\" goto :no_python
curl --version >nul 2>&1
if errorlevel 1 goto :no_tools
tar --version >nul 2>&1
if errorlevel 1 goto :no_tools

rem  Stop if ComfyUI from this folder is still running - its files would be locked
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-Process python -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq [IO.Path]::GetFullPath($env:PY) }) { exit 3 }" >nul 2>&1
if "%errorlevel%"=="3" goto :comfy_running

rem -------------------------------------------------------------------
echo.
echo [1/8] Checking your environment
"%PY%" -c "import sys, torch; print('    Python', sys.version.split()[0], '| torch', torch.__version__, '| CUDA', torch.version.cuda)"
if errorlevel 1 goto :no_torch
"%PY%" -c "import torch; print('    GPU', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'none found')"

rem WTiVo's prebuilt backend needs exactly Python 3.12 + torch 2.8.0 + CUDA 12.8
"%PY%" -c "import sys, torch; sys.exit(0 if sys.version_info[:2] == (3, 12) and torch.__version__.startswith('2.8.0') and torch.version.cuda == '12.8' else 1)" >nul 2>&1
if errorlevel 1 (set "WT_ENV=0") else (set "WT_ENV=1")

rem GPU generation: 12 = RTX 50 (Blackwell), 7-9 = RTX 20/30/40, 0/1 = unknown
"%PY%" -c "import sys, torch; sys.exit(torch.cuda.get_device_capability(0)[0] if torch.cuda.is_available() else 0)" >nul 2>&1
set "CC=%errorlevel%"

set "HAVE_GIT="
git --version >nul 2>&1
if not errorlevel 1 set "HAVE_GIT=1"
set "OLD_COMFY="
if not exist "%COMFY%\comfy_extras\nodes_trellis2.py" set "OLD_COMFY=1"
if not exist "%COMFY%\comfy_extras\nodes_mesh_postprocess.py" set "OLD_COMFY=1"

rem -------------------------------------------------------------------
echo.
echo [2/8] Downloading / updating the node packs
call :fetch "WTiVo-WatertightVoxel-ComfyuiNode" "%NODES%" "%SHA_WTIVO%"
call :fetch "ComfyUI-Mesh-Quad-Reconstruct" "%NODES%" "%SHA_QUAD%"
call :fetch "ComfyUI-CuMesh-Decimate" "%NODES%" "%SHA_CUMESH%"
call :fetch "ComfyUI-Memory-Cleaner" "%NODES%" "%SHA_MEMCLEAN%"
call :fetch "LODTailor-The-Mesh-Trimmer-ComfyuiNode" "%NODES%" "%SHA_LODTAILOR%"
call :fetch "WTiVo-FastMergeByDistance" "%NODES%" "%SHA_FASTMERGE%"
if not "%FAILS%"=="0" goto :summary

rem -------------------------------------------------------------------
echo.
echo [3/8] Picking the WTiVo build for your GPU
set "WT=%NODES%\WTiVo-WatertightVoxel-ComfyuiNode"
set "WT_RAR=%WT%\build\ForNonBlackwellgpu(rtx50 and below).rar"
if defined MOSTAAD_MULTIGPU goto :wt_force
if %CC% GEQ 12 goto :wt_blackwell
if %CC% LEQ 1 goto :wt_unknown
echo     RTX 20/30/40 class GPU - installing the multi-GPU build
goto :wt_multi
:wt_force
echo     MOSTAAD_MULTIGPU is set - installing the multi-GPU build for testing
:wt_multi
if not exist "%WT_RAR%" goto :wt_norar
tar -xf "%WT_RAR%" -C "%WT%" >nul 2>&1
call :size "%WT%\build\cppmodules.cp312-win_amd64.pyd"
if %SIZE% GTR 20000000 goto :wt_extracted
if exist "%ProgramFiles%\7-Zip\7z.exe" "%ProgramFiles%\7-Zip\7z.exe" x -y -o"%WT%" "%WT_RAR%" >nul 2>&1
call :size "%WT%\build\cppmodules.cp312-win_amd64.pyd"
if %SIZE% GTR 20000000 goto :wt_extracted
echo     [WARN] Could not unpack the .rar automatically. Unpack this file by hand
echo            into the WTiVo node folder and overwrite the files in "build":
echo            %WT_RAR%
set "WT_RAR_TODO=1"
goto :wt_test
:wt_extracted
echo     Multi-GPU build installed
goto :wt_test
:wt_blackwell
echo     RTX 50 series - keeping the default build
goto :wt_test
:wt_unknown
echo     Could not detect the GPU - keeping the default build
goto :wt_test
:wt_norar
echo     [WARN] Multi-GPU archive not found in the repo - keeping the default build
:wt_test
"%PY%" -c "import sys; sys.path.insert(0, r'%WT%'); import torch, wtivo" >nul 2>&1
if errorlevel 1 (set "WT_OK=0") else (set "WT_OK=1")

rem -------------------------------------------------------------------
echo.
echo [4/8] Installing Python dependencies into python_embeded
"%PY%" -m pip install --disable-pip-version-check -q -r "%NODES%\WTiVo-FastMergeByDistance\requirements.txt"
"%PY%" "%NODES%\ComfyUI-Mesh-Quad-Reconstruct\install.py"
"%PY%" -c "import cumesh" >nul 2>&1
if errorlevel 1 (set "CUMESH_OK=0") else (set "CUMESH_OK=1")
rem FastMerge: native C++ DLL (fast) or Python fallback (slow)
set "FM=%NODES%\WTiVo-FastMergeByDistance"
"%PY%" -c "import sys; sys.path.insert(0, r'%FM%'); import native; sys.exit(0 if native.native_available() else 1)" >nul 2>&1
if errorlevel 1 (set "FM_OK=0") else (set "FM_OK=1")

rem -------------------------------------------------------------------
echo.
echo [5/8] Test run - WTiVo has to close a mesh with holes on your GPU
set "WT_RUN=0"
if not "%WT_OK%"=="1" goto :wt_run_skip
echo     This takes a moment...
"%PY%" -c "import sys; src = open(sys.argv[1], encoding='utf-8').read(); exec(src.split('#' + 'WTIVO_SELFTEST' + '#', 1)[1].split('#' + 'END' + '#', 1)[0])" "%SELF%" "%WT%"
if not errorlevel 1 set "WT_RUN=1"
goto :wt_run_done
:wt_run_skip
echo     Skipped - the WTiVo backend did not load
:wt_run_done

rem -------------------------------------------------------------------
echo.
echo [6/8] Installing the PixelArtistry workflows
set "WF=%COMFY%\user\default\workflows\PixelArtistry"
"%PY%" -c "import sys; src = open(sys.argv[1], encoding='utf-8').read(); exec(src.split('#' + 'WORKFLOWS' + '#', 1)[1].split('#' + 'END' + '#', 1)[0])" "%SELF%" "%WF%"
if errorlevel 1 (echo     [WARN] Could not write the workflows) else (echo     Workflows are in the sidebar under Workflows - PixelArtistry)
if not exist "%COMFY%\input\dragon_front.png" curl -sL --fail -o "%COMFY%\input\dragon_front.png" "https://raw.githubusercontent.com/pixelartistry/PixelArtistry-Image-to-3D-Print/main/examples/dragon_front.png"

rem -------------------------------------------------------------------
echo.
echo [7/8] Checking models in ComfyUI\models
set "GET_QWEN=0"
set "GET_MV=0"
echo     Optional: Qwen-Image 2.1 makes the front image from a text prompt - about 16 GB.
choice /c YN /n /m "    Install the image models? [Y/N] "
if not errorlevel 2 set "GET_QWEN=1"
echo     Optional: Multiview builds the back and sides first - about 5 GB more, plus the Qwen models above.
choice /c YN /n /m "    Install the multiview model? [Y/N] "
if not errorlevel 2 set "GET_MV=1"
if "%GET_MV%"=="1" set "GET_QWEN=1"
call :models
if "%MISSING%"=="0" goto :blender
echo.
if defined AUTO_DL goto :dl_auto
choice /c YN /n /m "    Download the %MISSING% missing model files now? [Y/N] "
if errorlevel 2 goto :blender
goto :dl_go
:dl_auto
if /i not "%AUTO_DL%"=="Y" goto :blender
:dl_go
set "DL=1"
set "MISSING=0"
call :models

rem -------------------------------------------------------------------
:blender
echo.
echo [8/8] Looking for Blender - LODTailor and Bake Forger need it
set "BLENDER="
for /f "delims=" %%B in ('where blender 2^>nul') do if not defined BLENDER set "BLENDER=%%B"
if not defined BLENDER for /d %%D in ("%ProgramFiles%\Blender Foundation\Blender*") do if exist "%%D\blender.exe" set "BLENDER=%%D\blender.exe"
if not defined BLENDER goto :no_blender
echo     Found: %BLENDER%
goto :summary
:no_blender
echo     Not found - install Blender from blender.org

rem -------------------------------------------------------------------
:summary
echo.
echo ============================ SUMMARY ============================
if defined MOSTAAD_LATEST goto :sum_latest
if defined NOT_PINNED goto :sum_notpinned
echo  [OK]   Versions pinned to the ones tested on %PIN_DATE%
goto :sum_versions_done
:sum_latest
echo  [INFO] Newest versions from GitHub - NOT the tested versions
goto :sum_versions_done
:sum_notpinned
echo  [WARN] Some packs could not be updated - they may not be the tested versions
:sum_versions_done
if "%WT_OK%"=="1" (echo  [OK]   WTiVo watertight backend loads) else (echo  [FAIL] WTiVo backend - needs Python 3.12 + torch 2.8.0+cu128 in python_embeded)
if defined WT_RAR_TODO echo  [TODO] Unpack the WTiVo multi-GPU .rar by hand, see step 3
if defined MOSTAAD_MULTIGPU echo  [INFO] Test mode: multi-GPU WTiVo build forced by MOSTAAD_MULTIGPU
if not "%WT_OK%"=="1" goto :sum_cumesh
if "%WT_RUN%"=="1" (echo  [OK]   WTiVo test run on your GPU - holes closed, mesh watertight) else (echo  [FAIL] WTiVo test run failed - see the output of step 5)
:sum_cumesh
if "%CUMESH_OK%"=="1" (echo  [OK]   CuMesh for Quad Reconstruct + Decimate) else (echo  [FAIL] CuMesh missing - install VisualBruno ComfyUI-Trellis2 first, see the README)
if "%FM_OK%"=="1" (echo  [OK]   FastMerge runs in fast native mode) else (echo  [WARN] FastMerge uses its slow Python mode - install the Microsoft Visual C++ Redistributable)
if defined OLD_COMFY echo  [FAIL] ComfyUI is too old for the core Trellis2 nodes - run the update .bat first
if not "%MISSING%"=="0" echo  [WARN] %MISSING% model files missing - links are listed in step 7
if defined BLENDER (echo  [OK]   Blender found: %BLENDER%) else (echo  [WARN] Blender not found - LODTailor and Bake Forger will not run)
if not "%FAILS%"=="0" echo  [FAIL] %FAILS% downloads failed - check your connection and run this again
echo.
echo  Next: start ComfyUI and open Workflows - PixelArtistry.
echo  In each workflow, paste your Blender path once into the purple
echo  "Blender path" node - a clean Blender without add-ons works best.
echo  Then load your own image in the "Load Image" node. The dragon example is
echo  already in ComfyUI\input.
echo.
pause
exit /b 0

rem ===================================================================
rem  Error exits
rem ===================================================================
:no_python
echo  [ERROR] python_embeded or ComfyUI\custom_nodes not found next to this file.
echo          Move this .bat into your ComfyUI-Easy-Install folder or its Add-ons folder.
pause
exit /b 1

:comfy_running
echo  [ERROR] ComfyUI is still running from this folder. Close it and run this again.
pause
exit /b 1

:no_tools
echo  [ERROR] curl.exe or tar.exe not found. You need Windows 10 1803 or newer.
pause
exit /b 1

:no_torch
echo  [ERROR] python_embeded has no working PyTorch. Install ComfyUI first.
pause
exit /b 1

rem ===================================================================
rem  :fetch REPO PARENT  - clone or update github.com/Mstafa-awad/REPO
rem  into PARENT\REPO. Uses git when available, otherwise the main zip.
rem ===================================================================
:fetch
set "R=%~1"
set "P=%~2"
set "D=%~2\%~1"
set "REF=%~3"
if defined MOSTAAD_LATEST set "REF=main"
echo     %R%
if exist "%D%.new\" rmdir /s /q "%D%.new"
if exist "%P%\%R%-main\" rmdir /s /q "%P%\%R%-main"
if exist "%P%\%R%-%REF%\" rmdir /s /q "%P%\%R%-%REF%"
if exist "%P%\%R%-main\" goto :fetch_locked
if not defined HAVE_GIT goto :fetch_zip
if not exist "%D%\.git\" goto :fetch_new
git -C "%D%" remote get-url origin >nul 2>&1
if errorlevel 1 goto :fetch_new
git -C "%D%" fetch -q --depth 1 origin %REF%
if errorlevel 1 goto :fetch_keep
git -C "%D%" reset -q --hard FETCH_HEAD
goto :fetch_verify
:fetch_keep
echo            [WARN] Could not download - keeping the version already installed
set "NOT_PINNED=1"
exit /b 0
:fetch_new
rem  Download into a temporary folder first, replace the old one only on success
git init -q "%D%.new"
git -C "%D%.new" remote add origin "https://github.com/%GH%/%R%.git"
git -C "%D%.new" fetch -q --depth 1 origin %REF%
if errorlevel 1 goto :fetch_new_failed
git -C "%D%.new" checkout -q FETCH_HEAD
if exist "%D%\" rmdir /s /q "%D%"
if exist "%D%\" goto :fetch_new_locked
ren "%D%.new" "%R%"
goto :fetch_verify
:fetch_new_failed
rmdir /s /q "%D%.new" 2>nul
goto :fetch_failed
:fetch_new_locked
rmdir /s /q "%D%.new" 2>nul
goto :fetch_locked
:fetch_zip
curl -sL --fail -o "%TEMP%\%R%.zip" "https://github.com/%GH%/%R%/archive/%REF%.zip"
if errorlevel 1 goto :fetch_failed
tar -xf "%TEMP%\%R%.zip" -C "%P%"
del /q "%TEMP%\%R%.zip" 2>nul
if not exist "%P%\%R%-%REF%\" goto :fetch_failed
if exist "%D%\" rmdir /s /q "%D%"
if exist "%D%\" goto :fetch_zip_locked
ren "%P%\%R%-%REF%" "%R%"
exit /b 0
:fetch_zip_locked
rmdir /s /q "%P%\%R%-%REF%" 2>nul
goto :fetch_locked
:fetch_verify
if defined MOSTAAD_LATEST exit /b 0
set "GOT="
for /f %%H in ('git -C "%D%" rev-parse HEAD 2^>nul') do set "GOT=%%H"
if /i "%GOT%"=="%REF%" exit /b 0
echo            [ERROR] Wrong version after download: %GOT%
set /a FAILS+=1
exit /b 1
:fetch_failed
if exist "%D%\" (echo            [ERROR] Download failed - the version already installed was kept) else (echo            [ERROR] Download failed)
set /a FAILS+=1
exit /b 1
:fetch_locked
echo            [ERROR] Folder is in use - close ComfyUI and run this again
set /a FAILS+=1
exit /b 1
:fetch_failed
echo            [ERROR] Download failed
if exist "%D%\" rmdir /s /q "%D%"
set /a FAILS+=1
exit /b 1
:fetch_locked
if not defined HAVE_GIT goto :fetch_fresh
if not exist "%D%\.git\" goto :fetch_fresh
git -C "%D%" reset -q --hard
git -C "%D%" pull -q --ff-only
if errorlevel 1 echo            [WARN] Update failed - keeping the current version
exit /b 0
:fetch_fresh
if exist "%D%\" rmdir /s /q "%D%"
if exist "%D%\" goto :fetch_locked
if defined HAVE_GIT (
    git clone -q --depth 1 "https://github.com/%GH%/%R%.git" "%D%"
) else (
    curl -sL --fail -o "%TEMP%\%R%.zip" "https://github.com/%GH%/%R%/archive/refs/heads/main.zip"
    tar -xf "%TEMP%\%R%.zip" -C "%P%"
    ren "%P%\%R%-main" "%R%"
    del /q "%TEMP%\%R%.zip" 2>nul
)
if exist "%D%\" exit /b 0
echo            [ERROR] Download failed
set /a FAILS+=1
exit /b 1
:fetch_locked
echo            [ERROR] Folder is in use - close ComfyUI and run this again
set /a FAILS+=1
exit /b 1

rem ===================================================================
rem  :size FILE  - sets SIZE to the file size in bytes, 0 if missing
rem ===================================================================
:size
set "SIZE=0"
if exist "%~1" set "SIZE=%~z1"
exit /b 0

rem ===================================================================
rem  :models - model list for the print workflows. The Qwen and multiview
rem  files are only handled when you said yes in step 7.
rem ===================================================================
:models
set "HF=https://huggingface.co"
call :model "diffusion_models" "trellis_2_int8_convrot.safetensors" "%HF%/Comfy-Org/TRELLIS.2/resolve/main/diffusion_models/trellis_2_int8_convrot.safetensors"
call :model "diffusion_models" "pixal3d_int8_convrot.safetensors" "%HF%/Comfy-Org/Pixal3D/resolve/main/diffusion_models/pixal3d_int8_convrot.safetensors"
call :model "vae" "trellis_2_shape_vae_bf16.safetensors" "%HF%/Comfy-Org/Pixal3D/resolve/main/vae/trellis_2_shape_vae_bf16.safetensors"
call :model "vae" "trellis_2_texture_vae_bf16.safetensors" "%HF%/Comfy-Org/Pixal3D/resolve/main/vae/trellis_2_texture_vae_bf16.safetensors"
call :model "clip_vision" "dino_v3_L_naf_fp32.safetensors" "%HF%/Comfy-Org/Pixal3D/resolve/main/clip_vision/dino_v3_L_naf_fp32.safetensors"
call :model "geometry_estimation" "moge_2_vitl_normal_fp16.safetensors" "%HF%/Comfy-Org/MoGe/resolve/main/geometry_estimation/moge_2_vitl_normal_fp16.safetensors"
call :model "background_removal" "birefnet.safetensors" "%HF%/Comfy-Org/BiRefNet/resolve/main/background_removal/birefnet.safetensors"
if "%GET_QWEN%"=="1" call :model "diffusion_models" "qwen_image_2.1_int8_convrot.safetensors" "%HF%/Comfy-Org/Qwen-Image-2.1/resolve/main/diffusion_models/qwen_image_2.1_int8_convrot.safetensors"
if "%GET_QWEN%"=="1" call :model "text_encoders" "qwen3vl_8b_int8_convrot.safetensors" "%HF%/Comfy-Org/Qwen-Image-2.1/resolve/main/text_encoders/qwen3vl_8b_int8_convrot.safetensors"
if "%GET_QWEN%"=="1" call :model "vae" "qwen_image_2.1_vae_bf16.safetensors" "%HF%/Comfy-Org/Qwen-Image-2.1/resolve/main/vae/qwen_image_2.1_vae_bf16.safetensors"
if "%GET_MV%"=="1" call :model "diffusion_models" "pixal3d_multiview_int8_convrot.safetensors" "%HF%/Comfy-Org/Pixal3D/resolve/main/diffusion_models/pixal3d_multiview_int8_convrot.safetensors"
exit /b 0

rem  :model FOLDER FILE URL
:model
set "MF=%MODELS%\%~1"
rem  Ask ComfyUI itself - covers models\unet, subfolders and extra_model_paths.yaml
"%PY%" -c "import sys; src = open(sys.argv[1], encoding='utf-8').read(); exec(src.split('#' + 'MODELCHECK' + '#', 1)[1].split('#' + 'END' + '#', 1)[0])" "%SELF%" "%ROOT%." "%~1" "%~2" "%DL%"
if errorlevel 1 goto :model_missing
exit /b 0
:model_missing
if "%DL%"=="1" goto :model_download
echo     MISSING   %~1\%~2
echo               %~3
set /a MISSING+=1
exit /b 0
:model_download
if not exist "%MF%\" mkdir "%MF%"
echo     Downloading %~1\%~2
curl -L --fail --retry 3 -# -o "%MF%\%~2.part" "%~3"
if errorlevel 1 goto :model_dl_fail
move /y "%MF%\%~2.part" "%MF%\%~2" >nul
exit /b 0
:model_dl_fail
echo     [ERROR] Download failed: %~3
del /q "%MF%\%~2.part" 2>nul
set /a FAILS+=1
set /a MISSING+=1
exit /b 0

rem ===================================================================
rem  Python self-test for step 5. cmd never runs the lines below; step 5
rem  reads them from this file and runs them with python_embeded.
rem ===================================================================
#WTIVO_SELFTEST#
import contextlib, io, sys, time
import numpy as np
sys.path.insert(0, sys.argv[2])
try:
    import trimesh
    from inprocess import process_arrays
except Exception as exc:
    print("    [FAIL] Could not load WTiVo:", exc)
    sys.exit(2)
sphere = trimesh.creation.icosphere(subdivisions=4, radius=0.5)
verts = np.asarray(sphere.vertices, dtype=np.float64)
faces = np.asarray(sphere.faces[60:], dtype=np.int32)  # 60 faces removed = holes
log = io.StringIO()
start = time.time()
try:
    with contextlib.redirect_stdout(log):
        _, out_faces, watertight, _, _ = process_arrays(
            verts, faces, input_res=256, final_res=256, proxy_points=200_000, threads=4)
except Exception as exc:
    print("    [FAIL]", exc)
    print("\n".join(log.getvalue().splitlines()[-15:]))
    sys.exit(1)
print(f"    Sphere with holes: {len(faces):,} faces in, {len(out_faces):,} out, "
      f"watertight={watertight}, {time.time() - start:.0f}s")
if not watertight:
    print("\n".join(log.getvalue().splitlines()[-15:]))
sys.exit(0 if watertight and len(out_faces) else 1)
#END#

rem ===================================================================
rem  Python model check for step 7: resolves model folders exactly like
rem  ComfyUI does. Exit 0 = found, 1 = missing.
rem ===================================================================
#MODELCHECK#
import os, re, sys
root, kind, name, quiet = os.path.abspath(sys.argv[2]), sys.argv[3], sys.argv[4], sys.argv[5] == "1"
comfy = os.path.join(root, "ComfyUI")
sys.path.insert(0, comfy)
bases = []
try:
    import folder_paths
    try:
        from utils.extra_config import load_extra_path_config
        configs = [os.path.join(comfy, "extra_model_paths.yaml")]
        for bat in os.listdir(root):  # launchers may pass --extra-model-paths-config
            if bat.lower().endswith(".bat"):
                text = open(os.path.join(root, bat), encoding="utf-8", errors="ignore").read()
                for m in re.finditer(r'--extra-model-paths-config\s+(?:"([^"]+)"|(\S+))', text):
                    p = m.group(1) or m.group(2)
                    configs += [p, os.path.join(root, p), os.path.join(comfy, p)]
        seen = set()
        for cfg in configs:
            cfg = os.path.normcase(os.path.abspath(cfg))
            if cfg not in seen and os.path.isfile(cfg):
                seen.add(cfg)
                load_extra_path_config(cfg)
    except Exception:
        pass
    bases = list(folder_paths.get_folder_paths(kind))
except Exception:
    pass
default = os.path.join(comfy, "models", kind)
if default not in bases:
    bases.append(default)
found = None
for base in bases:
    for folder, _, files in os.walk(base):
        if name in files:
            found = os.path.join(folder, name)
            break
    if found:
        break
if found and not quiet:
    inside = os.path.normcase(os.path.realpath(found)).startswith(os.path.normcase(os.path.realpath(default)) + os.sep)
    where = "" if inside else "  (" + os.path.dirname(found) + ")"
    print(f"    OK        {kind}\\{name}{where}")
sys.exit(0 if found else 1)
#END#

rem ===================================================================
rem  The five PixelArtistry print workflows (gzip + base64) for step 6.
rem  cmd never runs the lines below; step 6 unpacks them with Python.
rem ===================================================================
#WORKFLOWS#
import base64, gzip, os, sys
dest = sys.argv[2]
os.makedirs(dest, exist_ok=True)
FILES = {
    "PixelArtistry_Print_00_Image_Qwen.json": (
        "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"
    ),
    "PixelArtistry_Print_01_1K.json": (
        "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"
        "TyBSmsYPf/1/G7TkCJLOAAA="
    ),
    "PixelArtistry_Print_02_1536.json": (
        "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"
        "vxY2D/cJRErT+OGv/w9y4wPKns4AAA=="
    ),
    "PixelArtistry_Print_03_2K.json": (
        "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"
        "vCb3amHzcJ9ApDSNH/76/wBXbabbks4AAA=="
    ),
    "PixelArtistry_Print_04_Multiview.json": (
        "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"
        "gTwCAA=="
    ),
}
for name, blob in FILES.items():
    with open(os.path.join(dest, name), 'wb') as fh:
        fh.write(gzip.decompress(base64.b64decode(blob)))
    print('    ' + name)
#END#
