LIBNAME aaic'P:\yzhang\Whitehall II\AAIC';
RUN;
%let path = P:\yzhang\Whitehall II\Data;

/*A few macros*/
%macro import_spss;
	proc import datafile="&path\&file" out=%scan(&file, 1, .) 
			/* Dataset name from the filename without .sav */
			dbms=sav replace;
	run;

%mend;

/*will use the 2011 calculated MVPA but as to July 2025,
the requested mild PA not available yet, so will calculate total PA using variables below.
Then then mild_moderate = total vigrous_2011_calculated; */
data pa_names;
	input WLKOUTA WLKOUTB PEDCYCA PEDCYCB SOCCERF SOCCERH GOLFF GOLFH SWIMF SWIMH 
		SPORT1 SPORTIF SPORT1H SPORT2 SPORT2F SPORT2H WEEDF WEEDH MOWF MOWH GARDN1 
		GARDN1F GARDN1H CARRYHF CARRYHH COOKF COOKH HANGWF HANGWH HOUSW1 HOUSW1F 
		HOUSW1H HOUSW2 HOUSW2F HOUSW2H CARWASF CARWASH PAIDECF PAIDECH DIY DIY1F 
		DIY1H PHYSA1 PHYSA1F PHYSA1H PHYSA2 PHYSA2F PHYSA2H;
	cards;
;
run;

	/**let file=HES_0281_S_ver2; import_spss;*/
	/*rename*/
DATA quest_names;
	input AGE_Q_5 PART PARTTYP QUESTYP notmar PEDCYCA PEDCYC SOCCERF soccerh golff 
		golfh swimf swimh sportif sportih sport2f sport2h weedf weedh mowf mowh 
		gardnlf gardnih carwasf carwash paidecf paidech diylf diylh FRUITVG smoke 
		alcwk0 ANG MI STRDIAG OHT HF ENHT INCLAU NKEM01 NKEM02 NKEM03 wlkouta wlkoutb 
		carryhf carryhh cookf cookh hangwf hangwh houswif houswih housw2f housw2h 
		PHYSA1F PHYSA1H PHYSA2F PHYSA2H;
	cards;
;
run;

DATA screen_names;
	input AGE SGP SBP BLCHOL BMI GLUC_F mm_scor SWORDS MEM AH4 MH:
cards;
	;
run;

DATA add_names;
	input AGE_C AGE_S ANIMALS UNITWKO ALCWKO BEERWKO BERUWKO NONDRNK SPRTWKO 
		WINEWKO SMKSTRT SMKSTOP ESMOKE PHYSA1 PHYSA11 PHYSA12 PHYSA13 PHYSA2 PHYSA21 
		PHYSA22 PHYSA23 STATUSX;
	cards;
;
run;

DATA food_names;
	input beef pork lamb bacon ham cornbf sausag savpies liver wholbrd brice 
		whpasta spinach greens leeks salad carrots broccol sprouts cabbage peas beans 
		marrow caulifl parsnip onions mushroo peppers tomato strawb whifish oilfish 
		shefish chick bakedb lentils tofu nuts peanutb beefbur batfish fishfin butter 
		hardmar cheese cotche biscuit cakes buns tarts milkpud sponge icecrea choc 
		sweets wine beer port liqu spirits;
	cards;
;
run;

	/* Conversion of duration data into duration of activity involves attribution of */
	/* the mid-point duration for every category. */
	%macro convert(var1);
		/*duration in mins*/
		if &var1=0 then
			&var1=0/4*60;

		if &var1=1 then
			&var1=0.5/4*60;

		if &var1=2 then
			&var1=1.25/4*60;

		if &var1=3 then
			&var1=2.5/4*60;

		if &var1=4 then
			&var1=4.5/4*60;

		if &var1=5 then
			&var1=8/4*60;

		if &var1=6 then
			&var1=12/4*60;
	%mend;

	/*keep variables*/
	%macro select_var(dat_ori, dat_new);
	data &dat_new;
		set &dat_ori;
		keep wave id age male white edu income apoe4 sum_pa_all_recode mvpa_calcu mar 
			cohab fruit_veg mind current smk hv drink cvd depress bp chol bmi_g dm_g 
			cog_imp cog_imp_nommse my_sbp my_blchol my_bmi my_gluc_f;
	run;

%mend;

/*cognitive impairment*/
%macro cog_test(dat, var1, var2);
	proc sort data=&dat;
		by wave;
	run;

	/*regress*/
	proc reg data=&dat;
		/*id id_random_dpuk; */
		by wave;
		model &var1=age male edu;
		output out=residual_dat r=resid;
		run;

	proc reg data=&dat outest=outest noprint;
		by wave;

		/*id id_random_dpuk; */
		model &var1=age male edu/rmse;
		run;

	proc sql noprint;
		select _rmse_ into :rmsel-:rmse6 from outest;
	quit;

	/*standard resid*/
	data residual_dat;
		set residual_dat;

		if wave=3 then
			resid_std=resid/&rmsel.;

		if wave=5 then
			resid_std=resid/&rmse2.;

		if wave=7 then
			resid_std=resid/&rmse3.;

		if wave=9 then
			resid_std=resid/&rmse4.;

		if wave=11 then
			resid_std=resid/&rmse5.;

		if wave=12 then
			resid_std=resid/&rmse6.;

		if resid_std<-1.5 and resid_std^=. then
			&var2=1;

		if resid_std>=-1.5 then
			&var2=0;
	run;

	proc sort data=&dat;
		by id wave;

	proc sort data=residual_dat;
		by id wave;

	data &dat;
		merge &dat (in=a) residual_dat;
		by id wave;

		if a;
		drop resid resid_std;
	run;

%mend;

/*wave 12: no my_mh*/
%macro cog_testi(dat, varl, var2);
	proc sort data=&dat;
		by wave;
	run;

	/*regress*/
	proc reg data=&dat;
		/*id id_random_dpuk; */
		by wave;
		model &var1=age male edu;
		output out=residual_dat r=resid;
		where wave ^=12;
		run;

	proc reg data=&dat outest=outest noprint;
		by wave;

		/*id id_random_dpuk;*/
		model &var1=age male edu/rmse;
		where wave ^=12;
		run;

	proc sql noprint;
		select _rmse_ into :rmsel-:rmse5 from outest;
	quit;

	/*standard resid*/
	data residual_dat;
		set residual_dat;

		if wave=3 then
			resid_std=resid/&rmsel.;

		if wave=5 then
			resid_std=resid/&rmse2.;

		if wave=7 then
			resid_std=resid/&rmse3.;

		if wave=9 then
			resid_std=resid/&rmse4.;

		if wave=11 then
			resid_std=resid/&rmse5.;

		if resid_std<-1.5 and resid_std^=. then
			&var2=1;

		if resid_std>=-1.5 then
			&var2=0;
	run;

	proc sort data=&dat;
		by id wave;

	proc sort data=residual_dat;
		by id wave;

	data &dat;
		merge &dat (in=a) residual_dat;
		by id wave;

		if a;
		drop resid resid_std;
	run;

%mend;

/*----------------------------*/
/*            FFQ            */
/*Out: aaic.ffq3_11           */
/*----------------------------*/
%let file = s3ffq_0281.sav;
%import_spss;
%let file = s5ffq_0281_S.sav;
%import_spss;
%let file = s7ffq_0281_S.sav;
%import_spss;
%let file = s9ffq_0281_S.sav;
%import_spss;
%let file = s11ffq_0281_S.sav;
%import_spss;

/*W3*/
proc sql noprint;
	select cats ("My_", name), cats ('X', name, "=", "My_", name) into :quest_new 
		separated by ' ', :quest_rename separated by ' ' from dictionary.columns 
		where libname='WORK' and memname="FOOD_NAMES";
quit;

DATA ffq3;
	set s3ffq_0281;
	xsprouts=xsprout;
	xsavpies=xsavpie;
	xwhpasta=xwhpast;
	xpeanutb=xpeanub;
	xbeefbur=xbeefbu;
	xbatfish=xbatfis;
	wave=3;
run;

DATA ffq3;
	set ffq3 (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	keep id &quest_new wave;
run;

/*w5*/
proc sql noprint;
	select cats ("My_", name), cats ('t', name, "=", "My_", name) into :quest_new 
		separated by ' ', :quest_rename separated by ' ' from dictionary.columns 
		where libname='WORK' and memname="FOOD NAMES";
quit;

DATA ffq5;
	set s5ffq_0281_s (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	wave=5;
	keep id &quest_new wave;
run;

/*w7*/
proc sql noprint;
	select cats ("My_", name), cats ('m', name, "=", "My_", name) into :quest new 
		separated by ' ', :quest_rename separated by ' ' from dictionary.columns 
		where libname='WORK' and memname="FOOD_NAMES";
quit;

DATA ffq7;
	set s7ffq_0281_s (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	wave=7;
	keep id &quest_new wave;
run;

/*w9*/
proc sql noprint;
	select cats ("My_", name), cats ('j', name, "=", "My_", name) into :quest_new 
		separated by ' ', :quest_rename separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="FOOD_NAMES";
quit;

DATA ffq9;
	set s9ffq_0281_s (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	wave=9;
	keep id &quest_new wave;
run;

/*combine w3,5,7,9*/
data ffq3_9;
	set ffq3 ffq5 ffq7 ffq9;
run;

data ffq3_9a;
	set ffq3_9;

	/*red meat*/
	array vars[53] My_beef My_pork My_lamb My_bacon My_ham My_cornbf My_sausag 
		My_savpies My_liver my wholbrd my_brice my_whpasta my_spinach my greens 
		my_leeks my_salad My carrots My broccol My_sprouts My_cabbage My_peas My 
		beans My_marrow My_caulifl My_parsnip My_onions My_mushroo My peppers 
		My_tomato My whifish My_oilfish My_shefish My bakedb My_lentils My_tofu My 
		nuts My peanutb My beefbur My_batfish My_fishfin My butter My hardmar My 
		cheese My_cotche My biscuit My_cakes My_buns My_tarts My_milkpud My sponge 
		My_icecrea My_choc My_sweets;
	array recode[53] beef pork lamb bacon ham cornbf sausag savpies liver wholbrd 
		brice whpasta spinach greens leeks salad carrots broccol sprouts cabbage peas 
		beans marrow caulifl parsnip onions mushroo peppers tomato whifish oilfish 
		shefish bakedb lentils tofu nuts peanutb beefbur batfish fishfin butter 
		hardmar cheese cotche biscuit cakes buns tarts milkpud sponge icecrea choc 
		sweets;

	do i=1 to 53;

		select (vars[i]);
			when (1) recode[i]=0;
			when (2) recode[i]=2/4.35;
			when (3) recode[i]=1;
			when (4) recode[i]=3;
			when (5) recode[i]=5.5;
			when (6) recode[i]=7;
			when (7) recode[i]=2.5*7;
			when (8) recode[i]=4.5*7;
			when (9) recode[i]=6.5*7;
			otherwise recode[i]=.;
		end;
	end;
	red_meat_sum=sum(of beef pork lamb bacon ham cornbf sausag savpies liver);

	if 6<red_meat_sum then
		red_meat=0;
	else if 4<red_meat_sum<=6 then
		red_meat=0.5;
	else if 0<=red_meat_sum<=4 then
		red_meat=1;
	whole_grain_sum=sum (of wholbrd brice whpasta);

	if 0<=whole_grain_sum<7 then
		whole_grain=0;
	else if 7<=whole_grain_sum <=14 then
		whole_grain=0.5;
	else if 14<whole_grain_sum then
		whole_grain=1;
	leafy_sum=sum (of spinach greens leeks salad);

	if 0<=eafy_sum<=2 then
		leafy=0;
	else if 2<leafy_sum<=6 then
		leafy=0.5;
	else if 6<leafy_sum then
		leafy=1;
	veg_sum=sum (of carrots broccol sprouts cabbage peas beans marrow caulifl 
		parsnip onions mushroo peppers tomato);

	if 0<=veg_sum<5 then
		veg=0;
	else if 5<=veg_sum<=6 then
		veg=0.5;
	else if 6<veg_sum then
		veg=1;

	if my_strawb in (1, 2) then
		berry=0;
	else if my_strawb=3 then
		berry=0.5;
	else if 4<=my_strawb then
		berry=1;
	fish_sum=sum (of whifish oilfish shefish);

	if 0<=fish_sum <0.23 then
		fish=0;
	else if 0.23<=fish_sum <1 then
		fish=0.5;
	else if 1<=fish_sum then
		fish=1;

	if My_chick in (1, 2) then
		poultry=0;
	else if My_chick=3 then
		poultry=0.5;
	else if 4<=My_chick<=9 then
		poultry=1;
	beans_sum=sum (of bakedb lentils tofu);

	if 0<=beans_sum<1 then
		beans=0;
	else if 1<=beans_sum<=3 then
		beans=0.5;
	else if 3<beans_sum then
		beans=1;
	nuts_sum=sum(of nuts peanutb);

	if 0<=nuts_sum<0.23 then
		nuts=0;
	else if 0.23<=nuts_sum<5 then
		nuts=0.5;
	else if 5<=nuts_sum then
		nuts=1;
	fried_sum=sum (of beefbur batfish fishfin);

	if 3 < fried_sum then
		fried=0;
	else if 1 <=fried_sum <=3 then
		fried=0.5;
	else if 0 <=fried_sum < 1 then
		fried=1;
	butter_sum=sum(of butter hardmar);

	if 14 <butter_sum then
		butter=0;
	else if 7<=butter_sum<=14 then
		butter=0.5;
	else if 0<=butter_sum<7 then
		butter=1;
	cheese_sum=sum(of cheese cotche);

	if 0<=cheese_sum<1 then
		cheese=0;
	else if 1<=cheese_sum<=6 then
		cheese=0.5;
	else if 6<cheese_sum then
		cheese=1;
	sweet_sum=sum(of biscuit cakes buns tarts milkpud sponge icecrea choc sweets);

	if 6<sweet_sum then
		sweet=0;
	else if 5<=sweet_sum<=6 then
		sweet=0.5;
	else if 0<=sweet_sum<5 then
		sweet=1;

	if My_wine=1 then
		wine=0;
	else if 2<=My_wine<=5 then
		wine=0.5;
	else if 6<=My_wine<=9 then
		wine=1;
	mind=sum (of whole_grain red_meat leafy veg berry fish poultry beans nuts 
		fried butter cheese sweet wine);
	keep id wave mind;
run;

/*w11*/
proc contents data=s11ffq_0281_s order=varnum;
run;

proc sql noprint;
	select cats ("My_", name), cats ('f', name, "=", "My_", name) into :quest_new 
		separated by ' ', :quest_rename separated by ' 'from dictionary.columns where 
		libname='WORK' and memname="FOOD_NAMES";
quit;

DATA ffq11;
	set siiffq_0281_s;
	id=input (id_random_DPUK, best32.);
	wave=11;
	array vars[15] FHAMOTH FLIVER FREDMEAT FBACSAUS FBWHPASR FBWHBRD FFISHFIN 
		FBATFISH FBUTTER FMARSPRD FCONFECT FCHOCSWE FICECREA FPEALEGU FSOYA;
	array recode[15] HAMOTH LIVER REDMEAT BACSAUS BWHPASR BWHBRD FISHFIN BATFISH 
		BUTTER MARSPRD CONFECT CHOCSWE ICECREA PEALEGU SOYA;

	do i=1 to 15;

		select (vars[i]);
			when (1) recode[i]=0;
			when (2) recode[i]=2/4.35;
			when (3) recode[i]=1;
			when (4) recode[i]=3;
			when (5) recode[i]=5.5;
			when (6) recode[i]=7;
			when (7) recode[i]=2.5*7;
			when (8) recode [i] 4.5*7;
			when (9) recode [i]=6.5*7;
			otherwise recode[i]=.;
		end;
	end;
	red_meat_sum=sum(of HAMOTH LIVER REDMEAT BACSAUS);

	if 6<red_meat_sum then
		red_meat=0;
	else if 4<red_meat_sum<=6 then
		red_meat=0.5;
	else if 0<=red_meat_sum<=4 then
		red_meat=1;
	whole_grain_sum=sum (of BWHPASR BWHBRD);

	if 0<=whole_grain_sum<7 then
		whole_grain=0;
	else if 7<=whole_grain_sum <=14 then
		whole_grain=0.5;
	else if 14<whole_grain_sum then
		whole_grain=1;

	if FFISH=1 then
		fish=0;
	else if FFISH-2 then
		fish=0.5;
	else if 3<=FFISH<=9 then
		fish=1;
	fried_sum=sum (of FISHFIN BATFISH);

	if 3 < fried_sum then
		fried=0;
	else if 1 <=fried_sum <=3 then
		fried=0.5;
	else if 0<=fried_sum < 1 then
		fried=1;

	if FCHICK in (1, 2) then
		poultry=0;
	else if FCHICK=3 then
		poultry=0.5;
	else if 4<=FCHICK<=9 then
		poultry=1;

	if 6<=FCHEESE<=9 then
		cheese=0;
	else if FCHEESE in (3, 4, 5) then
		cheese=0.5;
	else if FCHEESE in (1, 2) then
		cheese=1;
	butter_sum=sum(of BUTTER MARSPRD);

	if 14 <butter_sum then
		butter=0;
	else if 7<=butter_sum<=14 then
		butter=0.5;
	else if 0<=butter_sum<7 then
		butter=1;
	sweet_sum=sum (of CONFECT CHOCSWE ICECREA);

	if 6<sweet sum then
		sweet=0;
	else if 5<=sweet_sum<=6 then
		sweet=0.5;
	else if 0<=sweet_sum<5 then
		sweet=1;

	if FNUTS=1 then
		nuts=0;
	else if FNUTS in (2, 3, 4) then
		nuts=0.5;
	else if 5<=FNUTS<-9 then
		nuts=1;
	beans_sum=sum (of FPEALEGU FSOYA);

	if 0<=beans_sum<1 then
		beans=0;
	else if 1<=beans_sum<=3 then
		beans=0.5;
	else if з<beans_sum then
		beans=1;

	if FOLIVOIL in (1, 2) then
		olive=0;
	else if FOLIVOIL in (3, 4, 5) then
		olive-0.5;
	else if FOLIVOIL in (6, 7, 8, 9) then
		olive=1;

	if 1<=FVEGS<=4 then
		veg=0;
	else if FVEGS=5 then
		veg=0.5;
	else if 6<=FVEGS then
		veg=1;

	if FWINE=1 then
		wine=0;
	else if 2<=FWINE<=5 then
		wine=0.5;
	else if 6<=FWINE<=9 then
		wine=1;
	mind=sum (of wine veg olive beans nuts sweet butter cheese poultry fried fish 
		whole_grain red meat) /13*14;
	keep id wave mind;
run;

data aaic.ffq3_11;
	set ffq3_9a ffq11;
run;

/* -------------------combine wave 5-12  -------------------*/
/*  -------------------out: comble  -------------------*/
/*new requested variables*/
proc import datafile='P:\yzhang\Whitehall II\AAIC\new_dat_noNA.csv' 
		out=new_data dbms=csv replace;
	getnames=yes;
run;

/*PA */

%let file = PA_APOE_ver3update_S.sav;
%import_spss;

/*w5*/
%let file = s5quest_0281_S.sav;
%import_spss;
%let file = s5screen_0281_S.sav;
%import_spss;

/*baseline: age, sex, ethnivity, education martial*/
data aaic.base;
	set s5quest_0281_S;
	id=input (id_random_DPUK, best32.);

	/*sex*/
	if sex=1 then
		male=1;

	if sex=2 then
		male=0;

	/*ethnicity*/
	if ETHN_DS=1 then
		white=1;
	else if ETHN_DS=2 then
		white=0;
	edu=TEDTOTYR;
	income=TINCHH4;
	keep id white male edu income;
run;

/*APOE*/
data aaic.APOE;
	set PA_APOE_ver3update_S;
	id=input (id_random_DPUK, best32.);
	keep id apoe4;
RUN;

/*orignial name*/
/*change "t" to other letters*/
proc sql noprint;
	select cats ("My_", name), cats ('t', name, "=", "My_", name) into :quest_new 
		separated by ' ', :quest rename separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="QUEST_NAMES";
quit;

proc sql noprint;
	select cats ("My_", name), cats ('t', name, "=", "My_", name) into :screen_new 
		separated by ' ', :screen_rename separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="SCREEN_NAMES";
quit;

proc sql noprint;
	select cats ("My_", name), cats ('t', name, "=", "My_", name), into :add_new 
		separated by ' ', :add_rename separated by ' ' from dictionary.columns 
		where libname='WORK' and memname="ADD_NAMES";
quit;

/*rename*/
DATA QUEST5;
	set s5quest_0281_S (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	keep id &quest_new;
run;

DATA screen5;
	set s5screen_0281_S (rename=(&screen_rename));
	id=input (id_random_DPUK, best32.);
	keep id &screen_new;
run;

data empty;
	input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data;
	by id_random_DPUK;
run;

data tmp1;
	merge empty new_data;
	by id_random_DPUK;
run;

data add5;
	set tmp1 (rename=(&add_rename));
	id=input (id_random_DPUK, best32.);
	keep id &add_new;
run;

proc sort data-quest5;
	by id;

proc sort data=screen5;
	by id;

proc sort data=add5;
	by id;
run;

data w5;
	merge quest5 screen5 add5;
	by id;
	wave=5;
run;

/*w7*/
%let file = 87quest_0281_S.sav;
%import_spss;
%let file = 87screen_0281_S.sav;
%import_spss;

proc sql noprint;
	select cats ("My_", name), cats ('m', name, "=", "My_", name) into :quest_new 
		separated by ' ', :quest_rename separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="QUEST_NAMES" and name not in ('HF', 'ENHT', 
		'INCLAU');
quit;

proc sql noprint;
	select cats ("My_", name), cats ('m', name, "=", "My_", name) into :screen_new 
		separated by ' ', :screen rename separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="SCREEN_NAMES";
quit;

proc sql noprint;
	select cats ("My_", name), cats ('m', name, "=", "My ", name), cats ('m', name) 
	into :add_new separated by ' ', :add_rename separated by ' ', 
		:retian_name separated by ' ' from dictionary.columns 
		where libname='WORK' and memname="ADD_NAMES";
quit;

DATA QUEST7;
	set s7quest_0281_S (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	keep id &quest_new;
run;

DATA screen7;
	set s7screen_0281_S (rename=(&screen_rename));
	id=input (id_random_DPUK, best32.);
	keep id &screen_new;
run;

data empty;
	input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data;
	by id_random_DPUK;
run;

data tmp1;
	merge empty new_data;
	by id_random_DPUK;
run;

data add7;
	set tmp1 (rename=(&add_rename));
	id=input (id_random_DPUK, best32.);
	keep id &add_new;
run;

proc sort data=quest7;
	by id;

proc sort data=screen7;
	by id;

proc sort data=add7;
	by id;
run;

data w7;
	merge quest7 screen7 add7;
	by id;
	wave=7;
run;

/*w9*/
%let file = s9quest_0281_S.sav;
%import_spss;
%let file = s9screen_0281_S.sav;
%import_spss;

proc sql noprint;
	select cats ("My_", name), cats ('J', name, "=", "My_", name) into :quest_new 
		separated by ' ', :quest_rename separated by' 'from dictionary.columns where 
		libname='WORK' and memname="QUEST_NAMES" and name not in ('HF', 'ENHT');
quit;

proc sql noprint;
	select cats ("My_", name), cats ('J', name, "=", "My_", name) into :screen_new 
		separated by ' ', :screen rename separated by' 'from dictionary.columns 
		where libname='WORK' and memname="SCREEN_NAMES";
quit;

proc sql noprint;
	select cats ("My_", name), cats ('J', name, "=", "My_", name), cats ('J', 
		name) into :add_new separated by ' ', :add_rename separated by ' ', 
		:retain_name separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="ADD_NAMES";
quit;

DATA QUEST9;
	set s9quest_0281_S (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	keep id &quest_new;
run;

DATA screen9;
	set 39screen_0281_S (rename=(&screen_rename));
	id=input (id_random_DPUK, best32.);
	keep id &screen_new;
run;

data empty;
	input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data;
	by id_random_DPUK;
run;

data tmp1;
	merge empty new_data;
	by id_random_DPUK;
run;

data add9;
	set tmp1 (rename=(&add_rename));
	id=input (id_random_DPUK, best32.);
	keep id &add_new;
run;

data w9;
	merge quest9 screen9 add9;
	by id;
	wave=9;
run;

/*w11*/
%let file = s11quest_0281_S.sav;
%import_spss;
%let file = s11screen_0281_S.sav;
%import_spss;

proc sql noprint;
	select cats ("My_", name), cats ('F', name, "=", "My_", name) into :quest new 
		separated by ' ', :quest rename separated by' 'from dictionary.columns 
		where libname='WORK' and memname="QUEST NAMES" and name not in ('HF', 'ENHT', 
		'INCLAU');
quit;

proc sql noprint;
	select cats ("My_", name), cats ('F', name, "=", "My_", name) into :screen_new 
		separated by ' ', :screen rename separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="SCREEN_NAMES";
quit;

proc sql noprint;
	select cats ("My_", name), cats ('F', name, "=", "My_", name), cats ('F', 
		name) into :add_new separated by ' ', :add_rename separated by ' ', 
		:retain_name separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="ADD_NAMES";
quit;

DATA QUEST11;
	set s1lquest_0281_S (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	keep id &quest_new;
run;

DATA screen11;
	set sllscreen_0281_S (rename=(&screen_rename));
	id=input (id_random_DPUK, best32.);
	keep id &screen_new;
run;

data empty;
	input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data;
	by id_random_DPUK;
run;

data tmp1;
	merge empty new_data;
	by id_random_DPUK;
run;

data add11;
	set tmp1 (rename=(&add_rename));
	id=input (id_random_DPUK, best32.);
	keep id &add_new;
run;

data w11;
	merge quest11 screen11 add11;
	by id;
	wave=11;
run;

/*w12*/
%let file = s12quest_0281_S.sav;
%import_spss;
%let file = s12screen_0281_S.sav;
%import_spss;

proc sql noprint;
	select cats ("My_", name), cats ('D', name, "=", "My_", name) into :quest new 
		separated by ' ', :quest_rename separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="QUEST_NAMES" and name not in ('HF', 'ENHT');
quit;

proc sql noprint;
	select cats ("My_", name), cats ('D', name, "=", "My_", name) into :screen_new 
		separated by ' ', :screen_rename separated by' 'from dictionary.columns 
		where libname='WORK' and memname="SCREEN_NAMES" and name not in ('MH');
quit;

DATA QUEST12;
	set s12quest_0281_S (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	keep id &quest_new;
run;

DATA screen12;
	set s12screen_0281_S (rename=(&screen_rename));
	id=input (id_random_DPUK, best32.);
	keep id &screen_new;
run;

proc sql noprint;
	select cats ("My_", name), cats ('D', name, "=", "My_", name), cats ('D', 
		name) into :add_new separated by ' ', :add_rename separated by ' ', 
		retian_name separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="ADD_NAMES";
quit;

data empty;
	input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data;
	by id_random_DPUK;
run;

data tmp1;
	merge empty new_data;
	by id_random_DPUK;
run;

data add12;
	set tmp1 (rename=(&add_rename) );
	id=input (id_random_DPUK, best32.);
	keep id &add_new;
run;

data w12;
	merge quest12 screen12 add12;
	by id;
	wave=12;
run;

/*W3*/
%let file = s3quest_0281_S.sav;
%import_spss;
%let file = s3screen_0281_5.sav;
%import_spss;

proc sql noprint;
	select cats ("My_", name), cats ('X', name, "=", "My_", name) into :quest_new 
		separated by ' ', :quest_rename separated by ' ' from dictionary.columns 
		where libname='WORK' and memname="QUEST_NAMES" and name in ('AGE_Q_5', 
		'FRUITVG', 'smoke', 'alcwk0', 'NKEM01', 'NKEM02', 'NKEM03');
quit;

proc sql noprint;
	select cats ("My_", name), cats ('X', name, "=", "My_", name) into :screen new 
		separated by ' ', :screen rename separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="SCREEN_NAMES" and name not in ('mm_scor');
quit;

DATA QUEST3;
	set s3quest_0281_S (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	keep id &quest_new XMARCOH;
run;

DATA screen3;
	set s3screen_0281_S (rename=(&screen_rename));
	id=input (id_random_DPUK, best32.);
	keep id &screen_new;
run;

proc sql noprint;
	select cats ("My_", name), cats ('X', name, "=", "My_", name), cats ('X', 
		name) into : add_new separated by ' ', : add_rename separated by ' ', 
		:retain_name separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="ADD_NAMES";
quit;

data empty;
	input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data;
	by id_random_DPUK;
run;

data tmp1;
	merge empty new_data;
	by id_random_DPUK;
run;

data add3;
	set tmp1 (rename=(&add_rename));
	id=input (id_random_DPUK, best32.);
	keep id &add_new;
run;

/*w4*/
%let file = s4quest_0281_S.sav;
%import_spss;

data quest4_cvd;
	set s4quest_0281_S;

	/*cvd*/
	if VANG=1 or vMI=1 or vSTR=1 or VOHT=1 then
		cvd4=1;

	if VANG=2 and vMI=2 and VSTR=2 and VOHT=2 then
		cvd4=0;
	id=input (id_random_DPUK, best32.);
	keep id cvd4 VMARCOH;
run;

/*w1 and w2*/
%let file = s2quest_0281_S.sav;
%import_spss;

data s2;
	set s2quest_0281_S;
	id=input (id_random_DPUK, best32.);
	keep id ZSTATUS;
run;

proc sql noprint;
	select cats ("My_", name), cats ('Z', name, "=", "My_", name), cats ('Z', 
		name) into :add_new separated by ' ', :add_rename separated by ' ', 
		:retain_name separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="ADD_NAMES";
quit;

data empty;
	input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data;
	by id_random_DPUK;
run;

data tmp1;
	merge empty new_data;
	by id_random_DPUK;
run;

data add2;
	set tmp1 (rename=(&add_rename));
	id=input (id_random_DPUK, best32.);
	wave=2;
	keep id &add_new wave;
run;

/*W1*/
%let file = s1quest_0281_S.sav;
%import_spss;

data s1;
	set s1quest_0281_S;
	id=input (id_random_DPUK, best32.);
	keep id STATUS;
run;

proc sql noprint;
	select cats ("My_", name), cats (name, "=", "My_", name), cats (name) 
		into :add_new separated by ' ', : add_rename separated by ' ', :retain_name 
		separated by ' 'from dictionary.columns 
		where libname='WORK' and memname="ADD_NAMES";
quit;

data empty;
	input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data;
	by id_random_DPUK;
run;

data tmp1;
	merge empty new_data;
	by id_random_DPUK;
run;

data add1;
	set tmp1 (rename=(&add_rename));
	id=input (id_random_DPUK, best32.);
	wave=1;
	keep id &add_new wave;
run;

/*combine w3 and 4 here for imputation purpose, let wave=3*/
data w3_4;
	merge quest3 screen3 quest4 cvd s1 s2 add3;
	by id;
	wave=3;
run;

data comb1_4;
	set add1 add2 w3_4;
run;

/*impute the missing in R*/
proc export data=comb1_4 outfile='P:\yzhang\Whitehall II\AAIC\comb1_4.csv' 
		dbms=csv replace;
run;

proc import datafile="P:\yzhang\Whitehall II\AAIC\comb1_4_fill.csv" 
		out=comb1_4_fill dbms=csv replace;
	guessingrows=max;
run;

/*marital status, using my_statusx*/
data comb1_4_char;
	set comb1_4;
	keep id wave My AGE_Q_5 My_FRUITVG My_smoke My_NKEM01 My_NKEM02 My_NKEM03;
	where wave=3;
run;

proc sort data=comb1_4_char;
	by id wave;

proc sort data=comb1_4_fill;
	by id wave;

data comb1_4_fill_all;
	merge comb1_4_char comb1_4_fill;
	by id wave;
run;

/*combine w5-w12*/
data w9a;
	set w9 (rename=(My_PEDCYCA=My_PEDCYCA1 My_PEDCYCb=My_PEDCYCb1 
		My_wlkouta=My_wlkoutal My_wlkoutb My_wlkoutbl));
	My_PEDCYCA=My_PEDCYCA1+0;
	My_PEDCYCb=My_PEDCYCb1+0;
	My_wlkouta=My_wlkoutal+0;
	My_wlkoutb My_wlkoutb1+0;
run;

data combl;
	set comb1_4_fill_all w5 w7 w9a w11 w12;
run;

/*ignore the labels in the print out
frequency: none-0, 1-2 = 1, 3-4-2, 5-10-3, 11-15 -4 16-20-5 21+=6*/
data combla_recode;
	set comb1;
	array w5fvars {*} My_SOCCERF My_golff My_swimf My_sportif My_sport2f My_weedf 
		My_mowf My_gardnlf My_carwasf My_paidecf My_diylf My PHYSA1f My_PHYSA2f My 
		carryhf My_cookf My_hangwf My_houswlf My_housw2f;
	array w5hvars{*} My_SOCCERh My_golfh My_swimh My_sportih My_sport2h My weedh 
		My_mowh My_gardnih My_carwash My_paidech My_diylh My PHYSA1h My PHYSA2h 
		My_carryhh My_cookh My_hangwh My_houswih My_housw2h;

	if wave=5 then
		do;

			do i=1 to dim (w5fvars);
				w5fvars[i]=w5fvars[i] -1;
				w5hvars[i]=w5hvars[i] -1;
			end;
		end;
run;

/*length: mins/wk*/
data comb1b;
	set combla_recode;
	%convert (My_soccerh);
	%convert (My_golfh);
	%convert (My_swimh);
	%convert (My_sportih);
	%convert (My_sport2h);
	%convert (My weedh);
	%convert (My_mowh) %convert (My_gardnih);
	%convert (My_carwash);
	%convert (My_paidech);
	%convert (My_diy1h);
	%convert (My_PHYSA1H);
	%convert (My PHYSA2H);
	%convert (My_carryhh);
	%convert (My cookh);
	%convert (My hangwh);
	%convert (My_houswih);
	%convert (My_housw2h);
run;

/*alcohol*/
data tmp;
	set comb1b;
	drink_unit=sum (of My_BEERWKO, My_SPRTWKO, My_WINEWKO);

	if drink_unit> 14 then
		hv_drink=1;
	else if 0<=drink_unit<14 then
		hv_drink=0;
	else if My_NONDRNK=1 then
		hv_drink=0;
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

proc sort data=tmp2;
	by id wave;

proc sort data=ffq_drkl;
	by id wave;

proc sort data=ffq_drk2;
	by id wave;

data tmp2a;
	merge tmp2 (in=a) ffq_drk1 ffq_drk2;
	by id wave;

	if a;
run;

data tmp2b;
	set tmp2a;
	array vars[8] My_beer My_liqu My_port My_spirits My_wine FBEER FLIQUALL FWINE;
	array recode[8] My_beer1 My_liqul My_port1 My_spirits1 My_winel FBEER1 
		FLIQUALL1 FWINE1;

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
	alc_sum=sum (of My_beer1 My_liqul My_port1 My_spirits1 My_winel FBEER1 
		FLIQUALL1 FWINE1);

	if 14<=alc_sum then
		hv_drink=1;
	else if 0 <=alc_sum<14 then
		hv_drink=0;
	keep id wave hv_drink;
run;

data aaic.alchol;
	merge tmp tmp2b;
	by id wave;
run;

proc sort data=comb1b;
	by id wave;
run;

proc sort data=aaic.ffq3_11;
	by id wave;
run;

proc sort data=aaic.alchol;
	by id wave;
run;

data comb1c;
	merge combib (in=a) aaic.ffq3_11 aaic.alchol;
	by id wave;

	if a;
run;

data aaic.combid;
	set combic;
	age=My_AGE_C;

	/*cycle*/
	cycle=sum(My_PEDCYCA*5, My_PEDCYCB*2);

	/*soccer*/
	if My_SOCCERF=0 and My_soccerh=. then
		soccer=0;
	else
		soccer=My_soccerh;

	/*golf*/
	if My_golff=0 and My_golfh=. then
		golf=0;
	else
		golf=My_golfh;

	/*swim*/
	if My_swimf=0 and My_swimh=. then
		swim=0;
	else
		swim=My_swimh;

	/*spt1*/
	if My_sportif=0 and My_sportih=. then
		spt1=0;
	else
		spt1=My_sportih;

	/*spt2*/
	if My_sport2f=0 and My_sport2h=. then
		spt2=0;
	else
		spt2=My_sport2h;

	/*weed*/
	if My_weedf=0 and My_weedh=. then
		weed=0;
	else
		weed=My_weedh;

	/*mow*/
	if My_mowf=0 and My_mowh=. then
		mow=0;
	else
		mow=My_mowh;

	/*tgardnih*/
	if My_gardn1f=0 and My_gardn1h=. then
		garden=0;
	else
		garden=My_gardn1h;

	/*carwash*/
	if My_carwasf=0 and My_carwash=. then
		carwash=0;
	else
		carwash=My_carwash;

	/*pdec*/
	if My_paidecf=0 and My_paidech=. then
		pdec=0;
	else
		pdec=My_paidech;

	/*diy*/
	if My_diylf=0 and My_diylh=. then
		diy=0;
	else
		diy=My_diylh;

	/*additional*/
	if My PHYSA1f=0 and My_PHYSA1H=. then
		physal=0;
	else
		physal=My_PHYSA1H;

	if My PHYSA2f=0 and My_PHYSA2H=. then
		physa2=0;
	else
		physa2=My_PHYSA2H;

	/*walk*/
	walk=sum (My_wlkouta*5, My_wlkoutb*5);

	/*carry*/
	if My_carryhf=0 and My_carryhh=. then
		carry=0;
	else
		carry=My_carryhh;

	/*cook*/
	if My_cookf=0 and My_cookh=. then
		cook=0;
	else
		cook=My_cookh;

	/*hang*/
	if My_hangwf=0 and My_hangwh=. then
		hang=0;
	else
		hang=My_hangwh;

	/*house*/
	if My_houswif=0 and My_houswih=. then
		house1=0;
	else
		house1=My_houswih;

	if My_housw2f=0 and My_housw2h=. then
		house2=0;
	else
		house2=My_housw2h;
	sum_pa_all=sum(cycle, soccer, golf, swim, spti, spt2, weed, mow, garden, 
		carwash, pdec, diy, physal, physa2, walk, carry, cook, hang, housel, house2);

	/*smoke*/
	if my_esmoke 3 then
		current_smk=1;
	else if my_esmoke in (1 2) then
		current_smk=0;

	/*cvd*/
	if cvd4=1 then
		cvd=1;

	if cvd4=0 then
		cvd=0;

	if my_ANG=1 or my_MI=1 or my_STRDIAG in (1, 2) or my_OHT=1 then
		cvd=1;

	if my_ANG=2 and my _MI-2 and mY_STRDIAG not in (1, 2) and my_OHT=2 then
		cvd=0;

	/*depress_anxiety*/
	if my_NKEM01=1 OR my_NKEM02=1 or my_NKEM03=1 then
		depress=1;
	else if my _NKEM01-2 and my_NKEM02=2 and my_NKEM03-2 then
		depress=0;

	/*marital*/
	/*for wave 5-12*/
	if my_statusx=1 then
		mar_cohab=1;
	else if my_statusx in (3, 4, 5) then
		mar_cohab=0;

	/*cognitive*/
	if 0<=my_mm_scor< 24 then
		cog1=1;
	else if my_mm_scor>=24 then
		cog1=0;
run;

/*calculated MVPA variables in 2011 paper*/
data pa_calcu;
	set PA_APOE_ver3update_S;
	id=id_random_DPUK;
	mvpa5=sum (TMODHR_S, TVIGHR_S)*60;
	mvpa7=sum (mMODHR_S, mVIGHR_S)*60;
	mvpa9=sum (jMODHR_S, jVIGHR_S)*60;
	mvpall=sum (FMODHR_S, VIGHR_S)*60;
	keep id mvpa5 mvpa7 mvpa9 mvpa11;
run;

proc sort data=pa_calcu;
	by id;
run;

proc transpose data=pa_calcu out=pa_calcu_long name=varname;
	by id;
	var mvpa5 mvpa7 mvpa9 mvpall;
run;

data pa_calcu_long;
	set pa_calcu_long;
	wave=input (compress (varname, , 'kd'), 8.);
	mvpa_calcu=col1;
	keep id wave mvpa_calcu;
run;

proc sort data=pa_calcu_long;
	by wave id;
run;

proc sort data=aaic.combid;
	by wave id;
run;

data comb1d;
	merge aaic.combid (in a) pa_calcu_long;
	by wave id;
	keep id wave age sum_pa_all mvpa_calcu fruit_veg mind current_smk hv_drink cvd 
		depress mar_cohab bp chol obesity dm my_mm_scor cog1 my_animals my_SWORDS 
		my_MEM my_AH4 my MH cvd4 my_sbp my_blchol my_bmi my_gluc_f My_PART MY_PARTTYP;

	if a;
run;

proc sort data=aaic.apoe;
	by id;
run;

proc sort data=combid;
	by id;
run;

data comble;
	merge combid (in=a) aaic.base aaic.apoe;
	by id;

	if a;
run;

/*standarize test scores*/
proc sort data=comble;
	by wave;
run;

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

	/*defl: MMSE + OTHER*/
	if sum(of cog1, cog2, cog3, cog4, cog5, cog6) >=1 then
		cog_imp=1;
	else if cogl=. and cog2=. and cog3=. and cog4=. and cog5=. and cog6=. then
		cog_imp=.;
	else
		cog_imp=0;

	/*DEF2: OTHER*/
	if sum (of cog2, cog3, cog4, cog5, cog6) >=1 then
		cog_imp_nommse=1;
	else if cog2=. and cog3=. and cog4=. and cog5=. and cog6=. then
		cog_imp_nommse=.;
	else
		cog_imp_nommse=0;
run;

proc freq data=comb_std1;
	table wave* (cog_imp cog_imp_nommse);
run;

proc means data=comb_std1;
	class wave;
	var cog1 my_mm_scor;
run;

/*Sensitivity analysis, change outcome to first def1: cog_imp*/
%let out=cog_imp_nommse;

/*check pattern of cog*/
data outcome;
	set comb_std1;
	keep id wave &out;
run;

proc sort data=outcome;
	by id;

proc transpose data=outcome out wide_out prefix=wave_;
	by id;
	id wave;
	var &out;
run;

data pattern;
	set wide_out;
	array tvars{*} wave_:;
	length pattern $10;
	pattern='';

	do i=1 to dim (tvars);

		if missing (tvars[i]) then
			pattern=cats (pattern, "M");

		/* else pattern cats (pattern, 'o'); */
		else if tvars[i]=1 then
			pattern=cats (pattern, '1');
		else if tvars[i]=0 then
			pattern=cats (pattern, '0');
	end;
run;

proc freq data=pattern;
	tables pattern/nocum;
run;

/*miss w5 but has w3, imput cog at w5 by at w3
n=359*/
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

	if wave=5 and &out=. then
		&out=w3_cog;
run;

proc freq data=comb_std3;
	table wave* &out;
run;

proc freq data=comb_std3;
	table My_PART MY_PARTTYP;
	where wave=5 and &out=w3_cog and w3_cog^=.;
run;

/*check*/
proc sql;
	select count (distinct id) as n from comb_std3 where &out=. and age^. and 
		wave=5;
quit;

proc sql;
	select count (distinct id) as n from comb_std3 where &out^=. and age=. and 
		wave=5;
quit;

proc freq data=comb_std3;
	table wave*my_parttyp;
	where age^=.;
run;

proc sql;
	create table select_id5 as select distinct id from comb_std3 
	where wave=5 and 45<=age<=64 and &out=0 and apoe4^. and edu^. and income^=.;
quit;

proc sql;
	create table select1 as select * from comb_std3 where id in (select 
		select_id5.id from select_id5);
quit;

proc sql;
	select distinct wave, my_parttyp, count (distinct id) from select1 group by 
		wave, my_parttyp;
quit;

/*cog_imp patterns*/
data outcome;
	set select1;
	keep id wave &out;
	where wave^=3;
run;

proc sort data=outcome;
	by id;

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

		if missing (tvars[i]) then
			pattern=cats (pattern, "M");
		else
			pattern cats (pattern, 'o');

		/* else if tvars[i]= 1 then pattern = cats (pattern, '1');  */
		/* else if tvars[i]= 0 then pattern = cats (pattern, '0'); */
	end;
run;

proc freq data=pattern order=freq;
	tables pattern;
run;

/*not impute cog_imp, keep until the first missing*/
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
	where id in (select pattern.id from pattern where pattern in ('oMooo', 'oMMMM', 'OMMoo', 'oMooM', 'oMMMo', 'oMoMM')) and wave in (5);
QUIT;

data covars;
	set m_1 m_2 m_3 m_4;
run;

/*outcome*/
proc sql;
	create table yl as select id, wave, &out from select1 
	where id in (select pattern.id from pattern where pattern in ('ooooo' 'ooooM')) and wave in (7,	9, 11, 12);
QUIT;

proc sql;
	create table y2 as select id, wave, &out from select1 
	where id in (select pattern.id from pattern where pattern in ('oooMM' 'oooMo')) and wave in (7, 
		9, 11);
QUIT;

proc sql;
	create table y3 as select id, wave, &out from select1 
	where id in (select pattern.id from pattern where pattern in ('ooMMM' 'ooMMo' 'ooMoM' 'ooMoo')) 
		and wave in (7, 9);
QUIT;

proc sql;
	create table v4 as select id, wave, &out from select1 
	where id in (select pattern.id from pattern where pattern in ('oMooo', 'oMMMM', 'oMMoo', 'oMooM', 
		'oMMMo', 'oMoMM')) and wave in (7);
QUIT;

data ys;
	set y1 y2 y3 y4;

	if wave=7 then
		wave=5;
	else if wave=9 then
		wave=7;
	else if wave=11 then
		wave=9;
	else if wave=12 then
		wave=11;
run;

proc sort data=covars;
	by id wave;

proc sort data=ys;
	by id wave;

data merg1;
	merge covars ys;
	by id wave;
run;

/*check for missing */
proc means data=merg1 n nmiss;
run;

/*impute the missing using the avali down and up*/
/*impute missing covaraites*/
proc export data=merg1 outfile='P:\yzhang\Whitehall II\AAIC\merg1.csv' dbms=csv 
		replace;
run;

proc export data=select1 outfile='P:\yzhang\Whitehall II\AAIC\select1.csv' 
		dbms=csv replace;
run;

proc import datafile="P:\yzhang\Whitehall II\AAIC\mydat_fill_comp.csv" 
		out-mydat_fill_comp dbms=csv replace;
run;

/*keep all records up to and inlcuding the 1st cog impair*/
proc sort data=mydat_fill_comp;
	by id wave;
run;

data mydat_keep;
	set mydat_fill_comp;
	by id;
	retain found;

	if first.id then
		found=0;

	if found=0 then
		do;
			output;

			if &out=1 then
				found=1;
		end;
run;

proc sql;
	select count (distinct id) as n from mydat_keep;
quit;

proc means data=mydat_keep n nmiss;
	class wave;
run;

proc sql;
	select distinct wave, my_parttyp, count (distinct id) from mydat_keep group by 
		wave, my_parttyp;
quit;

proc sql;
	select count (distinct id) from mydat_keep group by wave;
quit;

data mydat_keep1;
	set mydat_keep;

	if my_SBP>=140 then
		bp=1;
	else if 0<=my_SBP<140 then
		bp=0;

	if my BLCHOL>-6.2 then
		chol=1;
	else if 0<=my_BLCHOL<6.2 then
		chol=0;

	if my_GLUC_F>=7 then
		dm_g='c_diabetes';
	else if 5.6<=my_GLUC_F<7 then
		dm_g='b_pre_dm';
	else if 0<=my_GLUC_F<5.6 then
		dm_g='a_normal';

	if 75<=mvpa_calcu<150 then
		mvpa_g="b_75_150";
	else if mvpa_calcu >=150 then
		mvpa_g="c_>=150";
	else if 0<=mvpa_calcu<75 then
		mvpa_g="a_<75";

	if my_bmi <18.5 then
		bmi_g=1;
	else if 18.5 <=my_bmi< 25 then
		bmi_g=2;
	else if 25 <=my_bmi <30 then
		bmi_g=3;
	else if 30 <=my_bmi then
		bmi_g=4;
		
	sum_pa_all_recode=max(mvpa_calcu, sum_pa_all);

	if 75<=sum_pa_all_recode<150 then
		pa_all_g="b_75_150";
	else if sum_pa_all_recode >=150 then
		pa_all_g="c_>=150";
	else if 0<=sum_pa_all_recode<75 then
		pa_all_g="a_<75";

	if mind> 8.5 then
		mind_60=1;
	else
		mind 60=0;
run;

/*check for missing */
proc means data=mydat_keep1 n nmiss;
run;

%select_var(mydat_keep1, aaic.mydat);

proc export data=aaic.mydat 
		outfile='P:\yzhang\Whitehall II\AAIC\aaic_mydat.csv' dbms=csv replace;
run;

/*descriptive statistics at w5*/
proc means data=mydat_keep1 n mean std maxdec-1 min max;
	var age edu my_sbp my_blchol my_gluc_f my_bmi mind mvpa_calcu 
		sum_pa_all_recode;
	where wave=5;
run;

proc freq data=mydat_keep1;
	table male mar_cohab income apoe4 cvd depress bp chol dm_g bmi_g current_smk 
		hv_drink mind_60 mvpa_g pa_all_g;
	where wave=5;
run;

proc sql;
	select distinct pattern, count (distinct id) from pattern where id in (select 
		mydat_keep1.id from mydat_keep1) group by pattern;
quit;