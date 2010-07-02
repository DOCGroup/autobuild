# Nmake macros for building Windows 32-Bit apps

!include <Win32.Mak>

all: $(OUTDIR) $(OUTDIR)\sandbox.exe

#----- If OUTDIR does not exist, then create directory
$(OUTDIR) :
    if not exist "$(OUTDIR)/$(NULL)" mkdir $(OUTDIR)

$(OUTDIR)\sandbox.obj: sandbox.cpp
    $(cc) $(cflags) $(cvars) /EHsc /Fo"$(OUTDIR)\\" /Fd"$(OUTDIR)\\" sandbox.cpp

$(OUTDIR)\sandbox.exe: $(OUTDIR)\sandbox.obj
    $(link) $(conflags) -out:$(OUTDIR)\sandbox.exe $(OUTDIR)\sandbox.obj $(conlibs)

#--------------------- Clean Rule --------------------------------------------------------
# Rules for cleaning out those old files
clean:
        $(CLEANUP)
