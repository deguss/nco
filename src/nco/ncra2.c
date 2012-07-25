/* $Header: /data/zender/nco_20150216/nco/src/nco/ncra2.c,v 1.19 2012-07-25 03:33:46 zender Exp $ */

/* This single source file may be called as three separate executables:
   ncra -- netCDF running averager
   ncea -- netCDF ensemble averager
   ncrcat -- netCDF record concatenator */

/* Purpose: Compute averages or extract series of specified hyperslabs of 
   specfied variables of multiple input netCDF files and output them 
   to a single file. */

/* Copyright (C) 1995--2012 Charlie Zender

   License: GNU General Public License (GPL) Version 3
   The full license text is at http://www.gnu.org/copyleft/gpl.html 
   and in the file nco/doc/LICENSE in the NCO source distribution.
   
   As a special exception to the terms of the GPL, you are permitted 
   to link the NCO source code with the HDF, netCDF, OPeNDAP, and UDUnits
   libraries and to distribute the resulting executables under the terms 
   of the GPL, but in addition obeying the extra stipulations of the 
   HDF, netCDF, OPeNDAP, and UDUnits licenses.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
   See the GNU General Public License for more details.
   
   The original author of this software, Charlie Zender, seeks to improve
   it with your suggestions, contributions, bug-reports, and patches.
   Please contact the NCO project at http://nco.sf.net or write to
   Charlie Zender
   Department of Earth System Science
   University of California, Irvine
   Irvine, CA 92697-3100 */

/* URL: http://nco.cvs.sf.net/nco/nco/src/nco/ncra.c

   Usage:
   ncra -O -n 3,4,1 -p ${HOME}/nco/data h0001.nc ~/foo.nc
   ncra -O -n 3,4,1 -p ${HOME}/nco/data -l ${HOME} h0001.nc ~/foo.nc
   ncra -O -n 3,4,1 -p /ZENDER/tmp -l ${HOME}/nco/data h0001.nc ~/foo.nc
   scp ~/nco/src/nco/ncra.c esmf.ess.uci.edu:nco/src/nco

   ncea in.nc in.nc ~/foo.nc
   ncea -O -n 3,4,1 -p ${HOME}/nco/data h0001.nc ~/foo.nc
   ncea -O -n 3,4,1 -p ${HOME}/nco/data -l ${HOME} h0001.nc ~/foo.nc
   ncea -O -n 3,4,1 -p /ZENDER/tmp -l ${HOME} h0001.nc ~/foo.nc */

#ifdef HAVE_CONFIG_H
# include <config.h> /* Autotools tokens */
#endif /* !HAVE_CONFIG_H */

/* Standard C headers */
#include <math.h> /* sin cos cos sin 3.14159 */
#include <stdio.h> /* stderr, FILE, NULL, etc. */
#include <stdlib.h> /* atof, atoi, malloc, getopt */
#include <string.h> /* strcmp. . . */
#include <sys/stat.h> /* stat() */
#include <time.h> /* machine time */
#ifndef _MSC_VER
# include <unistd.h> /* POSIX stuff */
#endif
#ifndef HAVE_GETOPT_LONG
# include "nco_getopt.h"
#else /* HAVE_GETOPT_LONG */ 
# ifdef HAVE_GETOPT_H
#  include <getopt.h>
# endif /* !HAVE_GETOPT_H */ 
#endif /* HAVE_GETOPT_LONG */

/* Internationalization i18n, Linux Journal 200211 p. 57--59 */
#ifdef I18N
#include <libintl.h> /* Internationalization i18n */
#include <locale.h> /* Locale setlocale() */
#define _(sng) gettext (sng)
#define gettext_noop(sng) (sng)
#define N_(sng) gettext_noop(sng)
#endif /* I18N */
#ifndef _LIBINTL_H
# define gettext(foo) foo
#endif /* _LIBINTL_H */

/* 3rd party vendors */
#include <netcdf.h> /* netCDF definitions and C library */

/* Personal headers */
/* #define MAIN_PROGRAM_FILE MUST precede #include libnco.h */
#define MAIN_PROGRAM_FILE
#include "libnco.h" /* netCDF Operator (NCO) library */

/* Define inline'd functions in header so source is visible to calling files
   C99 only: Declare prototype in exactly one header
   http://www.drdobbs.com/the-new-c-inline-functions/184401540 */
extern int min_int(int a, int b);
extern int max_int(int a, int b);
inline int min_int(int a, int b){return (a < b) ? a : b;}
inline int max_int(int a, int b){return (a > b) ? a : b;}
extern long min_lng(long a, long b);
extern long max_lng(long a, long b);
inline long min_lng(long a, long b){return (a < b) ? a : b;}
inline long max_lng(long a, long b){return (a > b) ? a : b;}

int
main(int argc,char **argv)
{
  nco_bool CNV_ARM;
  nco_bool CNV_CCM_CCSM_CF;
  nco_bool EXCLUDE_INPUT_LIST=False; /* Option c */
  nco_bool EXTRACT_ALL_COORDINATES=False; /* Option c */
  nco_bool EXTRACT_ASSOCIATED_COORDINATES=True; /* Option C */
  nco_bool FL_RTR_RMT_LCN;
  nco_bool FL_LST_IN_APPEND=True; /* Option H */
  nco_bool FL_LST_IN_FROM_STDIN=False; /* [flg] fl_lst_in comes from stdin */
  nco_bool FORCE_APPEND=False; /* Option A */
  nco_bool FORCE_OVERWRITE=False; /* Option O */
  nco_bool FORTRAN_IDX_CNV=False; /* Option F */
  nco_bool HISTORY_APPEND=True; /* Option h */
  nco_bool FINAL_DESIRED_RECORD_FROM_ALL_INPUT_FILES=False;
  nco_bool LAST_RECORD_OF_CURRENT_GROUP=False;
  nco_bool LAST_STRIDE_IN_FILE=False;
  nco_bool FIRST_RECORD_OF_CURRENT_GROUP=False;
  nco_bool FLG_BFR_NEEDS_NRM=False; /* [flg] Current output buffers need normalization */
  nco_bool FLG_MRO=False; /* [flg] Multi-Record Output */
  nco_bool MD5_DIGEST=False; /* [flg] Perform MD5 digests */
  nco_bool MSA_USR_RDR=False; /* [flg] Multi-slabbing algorithm leaves hyperslabs in */
  nco_bool RAM_CREATE=False; /* [flg] Create file in RAM */
  nco_bool RAM_OPEN=False; /* [flg] Open (netCDF3-only) file(s) in RAM */
  nco_bool RM_RMT_FL_PST_PRC=True; /* Option R */
  nco_bool WRT_TMP_FL=True; /* [flg] Write output to temporary file */
  nco_bool flg_cln=False; /* [flg] Clean memory prior to exit */

  char **fl_lst_abb=NULL; /* Option n */
  char **fl_lst_in;
  char **var_lst_in=NULL_CEWI;
  char *aux_arg[NC_MAX_DIMS];
  char *cmd_ln;
  char *cnk_arg[NC_MAX_DIMS];
  char *cnk_map_sng=NULL_CEWI; /* [sng] Chunking map */
  char *cnk_plc_sng=NULL_CEWI; /* [sng] Chunking policy */
  char *fl_in=NULL;
  char *fl_out=NULL; /* Option o */
  char *fl_out_tmp=NULL_CEWI;
  char *fl_pth=NULL; /* Option p */
  char *fl_pth_lcl=NULL; /* Option l */
  char *lmt_arg[NC_MAX_DIMS];
  char *nco_op_typ_sng=NULL_CEWI; /* [sng] Operation type Option y */
  char *nco_pck_plc_sng=NULL_CEWI; /* [sng] Packing policy Option P */
  char *opt_crr=NULL; /* [sng] String representation of current long-option name */
  char *optarg_lcl=NULL; /* [sng] Local copy of system optarg */
  
  char *sng_cnv_rcd=NULL_CEWI; /* [sng] strtol()/strtoul() return code */

  const char * const CVS_Id="$Id: ncra2.c,v 1.19 2012-07-25 03:33:46 zender Exp $"; 
  const char * const CVS_Revision="$Revision: 1.19 $";
  const char * const opt_sht_lst="346ACcD:d:FHhL:l:n:Oo:p:P:rRt:v:X:xY:y:-:";

  cnk_sct **cnk=NULL_CEWI;

#if defined(__cplusplus) || defined(PGI_CC)
  ddra_info_sct ddra_info;
  ddra_info.flg_ddra=False;
#else /* !__cplusplus */
  ddra_info_sct ddra_info={.flg_ddra=False};
#endif /* !__cplusplus */

  dmn_sct **dim;
  dmn_sct **dmn_out;
  
  extern char *optarg;
  extern int optind;

  /* Using naked stdin/stdout/stderr in parallel region generates warning
     Copy appropriate filehandle to variable scoped shared in parallel clause */
  FILE * const fp_stderr=stderr; /* [fl] stderr filehandle CEWI */
  FILE * const fp_stdout=stdout; /* [fl] stdout filehandle CEWI */

  int *in_id_arr;

  int abb_arg_nbr=0;
  int aux_nbr=0; /* [nbr] Number of auxiliary coordinate hyperslabs specified */
  int cnk_map=nco_cnk_map_nil; /* [enm] Chunking map */
  int cnk_nbr=0; /* [nbr] Number of chunk sizes */
  int cnk_plc=nco_cnk_plc_nil; /* [enm] Chunking policy */
  int dfl_lvl=0; /* [enm] Deflate level */
  int fl_idx;
  int fl_nbr=0;
  int fl_in_fmt; /* [enm] Input file format */
  int fl_out_fmt=NCO_FORMAT_UNDEFINED; /* [enm] Output file format */
  int fll_md_old; /* [enm] Old fill mode */
  int idx=int_CEWI;
  int jdx=int_CEWI;
  int in_id;
  int lmt_nbr=0; /* Option d. NB: lmt_nbr gets incremented */
  int md_open; /* [enm] Mode flag for nc_open() call */
  int nbr_dmn_fl;
  int nbr_dmn_xtr;
  int nbr_var_fix; /* nbr_var_fix gets incremented */
  int nbr_var_fl;
  int nbr_var_prc; /* nbr_var_prc gets incremented */
  int xtr_nbr=0; /* xtr_nbr won't otherwise be set for -c with no -v */
  int nco_op_typ=nco_op_avg; /* [enm] Default operation is averaging */
  int nco_pck_plc=nco_pck_plc_nil; /* [enm] Default packing is none */
  int opt;
  int out_id;  
  int rcd=NC_NOERR; /* [rcd] Return code */
  int rec_dmn_id=NCO_REC_DMN_UNDEFINED;
  int thr_idx; /* [idx] Index of current thread */
  int thr_nbr=int_CEWI; /* [nbr] Thread number Option t */
  int var_lst_in_nbr=0;
  
  lmt_sct **aux=NULL_CEWI; /* Auxiliary coordinate limits */
  lmt_sct **lmt=NULL_CEWI;
  lmt_sct *lmt_rec=NULL_CEWI;
  lmt_all_sct **lmt_all_lst; /* List of *lmt_all structures */
  lmt_all_sct *lmt_all_rec=NULL_CEWI; /* Pointer to record limit structure in above list */
  
  long idx_rec_crr_in; /* [idx] Index of current record in current input file */
  long rec_rmn_prv_drn=0L; /* [idx] Records remaining to be read in current duration group */
  long rec_dmn_sz=0L; /* [idx] Size of record dimension, if any, in current file (increments by srd) */
  long rec_usd_cml=0L; /* [nbr] Cumulative number of input records used (catenated by ncrcat or operated on by ncra) */
  long idx_rec_out=0L; /* [idx] Index of current record in output file (0 is first, ...) */
  
  nco_int base_time_srt=nco_int_CEWI;
  nco_int base_time_crr=nco_int_CEWI;

  nm_id_sct *dmn_lst;
  nm_id_sct *xtr_lst=NULL; /* xtr_lst may be alloc()'d from NULL with -c option */
  
  size_t bfr_sz_hnt=NC_SIZEHINT_DEFAULT; /* [B] Buffer size hint */
  size_t cnk_sz_scl=0UL; /* [nbr] Chunk size scalar */
  
  var_sct **var;
  var_sct **var_fix;
  var_sct **var_fix_out;
  var_sct **var_out=NULL_CEWI;
  var_sct **var_prc;
  var_sct **var_prc_out;
  
  static struct option opt_lng[]=
    { /* Structure ordered by short option key if possible */
      /* Long options with no argument, no short option counterpart */
      {"cln",no_argument,0,0}, /* [flg] Clean memory prior to exit */
      {"clean",no_argument,0,0}, /* [flg] Clean memory prior to exit */
      {"mmr_cln",no_argument,0,0}, /* [flg] Clean memory prior to exit */
      {"drt",no_argument,0,0}, /* [flg] Allow dirty memory on exit */
      {"dirty",no_argument,0,0}, /* [flg] Allow dirty memory on exit */
      {"mmr_drt",no_argument,0,0}, /* [flg] Allow dirty memory on exit */
      {"md5_digest",no_argument,0,0}, /* [flg] Print MD5 digest */
      {"msa_usr_rdr",no_argument,0,0}, /* [flg] Multi-slabbing algorithm leaves hyperslabs in user order */
      {"ram_all",no_argument,0,0}, /* [flg] Open (netCDF3) and create file(s) in RAM */
      {"create_ram",no_argument,0,0}, /* [flg] Create file in RAM */
      {"open_ram",no_argument,0,0}, /* [flg] Open (netCDF3) file(s) in RAM */
      {"diskless_all",no_argument,0,0}, /* [flg] Open (netCDF3) and create file(s) in RAM */
      {"ram_all",no_argument,0,0}, /* [flg] Open (netCDF3) and create file(s) in RAM */
      {"create_ram",no_argument,0,0}, /* [flg] Create file in RAM */
      {"open_ram",no_argument,0,0}, /* [flg] Open (netCDF3) file(s) in RAM */
      {"diskless_all",no_argument,0,0}, /* [flg] Open (netCDF3) and create file(s) in RAM */
      {"wrt_tmp_fl",no_argument,0,0}, /* [flg] Write output to temporary file */
      {"write_tmp_fl",no_argument,0,0}, /* [flg] Write output to temporary file */
      {"no_tmp_fl",no_argument,0,0}, /* [flg] Do not write output to temporary file */
      {"version",no_argument,0,0},
      {"vrs",no_argument,0,0},
      /* Long options with argument, no short option counterpart */
      {"bfr_sz_hnt",required_argument,0,0}, /* [B] Buffer size hint */
      {"buffer_size_hint",required_argument,0,0}, /* [B] Buffer size hint */
      {"chunk_map",required_argument,0,0}, /* [nbr] Chunking map */
      {"cnk_plc",required_argument,0,0}, /* [nbr] Chunking policy */
      {"chunk_policy",required_argument,0,0}, /* [nbr] Chunking policy */
      {"cnk_scl",required_argument,0,0}, /* [nbr] Chunk size scalar */
      {"chunk_scalar",required_argument,0,0}, /* [nbr] Chunk size scalar */
      {"cnk_dmn",required_argument,0,0}, /* [nbr] Chunk size */
      {"chunk_dimension",required_argument,0,0}, /* [nbr] Chunk size */
      {"fl_fmt",required_argument,0,0},
      {"file_format",required_argument,0,0},
      /* Long options with short counterparts */
      {"3",no_argument,0,'3'},
      {"4",no_argument,0,'4'},
      {"64bit",no_argument,0,'4'},
      {"netcdf4",no_argument,0,'4'},
      {"append",no_argument,0,'A'},
      {"coords",no_argument,0,'c'},
      {"crd",no_argument,0,'c'},
      {"no-coords",no_argument,0,'C'},
      {"no-crd",no_argument,0,'C'},
      {"debug",required_argument,0,'D'},
      {"dbg_lvl",required_argument,0,'D'},
      {"dimension",required_argument,0,'d'},
      {"dmn",required_argument,0,'d'},
      {"fortran",no_argument,0,'F'},
      {"ftn",no_argument,0,'F'},
      {"fl_lst_in",no_argument,0,'H'},
      {"file_list",no_argument,0,'H'},
      {"history",no_argument,0,'h'},
      {"hst",no_argument,0,'h'},
      {"dfl_lvl",required_argument,0,'L'}, /* [enm] Deflate level */
      {"deflate",required_argument,0,'L'}, /* [enm] Deflate level */
      {"local",required_argument,0,'l'},
      {"lcl",required_argument,0,'l'},
      {"nintap",required_argument,0,'n'},
      {"overwrite",no_argument,0,'O'},
      {"ovr",no_argument,0,'O'},
      {"output",required_argument,0,'o'},
      {"fl_out",required_argument,0,'o'},
      {"path",required_argument,0,'p'},
      {"pack",required_argument,0,'P'},
      {"retain",no_argument,0,'R'},
      {"rtn",no_argument,0,'R'},
      {"revision",no_argument,0,'r'},
      {"thr_nbr",required_argument,0,'t'},
      {"threads",required_argument,0,'t'},
      {"omp_num_threads",required_argument,0,'t'},
      {"variable",required_argument,0,'v'},
      {"auxiliary",required_argument,0,'X'},
      {"exclude",no_argument,0,'x'},
      {"xcl",no_argument,0,'x'},
      {"pseudonym",required_argument,0,'Y'},
      {"program",required_argument,0,'Y'},
      {"prg_nm",required_argument,0,'Y'},
      {"math",required_argument,0,'y'},
      {"help",no_argument,0,'?'},
      {0,0,0,0}
    }; /* end opt_lng */
  int opt_idx=0; /* Index of current long option into opt_lng array */

#ifdef _LIBINTL_H
  setlocale(LC_ALL,""); /* LC_ALL sets all localization tokens to same value */
  bindtextdomain("nco","/home/zender/share/locale"); /* ${LOCALEDIR} is e.g., /usr/share/locale */
  /* MO files should be in ${LOCALEDIR}/es/LC_MESSAGES */
  textdomain("nco"); /* PACKAGE is name of program */
#endif /* not _LIBINTL_H */

  /* Start timer and save command line */ 
  ddra_info.tmr_flg=nco_tmr_srt;
  rcd+=nco_ddra((char *)NULL,(char *)NULL,&ddra_info);
  ddra_info.tmr_flg=nco_tmr_mtd;
  cmd_ln=nco_cmd_ln_sng(argc,argv);
  
  /* Get program name and set program enum (e.g., prg=ncra) */
  prg_nm=prg_prs(argv[0],&prg);

  /* Parse command line arguments */
  while(1){
    /* getopt_long_only() allows one dash to prefix long options */
    opt=getopt_long(argc,argv,opt_sht_lst,opt_lng,&opt_idx);
    /* NB: access to opt_crr is only valid when long_opt is detected */
    if(opt == EOF) break; /* Parse positional arguments once getopt_long() returns EOF */
    opt_crr=(char *)strdup(opt_lng[opt_idx].name);

    /* Process long options without short option counterparts */
    if(opt == 0){
      if(!strcmp(opt_crr,"bfr_sz_hnt") || !strcmp(opt_crr,"buffer_size_hint")){
	bfr_sz_hnt=strtoul(optarg,&sng_cnv_rcd,NCO_SNG_CNV_BASE10);
	if(*sng_cnv_rcd) nco_sng_cnv_err(optarg,"strtoul",sng_cnv_rcd);
      } /* endif cnk */
      if(!strcmp(opt_crr,"cnk_dmn") || !strcmp(opt_crr,"chunk_dimension")){
	/* Copy limit argument for later processing */
	cnk_arg[cnk_nbr]=(char *)strdup(optarg);
	cnk_nbr++;
      } /* endif cnk */
      if(!strcmp(opt_crr,"cnk_scl") || !strcmp(opt_crr,"chunk_scalar")){
	cnk_sz_scl=strtoul(optarg,&sng_cnv_rcd,NCO_SNG_CNV_BASE10);
	if(*sng_cnv_rcd) nco_sng_cnv_err(optarg,"strtoul",sng_cnv_rcd);
      } /* endif cnk */
      if(!strcmp(opt_crr,"cnk_map") || !strcmp(opt_crr,"chunk_map")){
	/* Chunking map */
	cnk_map_sng=(char *)strdup(optarg);
	cnk_map=nco_cnk_map_get(cnk_map_sng);
      } /* endif cnk */
      if(!strcmp(opt_crr,"cnk_plc") || !strcmp(opt_crr,"chunk_policy")){
	/* Chunking policy */
	cnk_plc_sng=(char *)strdup(optarg);
	cnk_plc=nco_cnk_plc_get(cnk_plc_sng);
      } /* endif cnk */
      if(!strcmp(opt_crr,"cln") || !strcmp(opt_crr,"mmr_cln") || !strcmp(opt_crr,"clean")) flg_cln=True; /* [flg] Clean memory prior to exit */
      if(!strcmp(opt_crr,"drt") || !strcmp(opt_crr,"mmr_drt") || !strcmp(opt_crr,"dirty")) flg_cln=False; /* [flg] Clean memory prior to exit */
      if(!strcmp(opt_crr,"fl_fmt") || !strcmp(opt_crr,"file_format")) rcd=nco_create_mode_prs(optarg,&fl_out_fmt);
      if(!strcmp(opt_crr,"md5_digest")){
	MD5_DIGEST=True;
	if(dbg_lvl >= nco_dbg_std) (void)fprintf(stderr,"%s: INFO Will perform MD5 digests of input and output hyperslabs\n",prg_nm_get());
      } /* endif "md5" */
      if(!strcmp(opt_crr,"msa_usr_rdr")) MSA_USR_RDR=True; /* [flg] Multi-slabbing algorithm leaves hyperslabs in user order */
      if(!strcmp(opt_crr,"ram_all") || !strcmp(opt_crr,"create_ram") || !strcmp(opt_crr,"diskless_all")) RAM_CREATE=True; /* [flg] Open (netCDF3) file(s) in RAM */
      if(!strcmp(opt_crr,"ram_all") || !strcmp(opt_crr,"open_ram") || !strcmp(opt_crr,"diskless_all")) RAM_OPEN=True; /* [flg] Create file in RAM */
      if(!strcmp(opt_crr,"vrs") || !strcmp(opt_crr,"version")){
	(void)nco_vrs_prn(CVS_Id,CVS_Revision);
	nco_exit(EXIT_SUCCESS);
      } /* endif "vrs" */
      if(!strcmp(opt_crr,"wrt_tmp_fl") || !strcmp(opt_crr,"write_tmp_fl")) WRT_TMP_FL=True;
      if(!strcmp(opt_crr,"no_tmp_fl")) WRT_TMP_FL=False;
    } /* opt != 0 */
    /* Process short options */
    switch(opt){
    case 0: /* Long options have already been processed, return */
      break;
    case '3': /* Request netCDF3 output storage format */
      fl_out_fmt=NC_FORMAT_CLASSIC;
      break;
    case '4': /* Catch-all to prescribe output storage format */
      if(!strcmp(opt_crr,"64bit")) fl_out_fmt=NC_FORMAT_64BIT; else fl_out_fmt=NC_FORMAT_NETCDF4; 
      break;
    case '6': /* Request netCDF3 64-bit offset output storage format */
      fl_out_fmt=NC_FORMAT_64BIT;
      break;
    case 'A': /* Toggle FORCE_APPEND */
      FORCE_APPEND=!FORCE_APPEND;
      break;
    case 'C': /* Extract all coordinates associated with extracted variables? */
      EXTRACT_ASSOCIATED_COORDINATES=False;
      break;
    case 'c':
      EXTRACT_ALL_COORDINATES=True;
      break;
    case 'D': /* Debugging level. Default is 0. */
      dbg_lvl=(unsigned short int)strtoul(optarg,&sng_cnv_rcd,NCO_SNG_CNV_BASE10);
      if(*sng_cnv_rcd) nco_sng_cnv_err(optarg,"strtoul",sng_cnv_rcd);
      break;
    case 'd': /* Copy limit argument for later processing */
      lmt_arg[lmt_nbr]=(char *)strdup(optarg);
      lmt_nbr++;
      break;
    case 'F': /* Toggle index convention. Default is 0-based arrays (C-style). */
      FORTRAN_IDX_CNV=!FORTRAN_IDX_CNV;
      break;
    case 'H': /* Toggle writing input file list attribute */
      FL_LST_IN_APPEND=!FL_LST_IN_APPEND;
      break;
    case 'h': /* Toggle appending to history global attribute */
      HISTORY_APPEND=!HISTORY_APPEND;
      break;
    case 'L': /* [enm] Deflate level. Default is 0. */
      dfl_lvl=(int)strtol(optarg,&sng_cnv_rcd,NCO_SNG_CNV_BASE10);
      if(*sng_cnv_rcd) nco_sng_cnv_err(optarg,"strtol",sng_cnv_rcd);
      break;
    case 'l': /* Local path prefix for files retrieved from remote file system */
      fl_pth_lcl=(char *)strdup(optarg);
      break;
    case 'n': /* NINTAP-style abbreviation of files to average */
      fl_lst_abb=nco_lst_prs_2D(optarg,",",&abb_arg_nbr);
      if(abb_arg_nbr < 1 || abb_arg_nbr > 5){
	(void)fprintf(stdout,gettext("%s: ERROR Incorrect abbreviation for file list\n"),prg_nm_get());
	(void)nco_usg_prn();
	nco_exit(EXIT_FAILURE);
      } /* end if */
      break;
    case 'O': /* Toggle FORCE_OVERWRITE */
      FORCE_OVERWRITE=!FORCE_OVERWRITE;
      break;
    case 'o': /* Name of output file */
      fl_out=(char *)strdup(optarg);
      break;
    case 'p': /* Common file path */
      fl_pth=(char *)strdup(optarg);
      break;
    case 'P': /* Packing policy */
      nco_pck_plc_sng=(char *)strdup(optarg);
      nco_pck_plc=nco_pck_plc_get(nco_pck_plc_sng);
      break;
    case 'R': /* Toggle removal of remotely-retrieved-files. Default is True. */
      RM_RMT_FL_PST_PRC=!RM_RMT_FL_PST_PRC;
      break;
    case 'r': /* Print CVS program information and copyright notice */
      (void)nco_vrs_prn(CVS_Id,CVS_Revision);
      (void)nco_lbr_vrs_prn();
      (void)nco_cpy_prn();
      (void)nco_cnf_prn();
      nco_exit(EXIT_SUCCESS);
      break;
    case 't': /* Thread number */
      thr_nbr=(int)strtol(optarg,&sng_cnv_rcd,NCO_SNG_CNV_BASE10);
      if(*sng_cnv_rcd) nco_sng_cnv_err(optarg,"strtol",sng_cnv_rcd);
      break;
    case 'v': /* Variables to extract/exclude */
      /* Replace commas with hashes when within braces (convert back later) */
      optarg_lcl=(char *)strdup(optarg);
      (void)nco_lst_comma2hash(optarg_lcl);
      var_lst_in=nco_lst_prs_2D(optarg_lcl,",",&var_lst_in_nbr);
      optarg_lcl=(char *)nco_free(optarg_lcl);
      xtr_nbr=var_lst_in_nbr;
      break;
    case 'X': /* Copy auxiliary coordinate argument for later processing */
      aux_arg[aux_nbr]=(char *)strdup(optarg);
      aux_nbr++;
      MSA_USR_RDR=True; /* [flg] Multi-slabbing algorithm leaves hyperslabs in user order */      
      break;
    case 'x': /* Exclude rather than extract variables specified with -v */
      EXCLUDE_INPUT_LIST=True;
      break;
    case 'Y': /* Pseudonym */
      /* Call prg_prs to reset pseudonym */
      optarg_lcl=(char *)strdup(optarg);
      if(prg_nm) prg_nm=(char *)nco_free(prg_nm);
      prg_nm=prg_prs(optarg_lcl,&prg);
      optarg_lcl=(char *)nco_free(optarg_lcl);
      break;
    case 'y': /* Operation type */
      nco_op_typ_sng=(char *)strdup(optarg);
      if(prg == ncra || prg == ncea ) nco_op_typ=nco_op_typ_get(nco_op_typ_sng);
      break;
    case '?': /* Print proper usage */
      (void)nco_usg_prn();
      nco_exit(EXIT_SUCCESS);
      break;
    case '-': /* Long options are not allowed */
      (void)fprintf(stderr,"%s: ERROR Long options are not available in this build. Use single letter options instead.\n",prg_nm_get());
      nco_exit(EXIT_FAILURE);
      break;
    default: /* Print proper usage */
      (void)nco_usg_prn();
      nco_exit(EXIT_FAILURE);
      break;
    } /* end switch */
    if(opt_crr) opt_crr=(char *)nco_free(opt_crr);
  } /* end while loop */
  
  /* Process positional arguments and fill in filenames */
  fl_lst_in=nco_fl_lst_mk(argv,argc,optind,&fl_nbr,&fl_out,&FL_LST_IN_FROM_STDIN);

  /* Make uniform list of user-specified chunksizes */
  if(cnk_nbr > 0) cnk=nco_cnk_prs(cnk_nbr,cnk_arg);

  /* Make uniform list of user-specified dimension limits */
  if(lmt_nbr > 0) lmt=nco_lmt_prs(lmt_nbr,lmt_arg);
  
  /* Initialize thread information */
  thr_nbr=nco_openmp_ini(thr_nbr);
  in_id_arr=(int *)nco_malloc(thr_nbr*sizeof(int));

  /* Parse filename */
  fl_in=nco_fl_nm_prs(fl_in,0,&fl_nbr,fl_lst_in,abb_arg_nbr,fl_lst_abb,fl_pth);
  /* Make sure file is on local system and is readable or die trying */
  fl_in=nco_fl_mk_lcl(fl_in,fl_pth_lcl,&FL_RTR_RMT_LCN);
  /* Open file using appropriate buffer size hints and verbosity */
  if(RAM_OPEN) md_open=NC_NOWRITE|NC_DISKLESS; else md_open=NC_NOWRITE;
  rcd+=nco_fl_open(fl_in,md_open,&bfr_sz_hnt,&in_id);

  /* Parse auxiliary coordinates */
  if(aux_nbr > 0){
     int aux_idx_nbr;
     aux=nco_aux_evl(in_id,aux_nbr,aux_arg,&aux_idx_nbr);
     if(aux_idx_nbr > 0){
        lmt=(lmt_sct **)nco_realloc(lmt,(lmt_nbr+aux_idx_nbr)*sizeof(lmt_sct *));
        int lmt_nbr_new=lmt_nbr+aux_idx_nbr;
        int aux_idx=0;
        for(int lmt_idx=lmt_nbr;lmt_idx<lmt_nbr_new;lmt_idx++) lmt[lmt_idx]=aux[aux_idx++];
        lmt_nbr=lmt_nbr_new;
     } /* endif aux */
  } /* endif aux_nbr */
  
  /* Get number of variables, dimensions, and record dimension ID of input file */
  (void)nco_inq(in_id,&nbr_dmn_fl,&nbr_var_fl,(int *)NULL,&rec_dmn_id);
  (void)nco_inq_format(in_id,&fl_in_fmt);
  
  /* Form initial extraction list which may include extended regular expressions */
  xtr_lst=nco_var_lst_mk(in_id,nbr_var_fl,var_lst_in,EXCLUDE_INPUT_LIST,EXTRACT_ALL_COORDINATES,&xtr_nbr);

  /* Change included variables to excluded variables */
  if(EXCLUDE_INPUT_LIST) xtr_lst=nco_var_lst_xcl(in_id,nbr_var_fl,xtr_lst,&xtr_nbr);

  /* Is this a CCM/CCSM/CF-format history tape? */
  CNV_CCM_CCSM_CF=nco_cnv_ccm_ccsm_cf_inq(in_id);

  /* Add all coordinate variables to extraction list */
  if(EXTRACT_ALL_COORDINATES) xtr_lst=nco_var_lst_crd_add(in_id,nbr_dmn_fl,nbr_var_fl,xtr_lst,&xtr_nbr,CNV_CCM_CCSM_CF);

  /* Extract coordinates associated with extracted variables */
  if(EXTRACT_ASSOCIATED_COORDINATES) xtr_lst=nco_var_lst_crd_ass_add(in_id,xtr_lst,&xtr_nbr,CNV_CCM_CCSM_CF);

  /* Sort extraction list by variable ID for fastest I/O */
  if(xtr_nbr > 1) xtr_lst=nco_lst_srt_nm_id(xtr_lst,xtr_nbr,False);

  /* We now have final list of variables to extract. Phew. */
  
  /* Find coordinate/dimension values associated with user-specified limits
     NB: nco_lmt_evl() with same nc_id contains OpenMP critical region */
  for(idx=0;idx<lmt_nbr;idx++) (void)nco_lmt_evl(in_id,lmt[idx],0L,FORTRAN_IDX_CNV);

  /* Place all dimensions in lmt_all_lst */
  lmt_all_lst=(lmt_all_sct **)nco_malloc(nbr_dmn_fl*sizeof(lmt_all_sct *));
  /* Initialize lmt_all_sct's */ 
  (void)nco_msa_lmt_all_int(in_id,MSA_USR_RDR,lmt_all_lst,nbr_dmn_fl,lmt,lmt_nbr);

  /* Find dimensions associated with variables to be extracted */
  dmn_lst=nco_dmn_lst_ass_var(in_id,xtr_lst,xtr_nbr,&nbr_dmn_xtr);

  /* Fill-in dimension structure for all extracted dimensions */
  dim=(dmn_sct **)nco_malloc(nbr_dmn_xtr*sizeof(dmn_sct *));
  for(idx=0;idx<nbr_dmn_xtr;idx++) dim[idx]=nco_dmn_fll(in_id,dmn_lst[idx].id,dmn_lst[idx].nm);
  /* Dimension list no longer needed */
  dmn_lst=nco_nm_id_lst_free(dmn_lst,nbr_dmn_xtr);

  /* Duplicate input dimension structures for output dimension structures */
  dmn_out=(dmn_sct **)nco_malloc(nbr_dmn_xtr*sizeof(dmn_sct *));
  for(idx=0;idx<nbr_dmn_xtr;idx++){ 
    dmn_out[idx]=nco_dmn_dpl(dim[idx]);
    (void)nco_dmn_xrf(dim[idx],dmn_out[idx]);
  } /* end loop over dimensions */

  /* Merge hyperslab limit information into dimension structures */
  if(nbr_dmn_fl > 0) (void)nco_dmn_lmt_all_mrg(dmn_out,nbr_dmn_xtr,lmt_all_lst,nbr_dmn_fl); 
  
  /* Create stand-alone limit structure just for record dimension */
  if(rec_dmn_id == NCO_REC_DMN_UNDEFINED){
    if(prg == ncra || prg == ncrcat){
      (void)fprintf(stdout,gettext("%s: ERROR input file %s lacks a record dimension\n"),prg_nm_get(),fl_in);
      if(fl_nbr == 1)(void)fprintf(stdout,gettext("%s: HINT Use ncks instead of %s\n"),prg_nm_get(),prg_nm_get());
      nco_exit(EXIT_FAILURE);
    } /* endif */
  }else{ /* Record dimension exists */
    lmt_rec=nco_lmt_sct_mk(in_id,rec_dmn_id,lmt,lmt_nbr,FORTRAN_IDX_CNV);
    /* Initialize record coordinate re-basing */
    if(prg == ncra || prg == ncrcat){
      int var_id;
      
      lmt_rec->lmt_cln=cln_nil; 
      lmt_rec->origin=0.0; 
      lmt_rec->rbs_sng=NULL;

      /* Obtain record coordinate metadata */
      rcd=nco_inq_varid_flg(in_id,lmt_rec->nm,&var_id);
      if(rcd == NC_NOERR){ 
	char *cln_att_sng=NULL;
	lmt_rec->rbs_sng=nco_lmt_get_udu_att(in_id,var_id,"units"); 
	cln_att_sng=nco_lmt_get_udu_att(in_id,var_id,"calendar"); 
	lmt_rec->lmt_cln=nco_cln_get_cln_typ(cln_att_sng); 
	if(cln_att_sng) cln_att_sng=(char*)nco_free(cln_att_sng);  
      }else{ /* endif record coordinate exists */
	/* Record dimension, but not record coordinate, exists, which is fine. Reset return code. */
	rcd=NC_NOERR;
      } /* endif record coordinate exists */
    } /* endif ncra, ncrcat */
  } /* endif record dimension exists */
  
  if(rec_dmn_id != NCO_REC_DMN_UNDEFINED){
    for(idx=0;idx<nbr_dmn_fl;idx++){
      if(!strcmp(lmt_rec->nm,lmt_all_lst[idx]->dmn_nm)){
        lmt_all_rec=lmt_all_lst[idx];
	/* Can only have one record limit */
        if(lmt_all_rec->lmt_dmn_nbr > 1L){
	  (void)fprintf(stdout,"%s: Although this program allows multiple hyperslab limits for a single dimension, it allows only one unwrapped limit for the record dimension \"%s\". You have specified %i.\n",prg_nm_get(),lmt_all_rec->dmn_nm,lmt_all_rec->lmt_dmn_nbr);
	  nco_exit(EXIT_FAILURE);
	} /* end if */
        if(prg==ncra || prg==ncrcat){
	  /* Change record dimension in lmt_all_lst so that cnt=1 */
	  lmt_all_rec->dmn_cnt=1L;
	  lmt_all_rec->lmt_dmn[0]->srt=0L;
	  lmt_all_rec->lmt_dmn[0]->end=0L;           
	  lmt_all_rec->lmt_dmn[0]->cnt=1L;                   
	  lmt_all_rec->lmt_dmn[0]->srd=1L;
	  lmt_all_rec->lmt_dmn[0]->drn=1L;
	} /* endif ncra || ncrcat */
	break;
      } /* endif current limit applies to record dimension */
    } /* end loop over all dimensions */
  } /* end if file has record dimension */
  
  /* Is this an ARM-format data file? */
  CNV_ARM=nco_cnv_arm_inq(in_id);
  /* NB: nco_cnv_arm_base_time_get() with same nc_id contains OpenMP critical region */
  if(CNV_ARM) base_time_srt=nco_cnv_arm_base_time_get(in_id);

  /* Fill-in variable structure list for all extracted variables */
  var=(var_sct **)nco_malloc(xtr_nbr*sizeof(var_sct *));
  var_out=(var_sct **)nco_malloc(xtr_nbr*sizeof(var_sct *));
  for(idx=0;idx<xtr_nbr;idx++){
    var[idx]=nco_var_fll(in_id,xtr_lst[idx].id,xtr_lst[idx].nm,dim,nbr_dmn_xtr);
    var_out[idx]=nco_var_dpl(var[idx]);
    (void)nco_xrf_var(var[idx],var_out[idx]);
    (void)nco_xrf_dmn(var_out[idx]);
  } /* end loop over idx */

  /* Extraction list no longer needed */
  xtr_lst=nco_nm_id_lst_free(xtr_lst,xtr_nbr);

  /* Refresh var_out with dim_out data */
  (void)nco_var_dmn_refresh(var_out,xtr_nbr);

  /* Divide variable lists into lists of fixed variables and variables to be processed */
  (void)nco_var_lst_dvd(var,var_out,xtr_nbr,CNV_CCM_CCSM_CF,nco_pck_plc_nil,nco_pck_map_nil,NULL,0,&var_fix,&var_fix_out,&nbr_var_fix,&var_prc,&var_prc_out,&nbr_var_prc);

  /* Make output and input files consanguinous */
  if(fl_out_fmt == NCO_FORMAT_UNDEFINED) fl_out_fmt=fl_in_fmt;

  /* Verify output file format supports requested actions */
  (void)nco_fl_fmt_vet(fl_out_fmt,cnk_nbr,dfl_lvl);

  /* Open output file */
  fl_out_tmp=nco_fl_out_open(fl_out,FORCE_APPEND,FORCE_OVERWRITE,fl_out_fmt,&bfr_sz_hnt,RAM_CREATE,RAM_OPEN,WRT_TMP_FL,&out_id);

  /* Copy global attributes */
  (void)nco_att_cpy(in_id,out_id,NC_GLOBAL,NC_GLOBAL,(nco_bool)True);
  
  /* Catenate time-stamped command line to "history" global attribute */
  if(HISTORY_APPEND) (void)nco_hst_att_cat(out_id,cmd_ln);

  /* Add input file list global attribute */
  if(FL_LST_IN_APPEND && HISTORY_APPEND && FL_LST_IN_FROM_STDIN) (void)nco_fl_lst_att_cat(out_id,fl_lst_in,fl_nbr);

  if(thr_nbr > 0 && HISTORY_APPEND) (void)nco_thr_att_cat(out_id,thr_nbr);
  
  /* Define dimensions in output file */
  (void)nco_dmn_dfn(fl_out,out_id,dmn_out,nbr_dmn_xtr);

  /* Define variables in output file, copy their attributes */
  (void)nco_var_dfn(in_id,fl_out,out_id,var_out,xtr_nbr,(dmn_sct **)NULL,(int)0,nco_pck_plc_nil,nco_pck_map_nil,dfl_lvl);

  /* Set chunksize parameters */
  if(fl_out_fmt == NC_FORMAT_NETCDF4 || fl_out_fmt == NC_FORMAT_NETCDF4_CLASSIC) (void)nco_cnk_sz_set(out_id,lmt_all_lst,nbr_dmn_fl,&cnk_map,&cnk_plc,cnk_sz_scl,cnk,cnk_nbr);

  /* Turn off default filling behavior to enhance efficiency */
  (void)nco_set_fill(out_id,NC_NOFILL,&fll_md_old);
  
  /* Take output file out of define mode */
  (void)nco_enddef(out_id);
  
  /* Zero start and stride vectors for all output variables */
  (void)nco_var_srd_srt_set(var_out,xtr_nbr);

  /* Copy variable data for non-processed variables */
  /* (void)nco_var_val_cpy(in_id,out_id,var_fix,nbr_var_fix); */
  (void)nco_msa_var_val_cpy(in_id,out_id,var_fix,nbr_var_fix,lmt_all_lst,nbr_dmn_fl);

  /* Close first input netCDF file */
  (void)nco_close(in_id);
  
  /* Allocate and, if necesssary, initialize accumulation space for processed variables */
  for(idx=0;idx<nbr_var_prc;idx++){
    if(prg == ncra || prg == ncrcat){
      /* Allocate space for only one record */
      var_prc[idx]->sz=var_prc[idx]->sz_rec=var_prc_out[idx]->sz=var_prc_out[idx]->sz_rec;
    } /* endif */
    if(prg == ncra || prg == ncea){
      var_prc_out[idx]->tally=var_prc[idx]->tally=(long *)nco_malloc(var_prc_out[idx]->sz*sizeof(long));
      var_prc_out[idx]->val.vp=(void *)nco_malloc(var_prc_out[idx]->sz*nco_typ_lng(var_prc_out[idx]->type));
      if(prg == ncea){
	(void)nco_zero_long(var_prc_out[idx]->sz,var_prc_out[idx]->tally);
	(void)nco_var_zero(var_prc_out[idx]->type,var_prc_out[idx]->sz,var_prc_out[idx]->val);
      } /* end if ncea */
    } /* end if */
  } /* end loop over idx */

  /* Timestamp end of metadata setup and disk layout */
  rcd+=nco_ddra((char *)NULL,(char *)NULL,&ddra_info);
  ddra_info.tmr_flg=nco_tmr_rgl;

  /* Loop over input files */
  for(fl_idx=0;fl_idx<fl_nbr;fl_idx++){
    /* Parse filename */
    if(fl_idx != 0) fl_in=nco_fl_nm_prs(fl_in,fl_idx,(int *)NULL,fl_lst_in,abb_arg_nbr,fl_lst_abb,fl_pth);
    if(dbg_lvl >= nco_dbg_fl) (void)fprintf(stderr,gettext("%s: INFO Input file %d is %s"),prg_nm_get(),fl_idx,fl_in);
    /* Make sure file is on local system and is readable or die trying */
    if(fl_idx != 0) fl_in=nco_fl_mk_lcl(fl_in,fl_pth_lcl,&FL_RTR_RMT_LCN);
    if(dbg_lvl >= nco_dbg_fl && FL_RTR_RMT_LCN) (void)fprintf(stderr,gettext(", local file is %s"),fl_in);
    if(dbg_lvl >= nco_dbg_fl) (void)fprintf(stderr,"\n");

    /* Open file once per thread to improve caching */
    for(thr_idx=0;thr_idx<thr_nbr;thr_idx++) rcd+=nco_fl_open(fl_in,NC_NOWRITE,&bfr_sz_hnt,in_id_arr+thr_idx);
    in_id=in_id_arr[0];
    
    /* Variables may have different ID, missing_value, type, in each file */
    for(idx=0;idx<nbr_var_prc;idx++) (void)nco_var_mtd_refresh(in_id,var_prc[idx]);
    
    /* Files may have different numbers of records to process
       NB: nco_lmt_evl() with same nc_id contains OpenMP critical region */
    if(rec_dmn_id != NCO_REC_DMN_UNDEFINED) (void)nco_lmt_evl(in_id,lmt_rec,rec_usd_cml,FORTRAN_IDX_CNV);
    if(lmt_rec->flg_mro) FLG_MRO=True;
    
    /* NB: nco_cnv_arm_base_time_get() with same nc_id contains OpenMP critical region */
    if(CNV_ARM) base_time_crr=nco_cnv_arm_base_time_get(in_id);
    
    /* Perform various error-checks on input file */
    if(False) (void)nco_fl_cmp_err_chk();
    
    if(dbg_lvl >= nco_dbg_std && (rec_dmn_id != NCO_REC_DMN_UNDEFINED) && (lmt_rec->srt > lmt_rec->end) && lmt_rec->rec_rmn_prv_drn) (void)fprintf(fp_stdout,gettext("%s: WARNING %s (input file %d) is superfluous\n"),prg_nm_get(),fl_in,fl_idx);
	
    if(prg == ncra || prg == ncrcat){ /* ncea jumps to else branch */

      rec_dmn_sz=lmt_rec->rec_dmn_sz;
      rec_rmn_prv_drn=lmt_rec->rec_rmn_prv_drn; /* Local copy may be decremented later */
      idx_rec_crr_in= (rec_rmn_prv_drn > 0L) ? 0L : lmt_rec->srt;

      // Master loop over records in current file
      while(idx_rec_crr_in >= 0L && idx_rec_crr_in < rec_dmn_sz){

	if(idx_rec_crr_in >= lmt_rec->end) LAST_STRIDE_IN_FILE=True; else LAST_STRIDE_IN_FILE=False;
	/* Even strides commence group beginnings */
	if(rec_rmn_prv_drn == 0L) FIRST_RECORD_OF_CURRENT_GROUP=True;
	/* Each group comprises DRN records */
	if(FIRST_RECORD_OF_CURRENT_GROUP) rec_rmn_prv_drn=lmt_rec->drn;

	if(fl_idx == fl_nbr-1 && idx_rec_crr_in == min_int(lmt_rec->end+lmt_rec->drn-1L,rec_dmn_sz-1L)) FINAL_DESIRED_RECORD_FROM_ALL_INPUT_FILES=True;

	/* Index juggling:
	   idx_rec_crr_in: Index of current record in current input file (increments by 1 for drn then srd-drn ...)
	   rec_usd_cml: Cumulative number of input records used (catenated by ncrcat or operated on by ncra)
	   lmt_rec->rec_rmn_prv_drn: Structure member, at start of this while loop, contains records remaining-to-be-read to complete duration group from previous file. Structure member remains constant until next file is read.
	   rec_rmn_prv_drn: Local copy initialized from lmt_rec structure member begins with above, and then is set to and tracks number of records rbbemaining remaining in current group. This means it is decremented from drn_nbr->0 for each group contained in current file.
	   idx_rec_out: Index of record in output file */
	
	/* ncra normalization/writing code must know last record in current group (LRCG) for both MRO and non-MRO */
	if(rec_rmn_prv_drn == 1L) LAST_RECORD_OF_CURRENT_GROUP=True; else LAST_RECORD_OF_CURRENT_GROUP=False;

	/* Process all variables in current record */
	if(dbg_lvl >= nco_dbg_scl) (void)fprintf(fp_stderr,gettext("Record %ld of %s contributes to output record %ld\n"),idx_rec_crr_in,fl_in,idx_rec_out);
	
	/* Update hyperslab start indices */
	/* Beware lmt_all_rec points to record limit of record struct of lmt_all_lst */
	lmt_all_rec->lmt_dmn[0]->srt=idx_rec_crr_in;
	lmt_all_rec->lmt_dmn[0]->end=idx_rec_crr_in;
	lmt_all_rec->lmt_dmn[0]->cnt=1L;
	lmt_all_rec->lmt_dmn[0]->srd=1L;   
	
#ifdef _OPENMP
#pragma omp parallel for default(none) private(idx,in_id) shared(CNV_ARM,base_time_crr,base_time_srt,dbg_lvl,fl_in,fl_out,idx_rec_crr_in,idx_rec_out,rec_usd_cml,in_id_arr,FIRST_RECORD_OF_CURRENT_GROUP,FINAL_DESIRED_RECORD_FROM_ALL_INPUT_FILES,lmt_rec,MD5_DIGEST,nbr_var_prc,nco_op_typ,FLG_BFR_NEEDS_NRM,FLG_MRO,out_id,prg,rcd,var_prc,var_prc_out,lmt_all_lst,nbr_dmn_fl)
#endif /* !_OPENMP */
	for(idx=0;idx<nbr_var_prc;idx++){
	  in_id=in_id_arr[omp_get_thread_num()];
	  if(dbg_lvl >= nco_dbg_var) rcd+=nco_var_prc_crr_prn(idx,var_prc[idx]->nm);
	  if(dbg_lvl >= nco_dbg_var) (void)fflush(fp_stderr);
	  
	  /* Retrieve variable from disk into memory */
	  /* NB: nco_var_get() with same nc_id contains OpenMP critical region */
	  (void)nco_msa_var_get(in_id,var_prc[idx],lmt_all_lst,nbr_dmn_fl);
	  if(prg == ncra) FLG_BFR_NEEDS_NRM=True; /* [flg] Current output buffers need normalization */
	  
	  /* Re-base record coordinate if necessary */
	  if(var_prc[idx]->is_crd_var && lmt_rec->origin != 0.0){
	    var_sct *var_crd;
	    scv_sct scv;
	    /* De-reference */
	    var_crd=var_prc[idx];
	    scv.val.d=lmt_rec->origin;              
	    scv.type=NC_DOUBLE;  
	    /* Convert scalar to variable type */
	    nco_scv_cnf_typ(var_crd->type,&scv);
	    (void)var_scv_add(var_crd->type,var_crd->sz,var_crd->has_mss_val,var_crd->mss_val,var_crd->val,&scv);
	  } /* end re-basing */
	  
	  if(prg == ncra){
	    /* Initialize tally and accumulation arrays when appropriate */
	    if(!rec_usd_cml || (FLG_MRO && FIRST_RECORD_OF_CURRENT_GROUP)){
	      (void)nco_zero_long(var_prc_out[idx]->sz,var_prc_out[idx]->tally);
	      (void)nco_var_zero(var_prc_out[idx]->type,var_prc_out[idx]->sz,var_prc_out[idx]->val);
	    } /* end if FIRST_RECORD_OF_CURRENT_GROUP */
	    
            /* Do not promote un-averagable types (NC_CHAR, NC_STRING)
	       Stuff first record into output buffer regardless of nco_op_typ; ignore later records (rec_usd_cml > 1)
	       Temporarily fixes TODO nco941 */
	    if(var_prc[idx]->type == NC_CHAR){
	      if(!rec_usd_cml || (FLG_MRO && FIRST_RECORD_OF_CURRENT_GROUP)) nco_opr_drv((long)(!FIRST_RECORD_OF_CURRENT_GROUP),nco_op_min,var_prc[idx],var_prc_out[idx]);
              }else{
	      /* Convert char, short, long, int types to doubles before arithmetic
		 Output variable type is "sticky" so only convert on first record */
	      if(!rec_usd_cml || (FLG_MRO && FIRST_RECORD_OF_CURRENT_GROUP)) var_prc_out[idx]=nco_typ_cnv_rth(var_prc_out[idx],nco_op_typ);
	      var_prc[idx]=nco_var_cnf_typ(var_prc_out[idx]->type,var_prc[idx]);
	      /* Perform arithmetic operations: avg, min, max, ttl, ... */
	      nco_opr_drv((long)(!FIRST_RECORD_OF_CURRENT_GROUP),nco_op_typ,var_prc[idx],var_prc_out[idx]);
	    } /* end else */ 
	  } /* end if ncra */
	    
	  /* All processed variables contain record dimension and both ncrcat and ncra write records singly */
	  var_prc_out[idx]->srt[0]=var_prc_out[idx]->end[0]=idx_rec_out;
	  var_prc_out[idx]->cnt[0]=1L;

	  /* Append current record to output file */
	  if(prg == ncrcat){
	    /* Replace this time_offset value with time_offset from initial file base_time */
	    if(CNV_ARM && !strcmp(var_prc[idx]->nm,"time_offset")) var_prc[idx]->val.dp[0]+=(base_time_crr-base_time_srt);
#ifdef _OPENMP
#pragma omp critical
#endif /* _OPENMP */
	    if(var_prc_out[idx]->sz_rec > 1L) (void)nco_put_vara(out_id,var_prc_out[idx]->id,var_prc_out[idx]->srt,var_prc_out[idx]->cnt,var_prc[idx]->val.vp,var_prc_out[idx]->type); else (void)nco_put_var1(out_id,var_prc_out[idx]->id,var_prc_out[idx]->srt,var_prc[idx]->val.vp,var_prc_out[idx]->type);
	    /* Perform MD5 digest of input and output data if requested */
	    if(MD5_DIGEST) (void)nco_md5_chk(var_prc_out[idx]->nm,var_prc_out[idx]->sz*nco_typ_lng(var_prc_out[idx]->type),out_id,var_prc_out[idx]->srt,var_prc_out[idx]->cnt,var_prc[idx]->val.vp);
	  } /* end if ncrcat */
	    
	  /* Warn if record coordinate, if any, is not monotonic */
	  if(prg == ncrcat && var_prc[idx]->is_crd_var) (void)rec_crd_chk(var_prc[idx],fl_in,fl_out,idx_rec_crr_in,idx_rec_out);
	  /* Convert missing_value, if any, back to unpacked type
	     Otherwise missing_value will be double-promoted when next record read 
	     Do not convert after last record otherwise normalization fails 
	     due to wrong missing_value type (needs promoted type, not unpacked type) */
	  if(var_prc[idx]->has_mss_val && var_prc[idx]->type != var_prc[idx]->typ_upk && !FINAL_DESIRED_RECORD_FROM_ALL_INPUT_FILES) var_prc[idx]=nco_cnv_mss_val_typ(var_prc[idx],var_prc[idx]->typ_upk);
	  /* Free current input buffer */
	  var_prc[idx]->val.vp=nco_free(var_prc[idx]->val.vp);
	} /* end (OpenMP parallel for) loop over variables */

	if(prg == ncra && ((FLG_MRO && LAST_RECORD_OF_CURRENT_GROUP) || FINAL_DESIRED_RECORD_FROM_ALL_INPUT_FILES)){
	  /* Normalize, multiply, etc where necessary: ncra and ncea normalization blocks are identical, 
	     except ncra normalizes after every drn records, while ncea normalizes once, after files loop. */
	  (void)nco_opr_nrm(nco_op_typ,nbr_var_prc,var_prc,var_prc_out);
	  FLG_BFR_NEEDS_NRM=False; /* [flg] Current output buffers need normalization */
	  
	  /* Copy averages to output file */
	  for(idx=0;idx<nbr_var_prc;idx++){
	    var_prc_out[idx]=nco_var_cnf_typ(var_prc_out[idx]->typ_upk,var_prc_out[idx]);
	    /* Packing/Unpacking */
	    if(nco_pck_plc == nco_pck_plc_all_new_att) var_prc_out[idx]=nco_put_var_pck(out_id,var_prc_out[idx],nco_pck_plc);
	    if(var_prc_out[idx]->nbr_dim == 0) (void)nco_put_var1(out_id,var_prc_out[idx]->id,var_prc_out[idx]->srt,var_prc_out[idx]->val.vp,var_prc_out[idx]->type); else (void)nco_put_vara(out_id,var_prc_out[idx]->id,var_prc_out[idx]->srt,var_prc_out[idx]->cnt,var_prc_out[idx]->val.vp,var_prc_out[idx]->type);
	  } /* end loop over idx */
	  idx_rec_out++; /* [idx] Index of current record in output file (0 is first, ...) */
	} /* end if normalize and write */

	/* Prepare indices and flags for next iteration */
	FIRST_RECORD_OF_CURRENT_GROUP=False;
	if(prg == ncrcat) idx_rec_out++; /* [idx] Index of current record in output file (0 is first, ...) */
	rec_usd_cml++; /* [nbr] Cumulative number of input records used (catenated by ncrcat or operated on by ncra) */
	if(dbg_lvl >= nco_dbg_var) (void)fprintf(fp_stderr,"\n");

	/* Finally, set index for next record or get outta' Dodge */
	if(LAST_STRIDE_IN_FILE){
	  long max_end; /* fxm need information about whether original, user-specified end was truncated... */
	  if(False) max_end=lmt_rec->end; else max_end=min_lng(lmt_rec->end+lmt_rec->drn-1L,rec_dmn_sz-1L);
	  if(--rec_rmn_prv_drn > 0L && idx_rec_crr_in < max_end) idx_rec_crr_in++; else break;
	}else{ /* !LAST_STRIDE_IN_FILE */
	  if(--rec_rmn_prv_drn > 0L) idx_rec_crr_in++; else idx_rec_crr_in+=lmt_rec->srd-lmt_rec->drn+1L;
	} /* !LAST_STRIDE_IN_FILE */

      } /* end master while loop over records in current file */

      if(fl_idx == fl_nbr-1){
	/* Warn if other than number of requested records were read */
	if(lmt_rec->lmt_typ == lmt_dmn_idx && lmt_rec->is_usr_spc_min && lmt_rec->is_usr_spc_max){
	  long drn_grp_nbr_max; /* [nbr] Duration groups that start within range */
	  long rec_nbr_rqs; /* Number of records user requested */
	  long rec_nbr_rqs_max; /* [nbr] Records that would be used by drn_grp_nbr_max groups */
	  long rec_nbr_spn_act; /* [nbr] Records available within user-specified range */
	  long rec_nbr_spn_max; /* [nbr] Minimum record number spanned by drn_grp_nbr_max groups */
	  long rec_nbr_trn; /* [nbr] Records truncated in last group */
	  long srd_nbr_flr; /* [nbr] Whole strides that fit within specified range */
	  /* Number of whole strides that fit within specified range */
	  srd_nbr_flr=(lmt_rec->max_idx-lmt_rec->min_idx)/lmt_rec->srd;
	  drn_grp_nbr_max=1L+srd_nbr_flr;
	  /* Number of records that would be used by N groups */
	  rec_nbr_rqs_max=drn_grp_nbr_max*lmt_rec->drn;
	  /* Minimum record number spanned by N groups of size D is N-1 strides, plus D-1 trailing members of last group */
	  rec_nbr_spn_max=lmt_rec->srd*(drn_grp_nbr_max-1L)+lmt_rec->drn;
	  /* Actual number of records available within range */
	  rec_nbr_spn_act=1L+lmt_rec->max_idx-lmt_rec->min_idx;
	  /* Number truncated in last group */
	  rec_nbr_trn=max_int(rec_nbr_spn_max-rec_nbr_spn_act,0L);
	  /* Records requested is maximum minus any truncated in last group */
	  rec_nbr_rqs=rec_nbr_rqs_max-rec_nbr_trn;
	  if(rec_nbr_rqs != rec_usd_cml) (void)fprintf(fp_stdout,gettext("%s: WARNING User requested %li records but only %li were found and used\n"),prg_nm_get(),rec_nbr_rqs,rec_usd_cml);
	} /* end if */
	/* ... and die if no records were read ... */
	if(rec_usd_cml <= 0){
	  (void)fprintf(fp_stdout,gettext("%s: ERROR No records lay within specified hyperslab\n"),prg_nm_get());
	  nco_exit(EXIT_FAILURE);
	} /* end if */
      } /* end if */

      /* End of ncra, ncrcat section */
    }else{ /* ncea */

      if(rec_dmn_id != NCO_REC_DMN_UNDEFINED){
	/* Update hyperslab start indices*/			
	lmt_all_rec->lmt_dmn[0]->srt=lmt_rec->srt;
	lmt_all_rec->lmt_dmn[0]->end=lmt_rec->end;
	lmt_all_rec->lmt_dmn[0]->cnt=lmt_rec->cnt;
	lmt_all_rec->lmt_dmn[0]->srd=lmt_rec->srd; 
	lmt_all_rec->dmn_cnt=lmt_rec->cnt; 
      } /* endif record dimension exists */
#ifdef _OPENMP
#pragma omp parallel for default(none) private(idx,in_id) shared(dbg_lvl,fl_idx,FLG_BFR_NEEDS_NRM,in_id_arr,lmt_rec,nbr_var_prc,nco_op_typ,rcd,var_prc,var_prc_out,lmt_all_lst,nbr_dmn_fl)
#endif /* !_OPENMP */
      for(idx=0;idx<nbr_var_prc;idx++){ /* Process all variables in current file */
	in_id=in_id_arr[omp_get_thread_num()];
	if(dbg_lvl >= nco_dbg_var) rcd+=nco_var_prc_crr_prn(idx,var_prc[idx]->nm);
	if(dbg_lvl >= nco_dbg_var) (void)fflush(fp_stderr);
	
	/* Retrieve variable from disk into memory */
	(void)nco_msa_var_get(in_id,var_prc[idx],lmt_all_lst,nbr_dmn_fl);
	
	/* Convert char, short, long, int types to doubles before arithmetic
	   Output variable type is "sticky" so only convert on first record */
	if(fl_idx == 0) var_prc_out[idx]=nco_typ_cnv_rth(var_prc_out[idx],nco_op_typ);
	var_prc[idx]=nco_var_cnf_typ(var_prc_out[idx]->type,var_prc[idx]);
	/* Perform arithmetic operations: avg, min, max, ttl, ... */ /* Note: fl_idx not rec_usd_cml! */
	nco_opr_drv(fl_idx,nco_op_typ,var_prc[idx],var_prc_out[idx]);
	FLG_BFR_NEEDS_NRM=True; /* [flg] Current output buffers need normalization */
	
	/* Free current input buffer */
	var_prc[idx]->val.vp=nco_free(var_prc[idx]->val.vp);
      } /* end (OpenMP parallel for) loop over idx */
    } /* end else ncea */
    
    if(dbg_lvl >= nco_dbg_scl) (void)fprintf(fp_stderr,"\n");
    
    /* Close input netCDF file */
    for(thr_idx=0;thr_idx<thr_nbr;thr_idx++) nco_close(in_id_arr[thr_idx]);
    
    /* Dispose local copy of file */
    if(FL_RTR_RMT_LCN && RM_RMT_FL_PST_PRC) (void)nco_fl_rm(fl_in);
    
    /* Do not bother to open more input files */
    if(lmt_rec->flg_input_complete){
      if(dbg_lvl >= nco_dbg_fl) (void)fprintf(fp_stderr,"%s: All requested data have been read, remaining %d input files will not be opened\n",prg_nm_get(),fl_nbr-fl_idx);
      continue;
    } /* endif dbg */

  } /* end loop over fl_idx */
  
  /* Normalize, multiply, etc where necessary: ncra and ncea normalization blocks are identical, 
     except ncra normalizes after every DRN records, while ncea normalizes once, after all files.
     Occassionally the last input file ends mid-group, or contains no valid records
     In such cases ncra has accumulated an irregular number of records to normalize
     FLG_BFR_NEEDS_NRM is true in such cases, and is always true for ncea */
  if(FLG_BFR_NEEDS_NRM) (void)nco_opr_nrm(nco_op_typ,nbr_var_prc,var_prc,var_prc_out);

  /* Manually fix YYMMDD date which was mangled by averaging */
  if(CNV_CCM_CCSM_CF && prg == ncra) (void)nco_cnv_ccm_ccsm_cf_date(out_id,var_out,xtr_nbr);
  
  /* Add time variable to output file
     NB: nco_cnv_arm_time_install() contains OpenMP critical region */
  if(CNV_ARM && prg == ncrcat) (void)nco_cnv_arm_time_install(out_id,base_time_srt,dfl_lvl);
  
  /* Copy averages to output file */
  if(prg == ncea){
    for(idx=0;idx<nbr_var_prc;idx++){
      var_prc_out[idx]=nco_var_cnf_typ(var_prc_out[idx]->typ_upk,var_prc_out[idx]);
      /* Packing/Unpacking */
      if(nco_pck_plc == nco_pck_plc_all_new_att) var_prc_out[idx]=nco_put_var_pck(out_id,var_prc_out[idx],nco_pck_plc);
      if(var_prc_out[idx]->nbr_dim == 0){
	(void)nco_put_var1(out_id,var_prc_out[idx]->id,var_prc_out[idx]->srt,var_prc_out[idx]->val.vp,var_prc_out[idx]->type);
      }else{ /* end if variable is scalar */
	(void)nco_put_vara(out_id,var_prc_out[idx]->id,var_prc_out[idx]->srt,var_prc_out[idx]->cnt,var_prc_out[idx]->val.vp,var_prc_out[idx]->type);
      } /* end if variable is an array */
    } /* end loop over idx */
  } /* end if ncea */
  
  /* Free averaging and tally buffers */
  if(prg == ncra || prg == ncea){
#ifdef _OPENMP
#pragma omp parallel for default(none) private(idx) shared(nbr_var_prc,nco_op_typ,var_prc,var_prc_out)
#endif /* !_OPENMP */
    for(idx=0;idx<nbr_var_prc;idx++){
      var_prc_out[idx]->tally=var_prc[idx]->tally=(long *)nco_free(var_prc[idx]->tally);
      var_prc_out[idx]->val.vp=nco_free(var_prc_out[idx]->val.vp);
    } /* end loop over idx */
  } /* endif ncra || ncea */

  /* Close output file and move it from temporary to permanent location */
  (void)nco_fl_out_cls(fl_out,fl_out_tmp,out_id);
  
  /* Clean memory unless dirty memory allowed */
  if(flg_cln){
    /* Record file-specific memory cleanup */
    if(rec_dmn_id != NCO_REC_DMN_UNDEFINED) lmt_rec=nco_lmt_free(lmt_rec);

    /* Free lmt, lmt_dmn, and lmt_all_lst structures and lists */
    for(idx=0;idx<nbr_dmn_fl;idx++)
      for(jdx=0;jdx<lmt_all_lst[idx]->lmt_dmn_nbr;jdx++)
	lmt_all_lst[idx]->lmt_dmn[jdx]=nco_lmt_free(lmt_all_lst[idx]->lmt_dmn[jdx]);
    if(nbr_dmn_fl > 0) lmt_all_lst=nco_lmt_all_lst_free(lmt_all_lst,nbr_dmn_fl);   
    lmt=(lmt_sct**)nco_free(lmt); 

    /* NCO-generic clean-up */
    /* Free individual strings/arrays */
    if(cmd_ln) cmd_ln=(char *)nco_free(cmd_ln);
    if(cnk_map_sng) cnk_map_sng=(char *)strdup(cnk_map_sng);
    if(cnk_plc_sng) cnk_plc_sng=(char *)strdup(cnk_plc_sng);
    if(fl_in) fl_in=(char *)nco_free(fl_in);
    if(fl_out) fl_out=(char *)nco_free(fl_out);
    if(fl_out_tmp) fl_out_tmp=(char *)nco_free(fl_out_tmp);
    if(fl_pth) fl_pth=(char *)nco_free(fl_pth);
    if(fl_pth_lcl) fl_pth_lcl=(char *)nco_free(fl_pth_lcl);
    if(in_id_arr) in_id_arr=(int *)nco_free(in_id_arr);
    /* Free lists of strings */
    if(fl_lst_in && fl_lst_abb == NULL) fl_lst_in=nco_sng_lst_free(fl_lst_in,fl_nbr); 
    if(fl_lst_in && fl_lst_abb) fl_lst_in=nco_sng_lst_free(fl_lst_in,1);
    if(fl_lst_abb) fl_lst_abb=nco_sng_lst_free(fl_lst_abb,abb_arg_nbr);
    if(var_lst_in_nbr > 0) var_lst_in=nco_sng_lst_free(var_lst_in,var_lst_in_nbr);
    /* Free limits */
    for(idx=0;idx<lmt_nbr;idx++) lmt_arg[idx]=(char *)nco_free(lmt_arg[idx]);
    /* NB: lmt[idx] was free()'d earlier */
    for(idx=0;idx<aux_nbr;idx++) aux_arg[idx]=(char *)nco_free(aux_arg[idx]);
    if(aux_nbr > 0) aux=(lmt_sct **)nco_free(aux);
    /* Free chunking information */
    for(idx=0;idx<cnk_nbr;idx++) cnk_arg[idx]=(char *)nco_free(cnk_arg[idx]);
    if(cnk_nbr > 0) cnk=nco_cnk_lst_free(cnk,cnk_nbr);
    /* Free dimension lists */
    if(nbr_dmn_xtr > 0) dim=nco_dmn_lst_free(dim,nbr_dmn_xtr);
    if(nbr_dmn_xtr > 0) dmn_out=nco_dmn_lst_free(dmn_out,nbr_dmn_xtr);
    /* Free variable lists */
    if(xtr_nbr > 0) var=nco_var_lst_free(var,xtr_nbr);
    if(xtr_nbr > 0) var_out=nco_var_lst_free(var_out,xtr_nbr);
    var_prc=(var_sct **)nco_free(var_prc);
    var_prc_out=(var_sct **)nco_free(var_prc_out);
    var_fix=(var_sct **)nco_free(var_fix);
    var_fix_out=(var_sct **)nco_free(var_fix_out);
  } /* !flg_cln */
  
  /* End timer */ 
  ddra_info.tmr_flg=nco_tmr_end; /* [enm] Timer flag */
  rcd+=nco_ddra((char *)NULL,(char *)NULL,&ddra_info);

  if(rcd != NC_NOERR) nco_err_exit(rcd,"main");
  nco_exit_gracefully();
  return EXIT_SUCCESS;
} /* end main() */