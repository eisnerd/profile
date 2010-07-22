#include <semaphore.h>

int main(int argc, char** argv)
{
  if (argc < 2)
	return 1;
  char path[256] = "/tmp/lock.";
  sem_t sem = sem_open(strcat(path, argv[0]), 
}
