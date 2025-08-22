copy /y ice40_sm_Code.mem ..\..\..\tb 
python mem2bin.py ice40_sm_Code.mem ice40_sm_Code.bin -be
python mem2bin.py ice40_sm_Data.mem ice40_sm_Data.bin -be

