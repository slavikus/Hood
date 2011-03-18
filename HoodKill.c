/*
 *  HoodKill.c
 *  Hood
 *
 *  Created by Slava Karpenko on 12/3/08.
 *  Copyright 2008 Ripdev. All rights reserved.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>

int main(int argc, char* argv[])
{
	if (argc < 2)
	{
		return -1;
	}
	
	pid_t pid = (pid_t)atoi(argv[1]);
	if (pid)
	{
		return kill(pid, SIGTERM);
	}
	
	return 1;
}