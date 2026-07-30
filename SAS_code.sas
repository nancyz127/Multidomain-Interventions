/*combine w3-w12*/
data comb; set w3 w5 w7 w9 w11 w12; run;


/*alcohol*/
data tmp;
	set comb;
	drink_unit=sum (of My_BEERWKO, My_SPRTWKO, My_WINEWKO);
	if drink_unit> 14 then hv_drink=1;
	else if 0<=drink_unit<14 then hv_drink=0;
	else if My_NONDRNK=1 then hv_drink=0;
	keep id wave hv_drink;
run;

data tmp2;
	set tmp;
	keep id wave;
	where hv_drink=.;
run;

/*impute from FFQ*/
data ffq_drk1;
	set ffq3_9;
	keep id wave My beer My_liqu My_port My spirits My_wine;
run;

data ffq_drk2;
	set s11ffq_0281_8;
	id=input (id_random_DPUK, best32.);
	wave=11;
	keep id wave FBEER FLIQUALL FWINE;
run;

proc sort data=tmp2; by id wave;
proc sort data=ffq_drkl; by id wave;
proc sort data=ffq_drk2; by id wave;

data tmp2a;
	merge tmp2 (in=a) ffq_drk1 ffq_drk2;
	by id wave;
	if a;
run;

data tmp2b;
	set tmp2a;
	array vars[8] My_beer My_liqu My_port My_spirits My_wine FBEER FLIQUALL FWINE;
	array recode[8] My_beer1 My_liqul My_port1 My_spirits1 My_winel FBEER1 FLIQUALL1 FWINE1;

	do i=1 to 8;
		select (vars[i]);
			when (1) recode[i]=0;
			when (2) recode [i]=2/4.35;
			when (3) recode [i]=1;
			when (4) recode[i]=3;
			when (5) recode [i]=5.5;
			when (6) recode [i]=7;
			when (7) recode [i]=2.5*7;
			when (8) recode [i]=4.5*7;
			when (9) recode[i]=6.5*7;
			otherwise recode[i]=.;
		end;
	end;
	alc_sum=sum (of My_beer1 My_liqul My_port1 My_spirits1 My_winel FBEER1 FLIQUALL1 FWINE1);

	if 14<=alc_sum then hv_drink=1;
	else if 0 <=alc_sum<14 then hv_drink=0;
	keep id wave hv_drink;
run;

data aaic.alchol;
	merge tmp tmp2b;
	by id wave;
run;

proc sort data=comb; by id wave; run;
proc sort data=aaic.ffq3_11; by id wave; run;
proc sort data=aaic.alchol; by id wave; run;

data comb1;
	merge comb (in=a) aaic.ffq3_11 aaic.alchol;
	by id wave;
	if a;
run;

data aaic.comb1;
	set comb1;
	age=My_AGE_C;
	
	/*smoke*/
	if my_esmoke =3 then current_smk=1;
	else if my_esmoke in (1 2) then current_smk=0;

	/*cvd*/
	if my_ANG=1 or my_MI=1 or my_STRDIAG in (1, 2) or my_OHT=1 then cvd=1;
	if my_ANG=2 and my _MI-2 and mY_STRDIAG not in (1, 2) and my_OHT=2 then cvd=0;

	/*depress_anxiety*/
	if my_NKEM01=1 OR my_NKEM02=1 or my_NKEM03=1 then depress=1;
	else if my _NKEM01-2 and my_NKEM02=2 and my_NKEM03-2 then depress=0;

	/*marital*/
	/*for wave 5-12*/
	if my_statusx=1 then mar_cohab=1;
	else if my_statusx in (3, 4, 5) then mar_cohab=0;

	/*cognitive*/
	if 0<=my_mm_scor< 24 then cog1=1;
	else if my_mm_scor>=24 then cog1=0;
run;

/*calculated MVPA variables in 2011 paper*/
data pa_calcu;
	set PA_APOE_ver3update_S;
	id=id_random_DPUK;
/* moderate +vigorous */
	mvpa5=sum (TMODHR_S, TVIGHR_S)*60;
	mvpa7=sum (mMODHR_S, mVIGHR_S)*60;
	mvpa9=sum (jMODHR_S, jVIGHR_S)*60;
	mvpall=sum (FMODHR_S, VIGHR_S)*60;
/* light+ moderate +vigorous */
	lmvpa5=sum (TMILHR_S, TMODHR_S, TVIGHR_S)*60;
	lmvpa7=sum (MMILHR_S,mMODHR_S, mVIGHR_S)*60;
	lmvpa9=sum (JMILHR_S, jMODHR_S, jVIGHR_S)*60;
	lmvpall=sum (FMILHR_S, FMODHR_S, VIGHR_S)*60;
	keep id mvpa5 mvpa7 mvpa9 mvpa11 lmvpa5 lmvpa7 lmvpa9 lmvpa11;
run;

proc sort data=pa_calcu; by id; run;
proc transpose data=pa_calcu out-pa_calcu_long1 name=varname;
	by id;
	var mvpa3 mvpa5 mvpa7 mvpa9 mvpa11 mvpa12;
run;

data pa_calcu_long1;
	set pa_calcu_long1;
	wave=input(compress (varname, 'kd'), 8.);
	mvpa_calcu=col1;
	keep id wave mvpa_calcu;
run;

proc transpose data=pa_calcu out-pa_calcu_long2 name=varname;
	by id;
	var lmvpa3 lmvpa5 lmvpa7 lmvpa9 lmvpa11 lmvpa12;
run;

data pa_calcu_long2;
	set pa_calcu_long2;
	wave=input(compress (varname, 'kd'), 8.);
	lmvpa_calcu=col1;
	keep id wave lmvpa_calcu;
run;

proc sort data=pa_calcu_long1; 	by wave id; run;
proc sort data=pa_calcu_long2; 	by wave id; run;
proc sort data=update.comb1d;  by wave id; run;

data comb1d;
	merge update.comb1d(in=a) pa_calcu_long1 pa_calcu_long2;
	by wave id;
	keep id wave age pa sum_pa sum_pa_all mvpa_calcu lmvpa_calcu fruit_veg mind 
		current_smk hv_drink cvd depress mar_cohab my_mm_scor cog1 my_animals 
		my_SWORDS my_MEM my_AH4 my_MH my_sbp my_blchol my_bmi my_gluc_f My_PART 
		My_PARTTYP;
	if a;
run;

proc sort data=aaic.apoe; by id; run;
proc sort data=comb1d; by id; run;

data comb1e;
	merge comb1d (in=a) aaic.base aaic.apoe;
	by id;
	if a;
run;

/*standarize test scores*/
proc sort data=comble; 	by wave; run;

proc stdize data=comble out=comb_std;
	by wave;
	var my_animals my_SWORDS my_MEM my_AH4 my_MH;
run;

%cog_test(comb_std, my_animals, cog2);
%cog_test(comb_std, my_SWORDS, cog3);
%cog_test(comb_std, my_MEM, cog4);
%cog_test(comb_std, my_AH4, cog5);
%cog_test1(comb_std, my_MH, cog6);

/*check*/
proc freq data=comb_std;
	table wave* (cog1 cog2 cog3 cog4 cog5 cog6);
run;

/*wave 5, mmse score lower than other waves*/
proc means data=comble;
	class wave;
	var my_mm_scor;
run;

data comb_stdl;
	set comb_std;

	/*def1: main analysis*/
	if sum (of cog2, cog3, cog4, cog5, cog6) >=1 then cog_imp_nommse=1;
	else if cog2=. and cog3=. and cog4=. and cog5=. and cog6=. then cog_imp_nommse=.;
	else cog_imp_nommse=0;
	
	/*def2: def1 + MMSE, sensitivity analysis*/
	if sum(of cog1, cog2, cog3, cog4, cog5, cog6) >=1 then cog_imp=1;
	else if cogl=. and cog2=. and cog3=. and cog4=. and cog5=. and cog6=. then cog_imp=.;
	else cog_imp=0;
run;


/*Run the following codes separately using two definitions*/
%let out=cog_imp_nommse;
%let out=cog_imp;

/*******miss w5 but has w3, imput cog at w5 by at w3*/
proc sql;
	create table w3_5 as select id, &out as w3_cog from comb_stdl 
	where id in (select pattern.id from pattern where substr(pattern, 1, 2) in ('OM' '1M')) and wave=3;
quit;

data comb_std2;
	merge comb_std1 (in=a) w3_5;
	by id;
	if a;
run;

data comb_std3;
	set comb_std2;
	if wave=5 and &out=. then &out=w3_cog;
run;
/* include/exclude */
proc sql;
	create table select_id3 as select distinct id from comb_std3 
	where wave=5 and 
		45<=age<=64 and &out=0 and my_part=1 and mvpa_calcu^=. and mind^=. and current_smk^=. and hv_drink^=. and 
		my_sbp^=. and my_blchol^=. and my_bmi^=. and my_gluc_f^=.;
quit;

proc sql;
	create table select1 as select * from comb_std3 where id in (select 
		select_id3.id from select_id3);
quit;

/*outcome missing patterns across waves, M if missing and o if observed*/
data outcome;
	set select1;
	keep id wave &out;
	where wave^=3;
run;

proc sort data=outcome; by id;
proc transpose data=outcome out=wide_out prefix=wave_;
	by id;
	id wave;
	var &out;
run;

data pattern;
	set wide out;
	array tvars{*} wave_:
    length pattern $10;
	pattern='';

	do i=1 to dim (tvars);
		if missing (tvars[i]) then pattern=cats (pattern, "M");
		else pattern cats (pattern, 'o');
	end;
run;

proc freq data=pattern order=freq;
	tables pattern;
run;

/*********** keep covariates according to the missing outcome pattern********/
proc sql;
	create table m_1 as select * from (select * from select1 (drop=cog_imp cog_imp_nommse)) 
		where id in (select pattern.id from pattern where pattern in ('ooooo' 'ooooM')) and wave in (5, 7, 9, 11);
QUIT;

proc sql;
	create table m_2 as select * from (select * from select1 (drop=cog_imp cog_imp_nommse)) 
	where id in (select pattern.id from pattern where pattern in ('oooMM' 'oooMo')) and wave in (5, 7, 9);
QUIT;

proc sql;
	create table m_3 as select * from (select * from select1 (drop=cog_imp cog_imp_nommse)) 
	where id in (select pattern.id from pattern where pattern in ('ooMMM' 'ooMMo' 'ooMoM' 'ooMoo')) and wave in (5, 7);
QUIT;

proc sql;
	create table m_4 as select * from (select * from select1 (drop=cog_imp cog_imp_nommse)) 
	where id in (select pattern.id from pattern where pattern in ('oMooo', 'oMMMM', 'OMMoo', 'oMooM', 'oMMMo', 'oMoMM', 'oMMoM','oMoMo')) and wave in (5);
QUIT;

data covars; set m_1 m_2 m_3 m_4; run;

/******** keep outcome according to the missing pattern*********/
proc sql;
	create table yl as select id, wave, &out from select1 
	where id in (select pattern.id from pattern where pattern in ('ooooo' 'ooooM')) and wave in (7,	9, 11, 12);
QUIT;

proc sql;
	create table y2 as select id, wave, &out from select1 
	where id in (select pattern.id from pattern where pattern in ('oooMM' 'oooMo')) and wave in (7, 9, 11);
QUIT;

proc sql;
	create table y3 as select id, wave, &out from select1 
	where id in (select pattern.id from pattern where pattern in ('ooMMM' 'ooMMo' 'ooMoM' 'ooMoo')) and wave in (7, 9);
QUIT;

proc sql;
	create table v4 as select id, wave, &out from select1 
	where id in (select pattern.id from pattern where pattern in ('oMooo', 'oMMMM', 'oMMoo', 'oMooM', 'oMMMo', 'oMoMM', 'oMMoM','oMoMo')) and wave in (7);
QUIT;

data ys;
	set y1 y2 y3 y4;
	if wave=7 then wave-5;
	else if wave=9 then wave=7;
	else if wave=11 then wave=9;
	else if wave=12 then wave=11;
run;

/******** combine covariates and outcome ************/
proc sort data=covars; 	by id wave;
proc sort data=ys; by id wave;
data merg1; merge covars ys; by id wave; run;

/* when  %let out=cog_imp_nommse*/
data merg1_select_nommse;
	set merg1;
	keep wave id &out
        age male white edu income apoe4 mar_cohab sum_pa sum_pa_all mvpa_calcu lmvpa_calcu 
        fruit_veg mind current_smk hv_drink cvd depress my_sbp my_blchol my_bmi my_gluc_f;
run;

/* when %let out=cog_imp */
data merg1_select;
	set merg1;
	keep wave id &out
        age male white edu income apoe4 mar_cohab sum_pa sum_pa_all mvpa_calcu lmvpa_calcu 
        fruit_veg mind current_smk hv_drink cvd depress my_sbp my_blchol my_bmi my_gluc_f;
run;

/**********keep only until 1st cog impairment************/
/* no mmse: data used for main analysis */
proc sort data=merg1_select_nommse; 	by id wave; run;
data merg1_select_nommse1;
	set merg1_select_nommse;
	by id;
	retain found;
	if first.id then found=0;
	if found=0 then do;
	   output;
       if cog_imp_nommse=1 then found=1;
	   end;
run;

proc export data=merg1_select_nommse1 outfile='P:\yzhang\Whitehall II\AAIC\cog_nommse_3011_1st.csv' dbms=csv replace;
run;

/* use mmse: data used for sensitivity analysis */
proc sort data=merg1_select; 	by id wave; run;
data merg1_select1;
	set merg1_select;
	by id;
	retain found;
	if first.id then found=0;
	if found=0 then do;
		output;
		if cog_imp=1 then found=1;
		end;
run;

proc export data=merg1_select1 outfile='P:\yzhang\Whitehall II\AAIC\cog_imp_3032_1st.csv' dbms=csv replace;
run;

/*************descriptive statistics at w5*****************/
data merg1_select_nommse2;
	set merg1_select_nommse1;

	if my_SBP>=130 then bp=1;
	else if 0<=my_SBP<130 then bp=0;

	if my BLCHOL>=6.18 then chol=1;
	else if 0<=my_BLCHOL<6.18 then chol=0;

	if my GLUC_F>=7 then dm_g='c_diabetes';
	else if 5.6<=my_GLUC_F<7 then dm_g='b_pre_dm';
	else if 0<=my_GLUC_F<5.6 then dm_g='a_normal';

	if 75<=mvpa_calcu<150 then mvpa_g="b_75_150";
	else if mvpa_calcu >=150 then mvpa_g="c_>=150";
	else if 0<=mvpa_calcu<75 then mvpa_g="a_<75";

	if my_bmi <18.5 then bmi_g=1;
	else if 18.5 <=my_bmi< 25 then bmi_g=2;
	else if 25 <=my_bmi <30 then bmi_g=3;
	else if 30 <=my_bmi then bmi_g=4;

	if 75<=lmvpa_calcu<150 then lmvpa_g="b_75_150";
	else if lmvpa_calcu >=150 then lmvpa_g "c_>=150";
	else if 0<=lmvpa_calcu<75 then lmvpa_g="a_<75";

	if mind>=8.5 then mind_60=1;
	else mind_60=0;
	where wave=5;
run;

proc means data=merg1_select_nommse2 n mean std nmiss maxdec=1;
	var age edu my_sbp my_blchol my_gluc_f my_bmi mind mvpa_calcu lmvpa_calcu;
	where wave=5;
run;

proc freq data-merg1_select_nommse2;
	table male mar_cohab income apoe4 cvd depress bp chol dm_g bmi_g current_smk hv_drink mind_60 mvpa_g lmvpa_g;
	where wave=5;
run;
