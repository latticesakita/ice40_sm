copy /y ice40_sm*.mem ..\..\..\tb 

for %%f in (*.mem) do (
	python mem2bin.py %%f %%~nf_BE.bin -be
	python mem2bin.py %%f %%~nf_LE.bin -le
)

