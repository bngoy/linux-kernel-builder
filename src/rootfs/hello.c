/*
** hello.c for Project in /Volumes/simplest-linux-devel/linux-kernel-builder
**
** Made by be
** Mail   <bertrand.ngoy@gmail.com>
**
** Started on  Wed Apr 29 10:25:45 2020 be
** Last update Wed Apr 29 10:25:45 2020 be
*/

#define _GNU_SOURCE
#include <sched.h>
#include <sys/types.h>
#include <sys/sysinfo.h>
#include <stdio.h>

#include "dl_syscalls.h"

int main(int argc, char* argv[])
{
  time_t            rawtime;
  struct tm         *timeinfo;
  struct sched_attr attr;
  unsigned int      flags = 0;
  cpu_set_t         cpu_set;
  int               ret;

  attr.size = sizeof(struct sched_attr);
  attr.sched_flags = 0;
  attr.sched_nice = 0;
  attr.sched_priority = 0;

  /* This creates a 200ms runtime every 1s period reservation */
  attr.sched_policy = SCHED_DEADLINE;
  attr.sched_runtime = 200 * 1000 * 1000;
  attr.sched_period = attr.sched_deadline = 1000 * 1000 * 1000;

  printf("nb procs: %i\n", get_nprocs());

  CPU_ZERO(&cpu_set);
  ret = sched_getaffinity(0, sizeof(cpu_set), &cpu_set);
  printf("affinity: %d\n", CPU_COUNT(&cpu_set));

  ret = sched_setattr(0, &attr, flags);
  if (ret < 0)
  {
    perror("[x] sched_setattr");
    exit(-1);
  }

  while (1)
  {
    time(&rawtime);
    timeinfo = localtime(&rawtime);
    printf("hello world! %s\n", asctime(timeinfo));

    sched_yield();
  }

  return 0;
}
