// sandbox.cpp 

#include "stdafx.h"

void print_help(void);

#if defined (UNICODE)
#define _tcout wcout
#else
#define _tcout cout
#endif // UNICODE

int _tmain(int argc, LPTSTR argv[])
{
  DWORD dwTimeLimit = 0;
  DWORD dwProcessLimit = 0;
  DWORD dwMemoryLimit = 0;
  LPTSTR szCommand = 0;
  bool fDebug = false;

  for (int iArg = 1; iArg < argc; ++iArg)
  {
    if (_tcsicmp (argv[iArg], TEXT("-h")) == 0
      || _tcsicmp (argv[iArg], TEXT("-?")) == 0)
    {
      print_help();
      return 1;
    }
    else if (_tcsicmp (argv[iArg], TEXT("-t")) == 0)
    {
      if (++iArg == argc)
        break;

      dwTimeLimit = ::_ttoi(argv[iArg]);
    }
    else if (_tcsicmp (argv[iArg], TEXT("-p")) == 0)
    {
      if (++iArg == argc)
        break;

      dwProcessLimit = ::_ttoi(argv[iArg]) ;
    }
    else if (_tcsicmp (argv[iArg], TEXT("-m")) == 0)
    {
      if (++iArg == argc)
        break;

      dwMemoryLimit = ::_ttoi(argv[iArg]);
    }
    else if (_tcsicmp (argv[iArg], TEXT("-d")) == 0)
    {
      fDebug = true;
    }
    else 
      szCommand = argv[iArg];
  }

  if (szCommand == 0)
  {
    cerr << "Error: No command given" << endl;
    print_help();
    return 1;
  }

  if (fDebug)
  {
      cout << "Time Limit = " << dwTimeLimit << endl;
      cout << "Process Limit = " << dwProcessLimit << endl;
      cout << "Memory Limit = " << dwMemoryLimit << endl;
      _tcout << TEXT("Command = ") << szCommand << endl;
  }

  if (dwTimeLimit == 0)
    dwTimeLimit = INFINITE;

  // Create a job kernel object.
  HANDLE hjob = ::CreateJobObject(NULL, NULL);

  // Place some restrictions on processes in the job.
  
  // First, set some basic restrictions.
  JOBOBJECT_BASIC_LIMIT_INFORMATION jobli = { 0 };

  // The process always runs in the idle priority class.
  jobli.PriorityClass = IDLE_PRIORITY_CLASS;

  // DO NOT limit the priority class, since we have tests that play with it.
  //jobli.LimitFlags = JOB_OBJECT_LIMIT_PRIORITY_CLASS;

  if (dwTimeLimit > 0)
  {
    // The job cannot use more than dwTimeLimit milliseconds of CPU time.
    jobli.PerJobUserTimeLimit.QuadPart = static_cast<__int64>(dwTimeLimit) * 10000; 

    jobli.LimitFlags |= JOB_OBJECT_LIMIT_JOB_TIME;
  }

  if (dwProcessLimit > 0)
  {
    // The job cannot have more than dwProcessLimit processes
    jobli.ActiveProcessLimit = dwProcessLimit;

    jobli.LimitFlags |= JOB_OBJECT_LIMIT_ACTIVE_PROCESS;
  }

  if (dwMemoryLimit > 0)
  {
    // set some extended restrictions.
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION jobeli = { 0 };

    jobli.LimitFlags |= JOB_OBJECT_LIMIT_JOB_MEMORY;

    ::memcpy(&jobeli.BasicLimitInformation, &jobli, sizeof(jobli));

    jobeli.JobMemoryLimit = dwMemoryLimit;

    ::SetInformationJobObject(hjob, JobObjectExtendedLimitInformation, &jobeli, sizeof(jobeli));
  }
  else 
  {
    ::SetInformationJobObject(hjob, JobObjectBasicLimitInformation, &jobli, sizeof(jobli));
  }

  
  // Second, set some UI restrictiosn.
  JOBOBJECT_BASIC_UI_RESTRICTIONS jobuir;
  jobuir.UIRestrictionsClass = JOB_OBJECT_UILIMIT_NONE;

  // The process can't log off the system.
  jobuir.UIRestrictionsClass |= JOB_OBJECT_UILIMIT_EXITWINDOWS;

  // The process can't access USER objects (such as other windows) in the system.
  jobuir.UIRestrictionsClass |= JOB_OBJECT_UILIMIT_HANDLES;

  ::SetInformationJobObject(hjob, JobObjectBasicUIRestrictions, &jobuir, sizeof(jobuir));

  STARTUPINFO si = { sizeof(si) };
  PROCESS_INFORMATION pi;
  ::CreateProcess(NULL, szCommand, NULL, NULL, FALSE, CREATE_SUSPENDED, NULL, NULL, &si, &pi);

  // Place this processin the job.
  ::AssignProcessToJobObject(hjob, pi.hProcess);

  // Now we can allow the child process's thread to execute code.
  ::ResumeThread(pi.hThread);
  ::CloseHandle(pi.hThread);

  // Wait for the process to terminate or for all the job's allotted CPU time to be used.
  HANDLE h[2];
  h[0] = pi.hProcess;
  h[1] = hjob;
  DWORD dw =  ::WaitForMultipleObjects(2, h, FALSE, dwTimeLimit);
  
  int nReturn = 0;

  switch (dw - WAIT_OBJECT_0) 
  {
  case WAIT_TIMEOUT:
    if (fDebug)
      cout << endl << "Process Timed Out" << endl;

    nReturn = 10;
    break;
  case WAIT_OBJECT_0:
    if (fDebug)
      cout << endl << "Process Exited" << endl;

    nReturn = 0;
    break;
  case WAIT_OBJECT_0 + 1:
    if (fDebug)
      cout << endl << "Process Exceeded Quota" << endl;

    nReturn = 11;
    break;
  }

  ::TerminateJobObject(hjob, ERROR_NOT_ENOUGH_QUOTA);
  ::CloseHandle(pi.hProcess);
  ::CloseHandle(hjob);

  return nReturn;
}

void print_help(void)
{
  cerr 
    << "Creates a sandbox for processes to run in." << endl
    << endl
    << "SANDBOX.EXE [-t timelimit] [-p processlimit] [-m memorylimit] command" << endl
    << endl
    << "  -t    sets the user time limit for the sandbox (in milliseconds)" << endl
    << "  -p    sets the limit of process that the sandbox can have" << endl
    << "  -m    sets the memory limit for each process in the sandbox" << endl;
}
