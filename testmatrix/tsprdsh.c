/* Check the log output from running the TAO tests using auto_run_tests */

#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <libgen.h>
#include <sys/stat.h>
#include <time.h>

#define TRUE 1
#define FALSE 0
#define LLEN 8000
#define LPP 53

struct filenode {
  struct filenode *next;
  char *name;
  char *fname;
  int num;
  int failed;
  };

struct filenode *fhead = NULL;
struct filenode *ftail = NULL;

struct testnode {
  struct testnode *next;
  char *name;
  char *results;
  };

struct testnode *thead = NULL;
struct testnode *ttail = NULL;

int numtests = 0;
int numfiles = 0;

int test_pass = 0;
int test_fail = 0;
int test_skip = 0;
int test_total = 0;

char * dupstr ( char * str )
{
  char * newstr;
  newstr = malloc( strlen(str)+1 );

  if ( newstr == NULL ) {
    printf("Error on malloc string\n");
    exit(1);
    }
  strcpy( newstr, str );
  return newstr;
}


int pathfind ( char *path, char *file, char *mode )
{
    /* This is a stand-in for the Sun provided routine
       it only does the part of the job this program needs */

  struct stat buf;
  int rc;

  rc = stat( file, &buf );
  if ( rc != 0 ) return FALSE;
  return ! S_ISDIR(buf.st_mode);
}


struct testnode * findtest ( char * test )
{
  struct testnode *p;
  p = thead;
  while ( p != NULL ) {
    if ( strcmp( p->name, test ) == 0 ) return p;
    p = p->next;
    }
  p = (struct testnode *) malloc( sizeof(struct testnode) );
  if ( p == NULL ) {
    printf("Unable to malloc testnode\n");
    exit(1);
    }
  p->next = NULL;
  p->name = dupstr( test );
  p->results = malloc( numfiles );
  if ( p->results == NULL ) {
    printf("Unable to malloc testnode\n");
    exit(1);
    }
  memset(p->results, '-', numfiles);
  test_total += numfiles;
  numtests++;
  if ( thead == NULL )
    thead = p;
  else
    ttail->next = p;
  ttail = p;
  return p;
}


void
tot( struct filenode *node, char * buf, int found )
{
  struct testnode *tst;
  char c;
  int i;

  if( ! buf[0] ) return;
  // strip off trailing whitespace
  i = strlen(buf) - 1;
  while ( i >= 0 && ( buf[i] == ' ' || buf[i] == '\t' || buf[i] == '\r' || buf[i] == '\n' ) ) buf[i--] = '\0';


  tst = findtest( buf );
  if( found ) node->failed++;
  if (found == 0) {
    c = '.';
    test_pass++;
    }
  else {
    c = 'X';
    test_fail++;
    }
  tst->results[node->num] = c;
}


void
checkfile ( struct filenode *node )
{
  FILE * filenum;
  char * filename;
  char  buf[160];
  char * eof = buf;
  char line[LLEN];
  int rc;
  int found;

  filename = node->fname;
  filenum = fopen(filename, "r");
  if (filenum == NULL) {
      /* Could not open file */
    return;
    }
  strcpy(buf, "*** Pre-Test (Setup & Compile ***)");
  found = 0;

  // First scan the Pre-Test stuff
  while ( eof != NULL ) {
    eof = fgets( line, LLEN, filenum );
    if( eof == NULL ) break;
    rc = strncmp( line, "auto_run_tests:", 15 );
    if( rc == 0 ) {
      break;
      }
    rc = strncmp( line, "Error:", 6 );
    if( rc == 0 ) found++;
    }

  // Second do the ACE tests
  while ( eof != NULL ) {
    eof = fgets( line, LLEN, filenum );
    if( eof == NULL ) break;
    rc = strncmp( line, "auto_run_tests:", 15 );
    if( rc == 0 ) {
      strcpy( buf, &line[16] );
      buf[strlen(buf)-1] = '\0';  /* erase the new line*/
      break;
      }
    rc = strncmp( line, "Running :", 8 );
    if( rc == 0 ) {
      tot( node, buf, found );
      found = 0;
      strcpy( buf, &line[8] );
      buf[strlen(buf)-1] = '\0';  /* erase the new line*/
      }
    rc = strncmp( line, "ERROR:", 6 );
    if( rc == 0 ) found++;
    rc = strncmp( line, "Error:", 6 );
    if( rc == 0 ) found++;
    }

  // Third do the TAO tests
  while ( eof != NULL ) {
    eof = fgets( line, LLEN, filenum );
    if( eof == NULL ) break;
    rc = strncmp( line, "auto_run_tests:", 15 );
    if( rc == 0 ) {
      tot( node, buf, found );
      found = 0;
      strcpy( buf, &line[16] );
      buf[strlen(buf)-1] = '\0';  /* erase the new line*/
      }
    rc = strncmp( line, "ERROR:", 6 );
    if( rc == 0 ) found++;
    rc = strncmp( line, "Error:", 6 );
    if( rc == 0 ) found++;
    }
  tot( node, buf, found );
  fclose(filenum);
  return;
}


int printtestline_html( struct testnode *p)
{
  int i;
  int result;

  printf("<tr>");
  for( i=0; i<numfiles; i++ )
  {
    result = p->results[i];
    switch (result) {
      case 'X':
        printf("<td bgcolor=\"red\"><a href=\"#%2d\">%c</a></td>", i+1, result);
//        test_fail++;
        break;
      case '.':
        printf("<td bgcolor=\"green\">%c </td>", result);
//        test_pass++;
        break;
      default:
        printf("<td>%c </td>", result);
//        test_skip++;
      }
    }
  printf("<td class=\"buildname\"> %s </td></tr>\n", p->name);

  return 0;
}


int printtestline( struct testnode *p)
{
  int i;
  for( i=0; i<numfiles; i++ ) printf("%c", p->results[i]);
  printf(" %s\n", p->name);
  return 0;
}


int printnodeline( struct filenode *p)
{
  printf("%2d %4d %s\n", p->num+1, p->failed, p->name);
  return 0;
}


int printnodeline_html( struct filenode *p, int summary_only )
{
  // print only builds with >50 tests failing 
  if (summary_only){ 
    if (p->failed > 50)
      printf("<tr><td><a name=\"%2d\"> %2d </td><td> %4d </td><td class=\"buildname\"> %s </td></tr>\n", p->num+1, p->num+1, p->failed, p->name);
  }
  else
      printf("<tr><td><a name=\"%2d\"> %2d </td><td> %4d </td><td class=\"buildname\"> %s </td></tr>\n", p->num+1, p->num+1, p->failed, p->name);
  return 0;
}


void printdate( void)
{
	time_t utc;
	struct tm * currtime;

	time (&utc);
	currtime = localtime (&utc);

	printf("%s", asctime (currtime) );
}

void printbanner(void)
{
  int i;
  char line[LLEN];

  printf ("<tr>");
  for( i=1; i<=numfiles; i++ ) {
    sprintf(line, "%02d", i);
    printf("<td>%c</td>", line[0]);
    }
  printf("<td rowspan=2><b>Name of test</b></td>");
  printf ("</tr>\n");

  printf ("<tr>");
  for( i=1; i<=numfiles; i++ ) {
    sprintf(line, "%02d", i);
    printf("<td>%c</td>", line[1]);
    }
  printf ("</tr>\n");
}

main ( int argc, char *argv[] )  /* Expect the file name on the command line */
{
  int rc;
  FILE * filenum;
  char *filename;
  char * eof = " ";
  char line[LLEN];
  char * line1;
  char * line2;
  struct filenode *newnode;
  struct testnode *newtest;
  int i;
  int lc = 0;
  int html_format;
  int summary_only = 0;
  int lpp;
  double test_pass_perc = 0.0;
  double test_fail_perc = 0.0;
  double test_skip_perc = 0.0;
  
    /* Get the file name from the command line */
  if (argc < 2 || argc > 4) { 
      /* No argument specified or too many*/
    printf("Usage: %s <control file> [ -html [ -summary ] ]\n", argv[0]);
    exit(1);
    }
  filename = argv[1];
  if( ! pathfind( NULL, filename, "d" ) ) {
    printf("%s does not exist or is a directory\n", filename);
    exit(1);
    }
  filenum = fopen(filename, "r");
  if (filenum == NULL) {
      /* Could not open file */
    printf("Could not open %s\n", filename);
    exit(2);
    }

    /* check if they want html formatting */
  if (argc > 2) {
    html_format = !strncmp( argv[2], "-html", 5);
    if (argc == 4 && html_format)
      summary_only = !strncmp( argv[3], "-summary", 7);
    }
  else 
    html_format = 0;

  if ( html_format ){
    printf ("<html>\n<head>\n");
    printf ("<title>Scoreboard Test Matrix</title>\n");
    printf ("<style type=\"text/css\">");
    printf ("td {text-align:center;}\ntd.buildname {text-align: left;}\n");
    printf ("</style>\n");
    printf ("</head>\n<body bgcolor=\"white\" link=\"black\" vlink=\"black\">\n");
    }

  while ( eof != NULL ) {
    eof = fgets( line, LLEN, filenum );
    if( eof == NULL ) break;

      /* trim off trailing whitespace */
    i = strlen(line) - 1;
    while ( i >= 0 && ( line[i] == ' ' || line[i] == '\t' 
              || line[i] == '\r' || line[i] == '\n' ) ) line[i--] = '\0';
    i = 0;

      /* trim off leading whitespace */
    while ( line[i] == ' ' || line[i] == '\t' ) i++;
    if ( line[i] == '\0' || line[i] == '#' ) continue;
    line1 = &line[i];

      /* isolate the name, we'll use this to identify the test column */
    while ( line[i] != ' ' && line[i] != '\t' && line[i] != '\0' ) i++;
    if ( line[i] == '\0' ) {
      printf("No path for %s\n", line1);
      exit(1);
      }
    line[i] = '\0';
    i++;

      /* trim off leading whitespace of the file path */
    while ( line[i] == ' ' || line[i] == '\t' ) i++;
    if ( line[i] == '\0' ) {
      printf("No path for %s\n", line1);
      exit(1);
      }
    line2 = &line[i];
      /* validate path */
    if( ! pathfind( NULL, line2, "d" ) ) {
      printf("%s does not exist or is a directory on %s\n", line2, line1);
      lc++;
      }
      /* Now put in the table */
    newnode = (struct filenode *) malloc( sizeof(struct filenode) );
    if ( newnode == NULL ) {
      printf("Error on malloc file node\n");
      exit(1);
      }
    newnode->next = NULL;
    newnode->name = dupstr( line1 );
    newnode->fname = dupstr( line2 );
    newnode->num = numfiles++;
    if ( fhead == NULL )
      fhead = newnode;
    else
      ftail->next = newnode;
    ftail = newnode;
    }
  
  newnode = fhead;
  while ( newnode != NULL ) {
    // If we are in "summary_only" mode, only count up the non-doc builds
    if ( summary_only ) {
      int doc = strncmp( newnode->name, "doc_", 4);
      if (doc != 0)
        checkfile ( newnode ); 
    }
    else
        checkfile ( newnode ); 
    newnode = newnode->next;
  }

  newtest = thead;

  if ( html_format ){
    printf("Last Updated on ");
    printdate();
    
    // Print the statistics
    test_pass_perc = 100.0 * (double) test_pass / (double) test_total;
    test_fail_perc = 100.0 * (double) test_fail / (double) test_total;
    test_skip = test_total - test_pass - test_fail;
    test_skip_perc = 100.0 * (double) test_skip / (double) test_total;
    printf("<table><tbody>\n");
    printf("<tr><td style=\"text-align:left;\">Tests Passed</td><td style=\"text-align:right;\">%6d</td><td style=\"text-align:right;\">%03.02f %%</td></tr>\n", test_pass, test_pass_perc);
    printf("<tr><td style=\"text-align:left;\">Tests Failed</td><td style=\"text-align:right;\">%6d</td><td style=\"text-align:right;\">%03.02f %%</td></tr>\n", test_fail, test_fail_perc);
    printf("<tr><td style=\"text-align:left;\">Tests Skipped</td><td style=\"text-align:right;\">%6d</td><td style=\"text-align:right;\">%03.02f %%</td></tr>\n", test_skip, test_skip_perc);
    printf("</tbody></table>\n");

    printf("<br /><br />\n");
    
      // print the number of tests failing in each build
    newnode = fhead;
    printf ("<table border=1 cellpadding=0 cellspacing=0><tbody>\n");
    printf ("<tr><th>Build Number</th><th>Number of test failing</th><th>Build Name</th></tr>\n");
    while ( newnode != NULL ) {
      printnodeline_html( newnode , summary_only );
      newnode = newnode->next;
      }
    printf("</tbody></table>\n<br />\n");

    printf("<br /><br />\n");

    if (!summary_only){
      // Print the Tests
      printf ("<table border=1 cellpadding=0 cellspacing=0><tbody>\n");
      lpp = numtests / ( numtests / 40 ) + 1;
      lc = 0;
      printbanner();

      while ( newtest != NULL ) {
        printtestline_html( newtest );
        // repeat the banner at intervals
        if( ++lc >= lpp ) {
          printbanner();
          lc = 0;
          }
        newtest = newtest->next;
        }
      printbanner();
      printf("</tbody></table>\n");
    }

    printf("</body>\n</html>\n");
    }
  else {
    /* print the output */
    if( lc != 0 ) {
      printf("\f");
      lc = 0;
      }

    // print all the tests
    while ( newtest != NULL ) {
      if( lc == 0 ) {
        // print column headers
        for( i=1; i<=numfiles; i++ ) {
          sprintf(line, "%02d", i);
          printf("%c", line[0]);
          }
        printf("\n");
        for( i=1; i<=numfiles; i++ ) {
          sprintf(line, "%02d", i);
          printf("%c", line[1]);
          }
        printf(" Name of test\n\n");
        lc = 3;
        }

      printtestline( newtest );
      newtest = newtest->next;
      // check if end of page
      if( ++lc >= LPP ) {
        printf("\f");
        lc = 0;
        }
      }
  
    // check for space between tests and builds
    if( lc + numfiles + 2 > LPP ) {
      printf("\f");
      lc = 0;
      }
    else
      printf("\n\n");
  
    // print the builds
    newnode = fhead;
    while ( newnode != NULL ) {
      printnodeline( newnode );
      newnode = newnode->next;
      }

    } //End of the non-html format

exit(0);
}
