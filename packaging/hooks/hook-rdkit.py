# hook-rdkit.py — PyInstaller hook to collect all RDKit shared libraries.
#
# RDKit ships .so/.dylib files that PyInstaller's static import analysis
# cannot auto-detect. collect_all() forces everything to be included.

from PyInstaller.utils.hooks import collect_all

datas, binaries, hiddenimports = collect_all("rdkit")
