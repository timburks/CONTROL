#include <unistd.h>

int main (int argc, char *argv[]) {
  return execl("/bin/launchctl", 
               "launchctl", 
               "load", 
               "-F", 
               "/Users/xmachine/Xmachine/LaunchAgents", 
               (char *) 0);
}
