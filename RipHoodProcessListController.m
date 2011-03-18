//
//  RipHoodProcessListController.m
//  Hood
//
//  Created by Slava Karpenko on 11/26/08.
//  Copyright 2008 Ripdev. All rights reserved.
//

#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/mach_traps.h>
#include <mach/mach_init.h>

#import "RipHoodProcessListController.h"
#import "RipHoodProcessListCell.h"

static int my_system(const char * argv[]);

@implementation RipHoodProcessListController

@synthesize shouldTrack;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
	processes = [[NSMutableArray alloc] initWithCapacity:0];
	pidInfo = [[NSMutableDictionary alloc] initWithCapacity:0];
	
    [super viewDidLoad];
}

- (void)_initializeHasRootPermissions
{
	hasNoRootPermissionsInitialized = YES;
	hasNoRootPermissions = YES;
	
	NSString* killToolPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"HoodKill" ofType:@""];
	if (killToolPath)
	{
		NSDictionary* attributes = [[NSFileManager defaultManager] fileAttributesAtPath:killToolPath traverseLink:YES];
		
		hasNoRootPermissions = ![[attributes fileOwnerAccountName] isEqualToString:@"root"];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [processes count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"z";
	
	NSMutableDictionary* pinfo = [pidInfo objectForKey:[processes objectAtIndex:[indexPath row]]];
    
    RipHoodProcessListCell *cell = (RipHoodProcessListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[RipHoodProcessListCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    // Configure the cell
	cell.processInfo = pinfo;
	
    return cell;
}

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}
*/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSMutableDictionary* pinfo = [pidInfo objectForKey:[processes objectAtIndex:[indexPath row]]];
		pid_t pid = [[pinfo objectForKey:@"pid"] unsignedIntValue];
		
		if (pid)
		{
			// check gid
			if ([[pinfo objectForKey:@"gid"] unsignedIntValue] != getuid())
			{
				// do warning
			}
			
			[self killPID:pid];
		}
    }

}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!hasNoRootPermissionsInitialized)
		[self _initializeHasRootPermissions];
		
	NSMutableDictionary* pinfo = [pidInfo objectForKey:[processes objectAtIndex:[indexPath row]]];
	if (pinfo)
	{
		if ([[pinfo objectForKey:@"gid"] unsignedIntValue] != getuid() && hasNoRootPermissions)
			return NO;
	}
	
    return YES;
}

/*
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
}
*/
/*
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
*/

- (void)dealloc {
	[processes release];
	[pidInfo release];

    [super dealloc];
}

#pragma mark -

- (void)grabProcessList
{
	if (prTable.editing)
	{
		[self performSelector:@selector(grabProcessList) withObject:nil afterDelay:3.];
		return;
	}
	
	if (!self.shouldTrack)
	{
		return;	
	}

	[processes removeAllObjects];

	int name[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL };
	int res;
	size_t sz = 0;
	
	res = sysctl(name, (sizeof(name)/sizeof(int)), NULL, &sz, NULL, 0);
	if (0 == res && sz > 0)
	{
		struct kinfo_proc* pc = (struct kinfo_proc*)malloc(sz);
		
		if (pc)
		{
			res = sysctl(name, (sizeof(name)/sizeof(int)), (void*)pc, &sz, NULL, 0);
			int pcCount = sz / sizeof(struct kinfo_proc);
			int i;
			
			for (i=0; i < pcCount; i++)
			{
				NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
				NSNumber* pid = [NSNumber numberWithInt:pc[i].kp_proc.p_pid];
				
				if (![pidInfo objectForKey:pid])
				{				
					NSMutableDictionary* pinfo = [NSMutableDictionary dictionaryWithCapacity:0];
					NSString* processPath = [self nameForProcessWithPID:pc[i].kp_proc.p_pid];
					
					if (processPath)
					{
						[pinfo setObject:processPath forKey:@"path"];
						
						if ([[[processPath stringByDeletingLastPathComponent] pathExtension] isEqualToString:@"app"])
						{
							NSBundle* bundle = [NSBundle bundleWithPath:[processPath stringByDeletingLastPathComponent]];
							
							if (bundle)
							{
								NSString* bundleName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
								
								[pinfo setObject:bundle forKey:@"bundle"];
								
								if (bundleName)
									[pinfo setObject:bundleName forKey:@"name"];
								else
									[pinfo setObject:[[[processPath stringByDeletingLastPathComponent] lastPathComponent] stringByDeletingPathExtension] forKey:@"name"];
							}
							else
								[pinfo setObject:[[[processPath stringByDeletingLastPathComponent] lastPathComponent] stringByDeletingPathExtension] forKey:@"name"];
						}
						else
						{
							[pinfo setObject:[processPath lastPathComponent] forKey:@"name"];
						}
					}
					else
						[pinfo setObject:[NSString stringWithUTF8String:pc[i].kp_proc.p_comm] forKey:@"name"];
					
					[pinfo setObject:pid forKey:@"pid"];
					
					[pinfo setObject:[NSNumber numberWithInt:pc[i].kp_eproc.e_pcred.p_ruid] forKey:@"gid"];
/*					[pinfo setObject:[NSNumber numberWithUnsignedInt:pc[i].kp_proc.p_swtime] forKey:@"swtime"];
					[pinfo setObject:[NSNumber numberWithUnsignedInt:pc[i].kp_proc.p_slptime] forKey:@"slptime"];
					[pinfo setObject:[NSNumber numberWithUnsignedInt:pc[i].kp_proc.p_estcpu] forKey:@"estcpu"];
					[pinfo setObject:[NSNumber numberWithUnsignedInt:pc[i].kp_proc.p_cpticks] forKey:@"cpticks"];
					[pinfo setObject:[NSNumber numberWithUnsignedInt:pc[i].kp_proc.p_pctcpu] forKey:@"pctcpu"]; */
					
					[pidInfo setObject:pinfo forKey:pid];
				}
				
				[processes addObject:pid];
				
				[pool release];
			}
			
			// TODO: implement cleanup of dead pids from pidInfo dictionary
			
			free(pc);
		}
	}
	
	[prTable reloadData];
	
	[self performSelector:@selector(grabProcessList) withObject:nil afterDelay:3.];
}

- (NSString*)nameForProcessWithPID:(pid_t)pidNum
{
    NSString *returnString = nil;
    int mib[4], numArgs = 0;
    size_t size = 0;
    char *stringPtr = NULL;
	int res;
	static char* args = NULL;
	static int maxarg = 0;
	
	// Yes, we leak KERN_ARGMAX number of bytes here, at the optimization of not calling malloc/free all the time.
	if (!args)
	{
		mib[0] = CTL_KERN;
		mib[1] = KERN_ARGMAX;
		
		size = sizeof(maxarg);
		if ( sysctl(mib, 2, &maxarg, &size, NULL, 0) == -1 )
		{
			return nil;
		}
		
		args = (char *)malloc(maxarg);
		if (args == NULL)
		{
			return nil;
		}
	}
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROCARGS2;
    mib[2] = pidNum;
    
    size = (size_t)maxarg;
	res = sysctl(mib, 3, args, &size, NULL, 0);
    if ( res == -1 )
	{
		// no permission
		return nil;
    }
    
    memcpy( &numArgs, args, sizeof(numArgs) );
    stringPtr = args + sizeof(numArgs);
    
	returnString = [[NSString alloc] initWithUTF8String:stringPtr];
    
    return [returnString autorelease];
}

- (void)beginTracking
{
	// fetch list of processes and stuff...
	
	[self grabProcessList];
}

#pragma mark -

- (void)killPID:(pid_t)pid
{
	NSString* killToolPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"HoodKill" ofType:@""];
	
	if (killToolPath)
	{
		const char* argv[] = {
			[[NSFileManager defaultManager] fileSystemRepresentationWithPath:killToolPath],
			[[NSString stringWithFormat:@"%u", pid] UTF8String],
			NULL
		};
		
		my_system(argv);
		
		[self grabProcessList];
	}
}

@end

static int my_system(const char * argv[])
{
	pid_t child;
	
	if (child = fork())
	{
		int exitStatus = 0;
		
		waitpid(child, &exitStatus, 0);
		
		return WEXITSTATUS(exitStatus);
	}
	else
	{
		// Set environment
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		unsetenv("DYLD_INSERT_LIBRARIES");
		
		execvp(argv[0], (char *const*)argv);
		
		[pool release];
		exit(0);
	}
		
	return -1;
}
