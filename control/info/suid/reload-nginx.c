
#include <unistd.h>


int main (int argc, char *argv[]) {
  return execl("/usr/local/nginx/sbin/nginx", "nginx", "-s", "reload", "-c", "/Users/xmachine/Xmachine/Config/nginx.conf", (char *) 0);
}

