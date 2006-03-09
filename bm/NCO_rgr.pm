package NCO_rgr;
# This file is part of the NCO nco_bm.pl benchmarking and regression testing.
# This file contains all the REGRESSION tests for the NCO operators.
# The BENCHMARKS are coded in the file "nco_bm_benchmarks.pl" which is inline
# code.  This is a module, so it has different packaging semantics, but
# it must maintain Perl semantics. - hjm

# $Header: /data/zender/nco_20150216/nco/bm/NCO_rgr.pm,v 1.27 2006-03-09 22:26:31 mangalam Exp $

require 5.6.1 or die "This script requires Perl version >= 5.6.1, stopped";
use English; # WCS96 p. 403 makes incomprehensible Perl errors sort of comprehensible
use Cwd 'abs_path';
use strict;

use NCO_bm qw(dbg_msg go
	$prefix $dta_dir @fl_cr8_dat $opr_sng_mpi $opr_nm $dsc_sng $prsrv_fl $nsr_xpc $srvr_sde
);

require Exporter;
our @ISA = qw(Exporter);
#export functions (top) and variables (bottom)
our @EXPORT = qw (
	perform_tests
	$outfile $dodap $prefix $opr_sng_mpi $opr_nm $dsc_sng $prsrv_fl $nsr_xpc
	$foo1_fl $foo_fl $foo_tst $orig_outfile $foo_avg_fl $foo_x_fl $foo_y_fl $foo_yx_fl
	$foo_xy_fl  $foo_xymyx_fl $pth_rmt_scp_tst $omp_flg $nco_D_flg
);
use vars qw(
    $dodap $dsc_sng $dust_usr $fl_fmt $fl_pth $foo1_fl $foo2_fl $foo_avg_fl
    $foo_fl $foo_tst $foo_x_fl $foo_xy_fl
    $foo_xymyx_fl $foo_y_fl $foo_yx_fl $mpi_prc $nco_D_flg $localhostname
    $nsr_xpc $omp_flg $opr_nm $opr_rgr_mpi $orig_outfile
    $outfile $pth_rmt_scp_tst $prsrv_fl @tst_cmd $USER
);
#
sub perform_tests {
# Tests are in alphabetical order by operator name

# The following tests are organized and laid out as follows:
# - $tst_cmd[] holds command lines for each operator being tested
#   the last 2 lines are the expected value and the serverside string, either:
#       "NO_SS" - No Serverside allowed or (all regr are NO_SS still)
#       "SS_OK" - OK to send it serverside. (has to be requested with '--serverside'
# - $dsc_sng still holds test description line
# - go() is function which executes each test

my $in_pth = "../data";
my $in_pth_arg = "-p $in_pth";
$prsrv_fl = 0;

## hjm++ 03-02-06 FXM does this now work without any other namespace gymnastics?
# csz++
# fxm: pass as arguments or use exporter/importer instead?
# *omp_flg=*main::omp_flg;
# *nco_D_flg=*main::nco_D_flg;
#*dodap=*main::dodap;
#*$fl_fmt=*main::fl_fmt;

# I DO NOT *&^%*& understand why this $outfile needs special handling !!!
*outfile = *main::outfile;

NCO_bm::dbg_msg(1,"in package NCO_rgr, \$dodap = $dodap");
NCO_bm::dbg_msg(1,"in package NCO_rgr, \$omp_flg = $omp_flg");
# csz--

NCO_bm::dbg_msg(1,"File format set to [$fl_fmt]");

# in general, $outfile    -> %tempf_00%
#             $foo_fl     -> %tempf_01%
#             $foo_tst    -> %tempf_02%
#             $foo_avg_fl -> %tempf_03%
#             $foo1_fl    -> %tempf_01%
#             $foo2_fl    -> %tempf_02%


if ($dodap ne "FALSE") {
	print "DEBUG: in perform_tests(), \$dodap = $dodap \n";
	if ($dodap ne "" && $fl_pth =~ /http/ ) { $in_pth_arg = "-p $fl_pth"; }
	if ($dodap eq "") { $in_pth_arg = "-p http://sand.ess.uci.edu/cgi-bin/dods/nph-dods/dodsdata"; }
}
NCO_bm::dbg_msg(1,"-------------  REGRESSION TESTS STARTED from perform_tests()  -------------");

if (0) {} #################  SKIP THESE #####################


####################
#### ncap tests ####
####################
    $opr_nm='ncap';
####################

# this stanza will not map to the way the SS is done - needs a %stdouterr% added but all the rest of them
# have an ncks which triggers this addition from the sub go() -> gnarly_pything.
# this stanza also requires a script on the SS.
	$tst_cmd[0]="ncap -h -O $fl_fmt $nco_D_flg -v -S ncap.in $in_pth_arg in.nc %tempf_00%";
	$dsc_sng="running ncap.in script into nco_tst.pl";
	$tst_cmd[1] = "ncap: WARNING Replacing missing value data in variable val_half_half";
#	$tst_cmd[2] = "NO_SS";
	$tst_cmd[2] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

#print "paused - hit return to continue"; my $wait = <STDIN>;

	$tst_cmd[0]="ncap -h -O $fl_fmt $nco_D_flg -C -v -s 'tpt_mod=tpt%273.0f' $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -v  tpt_mod -s '%.1f ' %tempf_00%";
	$dsc_sng="Testing float modulo float";
	$tst_cmd[2] = "0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array
#print "paused - hit return to continue"; my $wait = <STDIN>;


	$tst_cmd[0]="ncap -h -O $fl_fmt $nco_D_flg -C -v -s 'foo=log(e_flt)^1' $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -v foo -s '%.6f\\n' %tempf_00%";
	$dsc_sng="Testing foo=log(e_flt)^1 (fails on AIX TODO ncap57)";
	$tst_cmd[2] = "1.000000";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array
#print "paused - hit return to continue"; my $wait = <STDIN>;


# where did e_dbl go??  it's in in.cdl but gets lost thru the rgrs...?
	$tst_cmd[0]="ncap -h -O $fl_fmt $nco_D_flg -C -v -s 'foo=log(e_dbl)^1' $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%.12f\\n' %tempf_00%";
	$dsc_sng="Testing foo=log(e_dbl)^1";
	$tst_cmd[2] = "1.000000000000";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncap -h -O $fl_fmt $nco_D_flg -C -v -s 'foo=4*atan(1)' $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%.12f\\n' %tempf_00%";
	$dsc_sng="Testing foo=4*atan(1)";
	$tst_cmd[2] = "3.141592741013";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncap -h -O $fl_fmt $nco_D_flg -C -v -s 'foo=erf(1)' $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%.12f\\n' %tempf_00%";
	$dsc_sng="Testing foo=erf(1) [fails - erf() not impl right]";
	$tst_cmd[2] = "0.842701";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	#fails - wrong result ???
	$tst_cmd[0]="ncap -h -O $fl_fmt $nco_D_flg -C -v -s 'foo=gamma(0.5)' $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%.12f\\n' %tempf_00%";
	$dsc_sng="Testing foo=gamma(0.5) [fails - gamma() not impl right]";
	$tst_cmd[2] = "1.772453851";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncap -h -O $fl_fmt $nco_D_flg -C -v -s 'pi=4*atan(1);foo=sin(pi/2)' $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -v foo -s '%.12f\\n' %tempf_00%";
	$dsc_sng="Testing foo=sin(pi/2)";
	$tst_cmd[2] = "1.000000000000";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncap -h -O $fl_fmt $nco_D_flg -C -v -s 'pi=4*atan(1);foo=cos(pi)' $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -v foo -s '%.12f\\n' %tempf_00%";
	$dsc_sng="Testing foo=cos(pi)";
	$tst_cmd[2] = "-1.000000000000";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# print "paused - hit return to continue"; my $wait = <STDIN>;

if ($dodap eq "FALSE") {
####################
#### ncatted tests #
####################
    $opr_nm="ncatted";
####################
	# FAILS!
	$tst_cmd[0]="ncatted -h -O $fl_fmt $nco_D_flg -a units,,m,c,'meter second-1' $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%s' -v lev %tempf_00% | grep units | cut -d' ' -f 11-12";
	$dsc_sng="Modify all existing units attributes to meter second-1 FAILS - FXME! ";
	$tst_cmd[2] = "meter second-1";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

   $tst_cmd[0]="ncatted -h -O $fl_fmt $nco_D_flg -a missing_value,val_one_mss,m,f,0.0 $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%g' -d lat,1 -v val_one_mss %tempf_00%";
	$dsc_sng="Change missing_value attribute from 1.0e36 to 0.0";
	$tst_cmd[2] = "0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# this test now fails - due to changed $dsc_sng?
	$tst_cmd[0]="ncatted -O --hdr_pad=1000 $nco_D_flg -a missing_value,val_one_mss,m,f,0.0 $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -M %tempf_00% | grep hdr_pad | wc > %tempf_01%";
	$tst_cmd[2]="cut -c 14-15  %tempf_01%";
	$dsc_sng="Pad header with 1000 extra bytes for future metadata";
# 	$nsr_xpc= 26 ;
	$tst_cmd[3] = "24"; # was 26
	$tst_cmd[4] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array
}

#print "paused - hit return to continue"; my $wait = <STDIN>;


####################
#### ncbo tests ####
####################
    $opr_nm="ncbo";
####################
#if ($mpi_prc == 0 || ($mpi_prc > 0 && $opr_rgr_mpi =~ /$opr_nm/)) {
	$tst_cmd[0]="ncbo $omp_flg -h -O $fl_fmt $nco_D_flg --op_typ='-' -v mss_val_scl $in_pth_arg in.nc in.nc %tempf_00%";;
	$tst_cmd[1]="ncks -C -H -s '%g' -v mss_val_scl %tempf_00%";
	$dsc_sng="difference scalar missing value";
	$tst_cmd[2] = "1.0e36";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array - ok

	$tst_cmd[0]="ncbo $omp_flg -h -O $fl_fmt $nco_D_flg --op_typ='-' -d lon,1 -v mss_val $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%g' -v mss_val %tempf_00%";
	$dsc_sng="difference with missing value attribute";
	$tst_cmd[2] = 1.0e36;
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array ok

	$tst_cmd[0]="ncbo $omp_flg -h -O $fl_fmt $nco_D_flg --op_typ='-' -d lon,0 -v no_mss_val $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v no_mss_val %tempf_00%";
	$dsc_sng="difference without missing value attribute";
	$tst_cmd[2] = "0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array ok

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -v mss_val_fst $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncrename -h -O $nco_D_flg -v mss_val_fst,mss_val %tempf_00%";
	$tst_cmd[2]="ncbo $omp_flg  -h -O $fl_fmt $nco_D_flg -y '-' -v mss_val %tempf_00% ../data/in.nc %tempf_01% 2> %tempf_02%";
	$tst_cmd[3]="ncks -C -H -s '%f,' -v mss_val %tempf_01%";
	$dsc_sng="missing_values differ between files";
	$tst_cmd[4] = "-999.000000,-999.000000,-999.000000,-999.000000";
	$tst_cmd[5] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array ok

	$tst_cmd[0]="ncdiff $omp_flg -h -O $fl_fmt $nco_D_flg -d lon,1 -v mss_val $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%g' -v mss_val %tempf_00%";
	$dsc_sng="ncdiff symbolically linked to ncbo";
	$tst_cmd[2] = 1.0e36;
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array ok

	$tst_cmd[0]="ncdiff $omp_flg -h -O $fl_fmt $nco_D_flg -d lon,1 -v mss_val $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%g' -v mss_val %tempf_00%";
	$dsc_sng="difference with missing value attribute";
	$tst_cmd[2] = 1.0e36;
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array ok

	$tst_cmd[0]="ncdiff $omp_flg -h -O $fl_fmt $nco_D_flg -d lon,0 -v no_mss_val $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v no_mss_val %tempf_00%";
	$dsc_sng="difference without missing value attribute";
	$tst_cmd[2] = "0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array ok


	$tst_cmd[0]="ncwa $omp_flg -C -h -O $fl_fmt $nco_D_flg -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc %tempf_03%";
	$tst_cmd[1]="ncbo $omp_flg -C -h -O $fl_fmt $nco_D_flg -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc %tempf_03% %tempf_00%";
	$tst_cmd[2]="ncks -C -H -d time,3 -s '%f' -v rec_var_flt_mss_val_dbl %tempf_00%";
	$dsc_sng="Difference which tests broadcasting and changing variable IDs";
	$tst_cmd[3] = "-1.0";
	$tst_cmd[4] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

#} # endif $mpi_prc == 0...

# print "paused - hit return to continue"; my $wait = <STDIN>;
####################
#### ncea tests #### - OK !
####################
    $opr_nm='ncea';
####################

	$tst_cmd[0]="ncra -Y ncea $omp_flg -h -O $fl_fmt $nco_D_flg -v one_dmn_rec_var -d time,4 $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d' -v one_dmn_rec_var %tempf_00%";
	$dsc_sng="ensemble mean of int across two files";
	$tst_cmd[2] = "5";
	$tst_cmd[3] = "NO_SS";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra -Y ncea $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_flt_mss_val_flt -d time,0 $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%g' -v rec_var_flt_mss_val_flt %tempf_00%";
	$dsc_sng="ensemble mean with missing values across two files";
	$tst_cmd[2] = "1.0e36";
	$tst_cmd[3] = "NO_SS";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

   $tst_cmd[0]="/bin/rm -f %tempf_00%";
	$tst_cmd[1]="ncra -Y ncea $omp_flg -h -O $fl_fmt $nco_D_flg -y min -v rec_var_flt_mss_val_dbl -d time,1 $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[2]="ncks -C -H -s '%e' -v rec_var_flt_mss_val_dbl %tempf_00%";
	$dsc_sng="ensemble min of float across two files";
	$tst_cmd[3] = "2";
	$tst_cmd[4] = "NO_SS";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="/bin/rm -f %tempf_00%";
	$tst_cmd[1]="ncra -Y ncea $omp_flg -h -O $fl_fmt $nco_D_flg -C -v pck $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[2]="ncks -C -H -s '%e' -v pck %tempf_00%";
	$dsc_sng="scale factor + add_offset packing/unpacking";
	$tst_cmd[3] = "3";
	$tst_cmd[4] = "NO_SS";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="/bin/rm -f %tempf_00%";
	$tst_cmd[1]="ncra -Y ncea $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_int_mss_val_int $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[2]="ncks -C -H -s '%d ' -v rec_var_int_mss_val_int %tempf_00%";
	$dsc_sng="ensemble mean of integer with integer missing values across two files";
	$tst_cmd[3] = "-999 2 3 4 5 6 7 8 -999 -999";
	$tst_cmd[4] = "NO_SS";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# print "paused - hit return to continue"; my $wait = <STDIN>;

####################
## ncecat tests #### OK !
####################
    $opr_nm='ncecat';
####################
	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -v one $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -h -O $fl_fmt $nco_D_flg -v one $in_pth_arg in.nc %tempf_01%";
	$tst_cmd[2]="ncecat $omp_flg -h -O $fl_fmt $nco_D_flg %tempf_00% %tempf_01% %tempf_02%";
	$tst_cmd[3]="ncks -C -H -s '%6.3f, ' -v one %tempf_02%";
	$dsc_sng="concatenate two files containing only scalar variables";
	$tst_cmd[4] = " 1.000, "; # is this effectively equal to the previous " 1.000,  1.000, "
	$tst_cmd[5] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

#print "paused - hit return to continue"; my $wait = <STDIN>;

#####################
## ncflint tests #### OK !
#####################
    $opr_nm='ncflint';
####################
	$tst_cmd[0]="ncflint $omp_flg -h -O $fl_fmt $nco_D_flg -w 3,-2 -v one $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%e' -v one %tempf_00%";
	$dsc_sng="identity weighting";
	$tst_cmd[2] = "1.0";
	$tst_cmd[3] = "NO_SS";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

if ($dodap eq "FALSE"){
	$tst_cmd[0]="ncrename -h -O $nco_D_flg -v zero,foo $in_pth_arg in.nc %tempf_01%";
	$tst_cmd[1]="ncrename -h -O $nco_D_flg -v one,foo $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[2]="ncflint $omp_flg -h -O $fl_fmt $nco_D_flg -i foo,0.5 -v two %tempf_01% %tempf_00% %tempf_02%";
	$tst_cmd[3]="ncks -C -H -s '%e' -v two %tempf_02%";
	$dsc_sng="identity interpolation";
	$tst_cmd[4] = "2.0";
	$tst_cmd[5] = "NO_SS";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array
}

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -C -d lon,1 -v mss_val $in_pth_arg in.nc %tempf_01%";
	$tst_cmd[1]="ncks -h -O $fl_fmt $nco_D_flg -C -d lon,0 -v mss_val $in_pth_arg in.nc %tempf_02%";
	$tst_cmd[2]="ncflint $omp_flg -h -O $fl_fmt $nco_D_flg -w 0.5,0.5 %tempf_01% %tempf_02% %tempf_03%";
	$tst_cmd[3]="ncflint $omp_flg -h -O $fl_fmt $nco_D_flg -w 0.5,0.5  %tempf_02% %tempf_01%  %tempf_04%  $foo_y_fl $foo_x_fl $foo_yx_fl";
	$tst_cmd[4]="ncdiff $omp_flg -h -O $fl_fmt $nco_D_flg %tempf_03% %tempf_04% %tempf_05%";
	$tst_cmd[5]="ncks -C -H -s '%g' -v mss_val %tempf_05% ";
	$dsc_sng="switch order of occurrence to test for commutivity";
	$tst_cmd[6] = "1e+36";
	$tst_cmd[7] = "NO_SS";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array


####################
#### ncks tests #### OK !
####################
    $opr_nm='ncks';
####################
	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -v lat_T42,lon_T42,gw_T42 $in_pth_arg in.nc %tempf_03%";
	$tst_cmd[1]="ncrename -h -O $nco_D_flg -d lat_T42,lat -d lon_T42,lon -v lat_T42,lat -v gw_T42,gw -v lon_T42,lon %tempf_03%";
	$tst_cmd[2]="ncap -h -O $fl_fmt $nco_D_flg -s 'one[lat,lon]=lat*lon*0.0+1.0' -s 'zero[lat,lon]=lat*lon*0.0' %tempf_03% %tempf_04%";
	$tst_cmd[3]="ncks -C -H -s '%g' -v one -F -d lon,128 -d lat,64 %tempf_04% ";
	$dsc_sng="Create T42 variable named one, uniformly 1.0 over globe in %tempf_03% ";
	$tst_cmd[4] = 1;
	$tst_cmd[5] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	#passes, but returned string includes tailing NULLS (<nul> in nedit)
	$tst_cmd[0]="ncks -C -H -s '%c' -v fl_nm $in_pth_arg in.nc";
	$dsc_sng="extract filename string";
	$tst_cmd[1] = "/home/zender/nco/data/in.cdl";
	$tst_cmd[2] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -v lev $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f,' -v lev %tempf_00%";
	$dsc_sng="extract a dimension";
	$tst_cmd[2] = "100.000000,500.000000,1000.000000";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -v three_dmn_var $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v three_dmn_var -d lat,1,1 -d lev,2,2 -d lon,3,3 %tempf_00%";
	$dsc_sng="extract a variable with limits";
	$tst_cmd[2] = "23";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -v int_var $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d' -v int_var %tempf_00%";
	$dsc_sng="extract variable of type NC_INT";
	$tst_cmd[2] = "10";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -C -v three_dmn_var -d lat,1,1 -d lev,0,0 -d lev,2,2 -d lon,0,,2 -d lon,1,,2 $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%4.1f,' -v three_dmn_var %tempf_00%";
	$dsc_sng="Multi-slab lat and lon with srd";
	$tst_cmd[2] = "12.0,13.0,14.0,15.0,20.0,21.0,22.0,23.0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -C -v three_dmn_var -d lat,1,1 -d lev,2,2 -d lon,0,3 -d lon,1,3 $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%4.1f,' -v three_dmn_var %tempf_00%";
	$dsc_sng="Multi-slab with redundant hyperslabs";
	$tst_cmd[2] = "20.0,21.0,22.0,23.0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -C -v three_dmn_var -d lat,1,1 -d lev,2,2 -d lon,0.,,2 -d lon,90.,,2 $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%4.1f,' -v three_dmn_var %tempf_00%";
	$dsc_sng="Multi-slab with coordinates";
	$tst_cmd[2] = "20.0,21.0,22.0,23.0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -C -v three_dmn_var -d lat,1,1 -d lev,800.,200. -d lon,270.,0. $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%4.1f,' -v three_dmn_var %tempf_00%";
	$dsc_sng="Double-wrapped hyperslab";
	$tst_cmd[2] = "23.0,20.0,15.0,12.0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -C -d time_udunits,'1999-12-08 12:00:0.0','1999-12-09 00:00:0.0' $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%6.0f' -d time_udunits,'1999-12-08 18:00:0.0','1999-12-09 12:00:0.0',2 -v time_udunits $in_pth_arg in.nc";
	$dsc_sng="dimension slice using UDUnits library (fails without UDUnits library support)";
	$tst_cmd[2] = "876018";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -C -H -v wvl -d wvl,'0.4 micron','0.7 micron' -s '%3.1e' $in_pth_arg in.nc";
	$dsc_sng="dimension slice using UDUnit conversion (fails without UDUnits library support)";
	$tst_cmd[1] = "1.0e-06";
	$tst_cmd[2] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	#fails
	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -C -v '^three_*' $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -C -v three %tempf_00%";
	$dsc_sng="variable wildcards A (fails without regex library)";
	$tst_cmd[2] = "3";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -C -v '^[a-z]{3}_[a-z]{3}_[a-z]{3,}\$' $in_pth_arg in.nc %tempf_00%";
	# for this test, the regex is mod'ed                       ^
	$tst_cmd[1]="ncks -C -H -s '%d' -C -v val_one_int %tempf_00%";
	$dsc_sng="variable wildcards B (fails without regex library)";
	$tst_cmd[2] = "1";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -C -d time,0,1 -v time $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%g' -C -d time,2, %tempf_00%";
	$dsc_sng="Offset past end of file";
	$tst_cmd[2] = "ncks: ERROR User-specified dimension index range 2 <= time <= 1 does not fall within valid dimension index range 0 <= time <= 1";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -C -H -s '%d' -v byte_var $in_pth_arg in.nc";
	$dsc_sng="Print byte value";
	$tst_cmd[1] = "122";
	$tst_cmd[2] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array




#####################
#### ncpdq tests #### -OK !
#####################
    $opr_nm='ncpdq';
####################

	$tst_cmd[0]="ncpdq $omp_flg -h -O $fl_fmt $nco_D_flg -a -lat -v lat $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%g' -v lat -d lat,0 %tempf_00%";
	$dsc_sng="reverse coordinate";
	$tst_cmd[2] = "90";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncpdq $omp_flg -h -O $fl_fmt $nco_D_flg -a -lat,-lev,-lon -v three_dmn_var $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v three_dmn_var -d lat,0 -d lev,0 -d lon,0 %tempf_00%";
	$dsc_sng="reverse three dimensional variable";
	$tst_cmd[2] = 23;
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncpdq $omp_flg -h -O $fl_fmt $nco_D_flg -a lon,lat -v three_dmn_var $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v three_dmn_var -d lat,0 -d lev,2 -d lon,3 %tempf_00%";
	$dsc_sng="re-order three dimensional variable";
	$tst_cmd[2] = "11";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncpdq $omp_flg -h -O $fl_fmt $nco_D_flg -P all_new -v upk $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncpdq $omp_flg -h -O $fl_fmt $nco_D_flg -P upk -v upk %tempf_00% %tempf_00%";
	$tst_cmd[2]="ncks -C -H -s '%g' -v upk %tempf_00%";
	$dsc_sng="Pack and then unpack scalar (uses only add_offset)";
	$tst_cmd[3] = "3";
	$tst_cmd[4] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array


#print "paused - hit return to continue"; my $wait = <STDIN>;

####################
#### ncrcat tests ## OK !
####################
    $opr_nm='ncrcat';
####################
#if ($mpi_prc == 0) { # fxm test hangs because of ncrcat TODO 593
	$tst_cmd[0]="ncra -Y ncrcat $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc in.nc %tempf_00% 2> %tempf_02%";
	$tst_cmd[1]="ncks -C -H -d time,11 -s '%f' -v rec_var_flt_mss_val_dbl %tempf_00%";
	$dsc_sng="Concatenate float with double missing values across two files";
	$tst_cmd[2] = "2";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array
#    } else { print "NB: Current mpncrcat test skipped because it hangs fxm TODO nco593.\n";}

####################
#### ncra tests #### OK!
####################
    $opr_nm='ncra';
####################

#        if ($mpi_prc == 0 || ($mpi_prc > 0 && $localhostname !~ /sand/)) { # test hangs because of ncrcat TODO nco593
#	$outfile =  $foo1_fl; # orig line - refactor after rest of tests are working
	$tst_cmd[0]="ncra -Y ncrcat $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc in.nc %tempf_00% 2> %tempf_02%";
#	$outfile =  $orig_outfile;  orig line FIXME
	$tst_cmd[1]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -y avg -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[2]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -a time %tempf_00% %tempf_00%";
	$tst_cmd[3]="ncdiff $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_flt_mss_val_dbl %tempf_01% %tempf_00% %tempf_00%";
	$tst_cmd[4]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -y rms -v rec_var_flt_mss_val_dbl %tempf_00% %tempf_00%";
	$tst_cmd[5]="ncks -C -H -s '%f' -v rec_var_flt_mss_val_dbl %tempf_00%";
	$dsc_sng="record sdn of float with double missing values across two files";
	$tst_cmd[6] = "2";
	$tst_cmd[7] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array
#    } else { print "NB: Current mpncra test skipped on sand because mpncrcat step hangs fxm TODO nco593\n";}

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -v one_dmn_rec_var $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d' -v one_dmn_rec_var %tempf_00%";
	$dsc_sng="record mean of int across two files";
	$tst_cmd[2] = "5";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v rec_var_flt_mss_val_dbl %tempf_00%";
	$dsc_sng="record mean of float with double missing values";
	$tst_cmd[2] = "5";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_flt_mss_val_int $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v rec_var_flt_mss_val_int %tempf_00%";
	$dsc_sng="record mean of float with integer missing values";
	$tst_cmd[2] = "5";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_int_mss_val_int $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d' -v rec_var_int_mss_val_int %tempf_00%";
	$dsc_sng="record mean of integer with integer missing values";
	$tst_cmd[2] = "5";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_int_mss_val_int $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d' -v rec_var_int_mss_val_int %tempf_00%";
	$dsc_sng="record mean of integer with integer missing values across two files";
	$tst_cmd[2] = "5";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_int_mss_val_flt $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d' -v rec_var_int_mss_val_flt %tempf_00%";
	$dsc_sng="record mean of integer with float missing values";
	$tst_cmd[2] = "5";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_int_mss_val_flt $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d' -v rec_var_int_mss_val_flt %tempf_00%";
	$dsc_sng="record mean of integer with float missing values across two files";
	$tst_cmd[2] = "5";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_dbl_mss_val_dbl_pck $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v rec_var_dbl_mss_val_dbl_pck %tempf_00%";
	$dsc_sng="record mean of packed double with double missing values";
	$tst_cmd[2] = "5";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_dbl_pck $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v rec_var_dbl_pck %tempf_00%";
	$dsc_sng="record mean of packed double to test precision";
	$tst_cmd[2] = "100.55";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -v rec_var_flt_pck $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%3.2f' -v rec_var_flt_pck %tempf_00%";
	$dsc_sng="record mean of packed float to test precision";
	$tst_cmd[2] = "100.55";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -v pck,one_dmn_rec_var $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d' -v pck %tempf_00%";
	$dsc_sng="pass through non-record (i.e., non-processed) packed data to output";
	$tst_cmd[2] = "1";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -y avg -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v rec_var_flt_mss_val_dbl %tempf_00%";
	$dsc_sng="record mean of float with double missing values across two files";
	$tst_cmd[2] = "5";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -y min -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v rec_var_flt_mss_val_dbl %tempf_00%";
	$dsc_sng="record min of float with double missing values across two files";
	$tst_cmd[2] = "2";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -y max -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v rec_var_flt_mss_val_dbl %tempf_00%";
	$dsc_sng="record max of float with double missing values across two files";
	$tst_cmd[2] = "8";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -y ttl -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v rec_var_flt_mss_val_dbl %tempf_00%";
	$dsc_sng="record ttl of float with double missing values across two files";
	$tst_cmd[2] = "70";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncra $omp_flg -h -O $fl_fmt $nco_D_flg -y rms -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%1.5f' -v rec_var_flt_mss_val_dbl %tempf_00%";
	$dsc_sng="record rms of float with double missing values across two files";
	$tst_cmd[2] = "5.38516";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

#print "paused - hit return to continue"; my $wait = <STDIN>;
#print "<<<STOP>>>- hit return to continue"; my $wait = <STDIN>;

####################
#### ncwa tests #### OK!
####################
    $opr_nm='ncwa';
####################

	$tst_cmd[0]="ncks -h -O $fl_fmt $nco_D_flg -v lat_T42,lon_T42,gw_T42 $in_pth_arg in.nc %tempf_03%";
	$tst_cmd[1]="ncrename -h -O $nco_D_flg -d lat_T42,lat -d lon_T42,lon -v lat_T42,lat -v gw_T42,gw -v lon_T42,lon %tempf_03%";
	$tst_cmd[2]="ncap -h -O $fl_fmt $nco_D_flg -s 'one[lat,lon]=lat*lon*0.0+1.0' -s 'zero[lat,lon]=lat*lon*0.0' %tempf_03% %tempf_04%";
	$tst_cmd[3]="ncks -C -H -s '%g' -v one -F -d lon,128 -d lat,64 %tempf_04%";
	$dsc_sng="Creating %tempf_03% again ";
	$tst_cmd[4] = "1";
	$tst_cmd[5] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -a lat,lon -w gw -d lat,0.0,90.0 %tempf_04% %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%g' -v one %tempf_00%";
	$dsc_sng="normalize by denominator upper hemisphere";
	$prsrv_fl = 1; # save previously generated files.
#	$nsr_xpc= 1;
# go();
	$tst_cmd[2] = 1;
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -a time -v pck,one_dmn_rec_var $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d' -v pck %tempf_00%";
	$dsc_sng="pass through non-averaged (i.e., non-processed) packed data to output";
	$tst_cmd[2] = "1";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa -N $omp_flg -h -O $fl_fmt $nco_D_flg -a lat,lon -w gw $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v mask %tempf_00%";
	$dsc_sng="do not normalize by denominator";
	$tst_cmd[2] = "50";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -a lon -v mss_val $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v mss_val %tempf_00%";
	$dsc_sng="average with missing value attribute";
	$tst_cmd[2] = "73";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -a lon -v no_mss_val $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%g' -v no_mss_val %tempf_00%";
	$dsc_sng="average without missing value attribute";
	$tst_cmd[2] = "5.0e35";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -v lat -m lat -M 90.0 -T eq -a lat $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%e' -v lat %tempf_00%";
	$dsc_sng="average masked coordinate";
	$tst_cmd[2] = "90.0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -v lat_var -m lat -M 90.0 -T eq -a lat $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%e' -v lat_var %tempf_00%";
	$dsc_sng="average masked variable";
	$tst_cmd[2] = "2.0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -v lev -m lev -M 100.0 -T eq -a lev -w lev_wgt $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%e' -v lev %tempf_00%";
	$dsc_sng="average masked, weighted coordinate";
	$tst_cmd[2] = "100.0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -v lev_var -m lev -M 100.0 -T gt -a lev -w lev_wgt $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%e' -v lev_var %tempf_00%";
	$dsc_sng="average masked, weighted variable";
	$tst_cmd[2] = "666.6667";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -v lat -a lat -w gw -d lat,0 $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%e' -v lat %tempf_00%";
	$dsc_sng="weight conforms to var first time";
	$tst_cmd[2] = "-90.0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -v mss_val_all -a lon -w lon $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%g' -v mss_val_all %tempf_00%";
	$dsc_sng="average all missing values with weights";
	$tst_cmd[2] = "1.0e36";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -v val_one_mss -a lat -w wgt_one $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%e' -v val_one_mss %tempf_00%";
	$dsc_sng="average some missing values with unity weights";
	$tst_cmd[2] = "1.0";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -v msk_prt_mss_prt -m msk_prt_mss_prt -M 1.0 -T lt -a lon $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%e' -v msk_prt_mss_prt %tempf_00%";
	$dsc_sng="average masked variable with some missing values";
	$tst_cmd[2] = "0.5";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y min -v rec_var_flt_mss_val_dbl $in_pth_arg in.nc %tempf_00% 2> %tempf_02%";
	$tst_cmd[1]="ncks -C -H -s '%e' -v rec_var_flt_mss_val_dbl %tempf_00%";
	$dsc_sng="min switch on type double, some missing values";
	$tst_cmd[2] = "2";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="ncwa $omp_flg  -h -O $fl_fmt $nco_D_flg -y min -v three_dmn_var_dbl -a lon $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f,' -v three_dmn_var_dbl %tempf_00% > %tempf_01%";
	$tst_cmd[2]="cut -d, -f 7 %tempf_01%";
	$dsc_sng="Dimension reduction with min switch and missing values";
	$tst_cmd[3] = "-99";
	$tst_cmd[4] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="cut -d, -f 20 %tempf_01%";
	$dsc_sng="Dimension reduction with min switch";
	$prsrv_fl = 1;
	$tst_cmd[1] = "77";
	$tst_cmd[2] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y min -v three_dmn_var_int -a lon $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d,' -v three_dmn_var_int %tempf_00% > %tempf_01%";
	$tst_cmd[2]="cut -d, -f 5 %tempf_01%";
	$dsc_sng="Dimension reduction on type int with min switch and missing values";
 	$tst_cmd[3] = "-99";
	$tst_cmd[4] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="cut -d, -f 7 %tempf_01%";
	$dsc_sng="Dimension reduction on type int variable";
	$prsrv_fl = 1;
	$tst_cmd[1] = "25";
	$tst_cmd[2] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y min -v three_dmn_var_sht -a lon $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d,' -v three_dmn_var_sht %tempf_00% > %tempf_01%";
	$tst_cmd[2]="cut -d, -f 20 %tempf_01%";
	$dsc_sng="Dimension reduction on type short variable with min switch and missing values";
 	$tst_cmd[3] = -99;
	$tst_cmd[4] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="cut -d, -f 8 %tempf_01%";
	$dsc_sng="Dimension reduction on type short variable";
	$prsrv_fl = 1;
	$tst_cmd[1] = "29";
	$tst_cmd[2] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y min -v three_dmn_rec_var $in_pth_arg in.nc %tempf_00% 2> %tempf_02%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v three_dmn_rec_var %tempf_00%";
	$dsc_sng="Dimension reduction with min flag on type float variable";
	$tst_cmd[2] = "1";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y max -v four_dmn_rec_var $in_pth_arg in.nc %tempf_00% 2> %tempf_02%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v four_dmn_rec_var %tempf_00%";
	$dsc_sng="Max flag on type float variable";
	$tst_cmd[2] = "240";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y max -v three_dmn_var_dbl -a lat,lon $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%f,' -v three_dmn_var_dbl %tempf_00% > %tempf_01%";
	$tst_cmd[2]="cut -d, -f 4 %tempf_01%";
	$dsc_sng="Dimension reduction on type double variable with max switch and missing values";
 	$tst_cmd[3] = "-99";
	$tst_cmd[4] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="cut -d, -f 5 %tempf_01%";
	$dsc_sng="Dimension reduction on type double variable";
	$prsrv_fl = 1;
	$tst_cmd[1] = "40";
	$tst_cmd[2] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y max -v three_dmn_var_int -a lat $in_pth_arg in.nc %tempf_00%";
	$tst_cmd[1]="ncks -C -H -s '%d,' -v three_dmn_var_int %tempf_00% > %tempf_01%";
	$tst_cmd[2]="cut -d, -f 9 %tempf_01%";
	$dsc_sng="Dimension reduction on type int variable with min switch and missing values";
 	$tst_cmd[3] = "-99";
	$tst_cmd[4] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="cut -d, -f 13 %tempf_01%";
	$dsc_sng="Dimension reduction on type int variable";
	$prsrv_fl = 1;
	$tst_cmd[1] = "29";
	$tst_cmd[2] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y max -v three_dmn_var_sht -a lat $in_pth_arg in.nc %tempf_00%";;
	$tst_cmd[1]="ncks -C -H -s '%d,' -v three_dmn_var_sht %tempf_00% > %tempf_01%";
	$tst_cmd[2]="cut -d, -f 37 %tempf_01%";
	$dsc_sng="Dimension reduction on type short variable with max switch and missing values";
 	$tst_cmd[3] = "-99";
	$tst_cmd[4] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# will fail SS - ncks not the last cmd
	$tst_cmd[0]="cut -d, -f 33 %tempf_01%";
	$dsc_sng="Dimension reduction on type short, max switch variable";
	$prsrv_fl = 1;
	$tst_cmd[1] = "69";
	$tst_cmd[2] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y rms -w lat_wgt -v lat $in_pth_arg in.nc %tempf_00% 2> %tempf_02%";
	$tst_cmd[1]="ncks -C -H -s '%f' -v lat %tempf_00%";;
	$dsc_sng="rms with weights";
	$tst_cmd[2] = "90";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -w val_half_half -v val_one_one_int $in_pth_arg in.nc %tempf_00% 2> %tempf_02%";
	$tst_cmd[1]="ncks -C -H -s '%ld' -v val_one_one_int %tempf_00%";;
	$dsc_sng="weights would cause SIGFPE without dbl_prc patch";
	$tst_cmd[2] = "1";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y avg -v val_max_max_sht $in_pth_arg in.nc %tempf_00% 2> %tempf_02%";
	$tst_cmd[1]="ncks -C -H -s '%d' -v val_max_max_sht %tempf_00%";;
	$dsc_sng="avg would overflow without dbl_prc patch";
	$tst_cmd[2] = "17000";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y ttl -v val_max_max_sht $in_pth_arg in.nc %tempf_00% 2> %tempf_02%";
	$tst_cmd[1]="ncks -C -H -s '%d' -v val_max_max_sht %tempf_00%";
	$dsc_sng="ttl would overflow without dbl_prc patch, wraps anyway so exact value not important (failure expected/OK on Xeon chips because of different wrap behavior)";
#	$nsr_xpc= -31536 ; # Expected on Pentium IV GCC Debian 3.4.3-13, PowerPC xlc
#    $nsr_xpc= -32768 ; # Expected on Xeon GCC Fedora 3.4.2-6.fc3
#    $nsr_xpc= -32768 ; # Expected on PentiumIII (Coppermine) gcc 3.4 MEPIS
	$tst_cmd[2] = "-32768";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y min -a lat -v lat -w gw $in_pth_arg in.nc %tempf_00%";;
	$tst_cmd[1]="ncks -C -H -s '%g' -v lat %tempf_00%";;
	$dsc_sng="min with weights";
	$tst_cmd[2] = "-900";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncwa $omp_flg -h -O $fl_fmt $nco_D_flg -y max -a lat -v lat -w gw $in_pth_arg in.nc %tempf_00%";;
	$tst_cmd[1]="ncks -C -H -s '%g' -v lat %tempf_00%";;
	$dsc_sng="max with weights";
	$tst_cmd[2] = "900";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

#print "paused - hit return to continue"; my $wait = <STDIN>;

####################
##### net tests #### OK ! (ones that can be done by non-zender)
####################
    $opr_nm='net';
####################
# test 1
	$tst_cmd[0]="/bin/rm -f /tmp/in.nc";
	$tst_cmd[1]="ncks -h -O $fl_fmt $nco_D_flg -s '%e' -v one -p ftp://dust.ess.uci.edu/pub/zender/nco -l /tmp in.nc | tail -1";
	$dsc_sng="Anonymous FTP protocol (requires anonymous FTP access to dust.ess.uci.edu)";
	$tst_cmd[2] = "1.000000e+00";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# test 2
	my $sftp_url = "sftp://dust.ess.uci.edu:/home/ftp/pub/zender/nco";
	if ($dust_usr ne ""){ # if we need to connect as another user (hmangalm@esmf -> hjm@dust))
		 $sftp_url =~ s/dust/$dust_usr\@dust/;
	}
#sftp://dust.ess.uci.edu:/home/ftp/pub/zender/nco
	$tst_cmd[0]="/bin/rm -f /tmp/in.nc";
	$tst_cmd[1]="ncks -O $nco_D_flg -v one -p $sftp_url -l /tmp in.nc";
	$tst_cmd[2]="ncks -H $nco_D_flg -s '%e' -v one -l /tmp in.nc";
	$dsc_sng="Secure FTP (SFTP) protocol (requires SFTP access to dust.ess.uci.edu)";
	$tst_cmd[3] = "1.000000e+00";
	$tst_cmd[4] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

# test 3
	if ($dust_usr ne ""){ # if we need to connect as another user (hmangalm@esmf -> hjm@dust))
		$pth_rmt_scp_tst = $dust_usr . '@' . $pth_rmt_scp_tst;
	}
	$tst_cmd[0]="/bin/rm -f /tmp/in.nc";
	$tst_cmd[1]="ncks -h -O $fl_fmt $nco_D_flg  -s '%e' -v one -p $pth_rmt_scp_tst -l /tmp in.nc | tail -1";
	$dsc_sng="SSH protocol (requires authorized SSH/scp access to dust.ess.uci.edu)";
	$tst_cmd[2] = 1;
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	$tst_cmd[0]="ncks -C -O -d lon,0 -s '%e' -v lon -p http://www.cdc.noaa.gov/cgi-bin/nph-nc/Datasets/ncep.reanalysis.dailyavgs/surface air.sig995.1975.nc";
	$dsc_sng="OPeNDAP protocol (requires OPeNDAP/DODS-enabled NCO)";
	$tst_cmd[1] = "0";
	$tst_cmd[2] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	if($USER eq 'zender'){
		$tst_cmd[0]="/bin/rm -f /tmp/etr_A4.SRESA1B_9.CCSM.atmd.2000_cat_2099.nc";
		$tst_cmd[1]="ncks -h -O $fl_fmt $nco_D_flg -s '%e' -d time,0 -v time -p ftp://climate.llnl.gov//sresa1b/atm/yr/etr/ncar_ccsm3_0/run9 -l /tmp etr_A4.SRESA1B_9.CCSM.atmd.2000_cat_2099.nc";
		$dsc_sng="Password-protected FTP protocol (requires .netrc-based FTP access to climate.llnl.gov)";
		$tst_cmd[2] = "182.5";
		$tst_cmd[3] = "SS_OK";
		NCO_bm::go(\@tst_cmd);
		$#tst_cmd=0;  # reset the array

		$tst_cmd[0]="/bin/rm -f /tmp/in.nc";
		$tst_cmd[1]="ncks -h -O $fl_fmt $nco_D_flg -v one -p mss:/ZENDER/nc -l /tmp in.nc";
		$tst_cmd[2]="ncks -C -H -s '%e' -v one %tempf_00%";
		$dsc_sng="msrcp protocol (requires msrcp and authorized access to NCAR MSS)";
		$tst_cmd[3] = "1";
		$tst_cmd[4] = "SS_OK";
		NCO_bm::go(\@tst_cmd);
		$#tst_cmd=0;  # reset the array

	} else { print "WARN: Skipping net tests of mss: and password protected FTP protocol retrieval---user not zender\n";}

	if($USER eq 'zender' || $USER eq 'hjm'){
	    $tst_cmd[0]="/bin/rm -f /tmp/in.nc";
	    $tst_cmd[1]="ncks -h -O $fl_fmt $nco_D_flg -s '%e' -v one -p wget://dust.ess.uci.edu/nco -l /tmp in.nc";
	    $dsc_sng="HTTP protocol (requires developers to implement wget in NCO nudge nudge wink wink)";
 	$tst_cmd[2] = "1";
	$tst_cmd[3] = "SS_OK";
	NCO_bm::go(\@tst_cmd);
	$#tst_cmd=0;  # reset the array

	} else { print "WARN: Skipping net test wget: protocol retrieval---not implemented yet\n";}

} # end of perform_test()
