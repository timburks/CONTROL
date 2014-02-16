// must be suid root
// chown root repound
// chmod +s repound

#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <signal.h>

#include <sys/param.h>
#include <sys/user.h>
#include <sys/sysctl.h>
#include <stdio.h>
#include <stdlib.h>

/*=======================================================================*/
void killAll(const char * csProcessName){
/*=======================================================================*/

        struct kinfo_proc *sProcesses = NULL, *sNewProcesses;
        pid_t  iCurrentPid;
        int    aiNames[4];
        size_t iNamesLength;
        int    i, iRetCode, iNumProcs;
        size_t iSize;

        iSize = 0;
        aiNames[0] = CTL_KERN;
        aiNames[1] = KERN_PROC;
        aiNames[2] = KERN_PROC_ALL;
        aiNames[3] = 0;
        iNamesLength = 3;

        iRetCode = sysctl(aiNames, iNamesLength, NULL, &iSize, NULL, 0);

        /*
         * Allocate memory and populate info in the  processes structure
         */

        do {
                iSize += iSize / 10;
                sNewProcesses = realloc(sProcesses, iSize);

                if (sNewProcesses == 0) {
                        if (sProcesses)
                                free(sProcesses);
                                errx(1, "could not reallocate memory");
                }
                sProcesses = sNewProcesses;
                iRetCode = sysctl(aiNames, iNamesLength, sProcesses, &iSize, NULL, 0);
        } while (iRetCode == -1 && errno == ENOMEM);

        iNumProcs = iSize / sizeof(struct kinfo_proc);
      /*
         * Search for the given process name and kill it.
         */

        for (i = 0; i < iNumProcs; i++) {
                iCurrentPid = sProcesses[i].kp_proc.p_pid;
                if( strncmp(csProcessName, sProcesses[i].kp_proc.p_comm, MAXCOMLEN) == 0 ) {
  			printf("signaling %d\n", iCurrentPid);
  			kill(iCurrentPid, 1);
                }
        }
        free(sProcesses);
} /* end of getProcessId() */


 
int main(void) {
    printf(
        "Real      UID = %d\n"
        "Effective UID = %d\n"
        "Real      GID = %d\n"
        "Effective GID = %d\n",
        getuid (),
        geteuid(),
        getgid (),
        getegid()
    );
  killAll("nginx");
  return 0;
}
