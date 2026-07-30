/*A few macros*/
%macro import_spss;
	proc import datafile="&path\&file" out=%scan(&file, 1, .) 
			/* Dataset name from the filename without .sav */
			dbms=sav replace;
	run;
%mend;

/*cognitive impairment*/
%macro cog_test(dat, var1, var2);
	proc sort data=&dat; by wave; run;

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

		if wave=3 then resid_std=resid/&rmsel.;
		if wave=5 then resid_std=resid/&rmse2.;
		if wave=7 then resid_std=resid/&rmse3.;
		if wave=9 then resid_std=resid/&rmse4.;
		if wave=11 then resid_std=resid/&rmse5.;
		if wave=12 then resid_std=resid/&rmse6.;
		
		if resid_std<-1.5 and resid_std^=. then &var2=1;
		if resid_std>=-1.5 then &var2=0;
	run;

	proc sort data=&dat; by id wave;
	proc sort data=residual_dat; by id wave;

	data &dat;
		merge &dat (in=a) residual_dat;
		by id wave;

		if a;
		drop resid resid_std;
	run;

%mend;

/*wave 12: no my_mh*/
%macro cog_testi(dat, varl, var2);
	proc sort data=&dat; by wave; run;

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
		if wave=3 then resid_std=resid/&rmsel.;
		if wave=5 then resid_std=resid/&rmse2.;
		if wave=7 then resid_std=resid/&rmse3.;
		if wave=9 then resid_std=resid/&rmse4.;
		if wave=11 then resid_std=resid/&rmse5.;
		
		if resid_std<-1.5 and resid_std^=. then &var2=1;
		if resid_std>=-1.5 then &var2=0;
	run;

	proc sort data=&dat; by id wave;

	proc sort data=residual_dat; by id wave;

	data &dat;
		merge &dat (in=a) residual_dat;
		by id wave;

		if a;
		drop resid resid_std;
	run;

%mend;

/* variable names differently at waves, rename*/
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

/* -------------------combine wave 5-12  -------------------*/
/*  -------------------out: comble  -------------------*/
/*new requested variables*/
proc import datafile='P:\yzhang\Whitehall II\AAIC\new_dat_noNA.csv' out=new_data dbms=csv replace; 	getnames=yes;
run;

proc import datafile='P: \yzhang\Whitehall II\Data\0281_DATASET_additional_July25_noNA.csv' out=add_july dbms-csv replace;
getnames=yes; guessingrows = max; run;

data add_july;
set add_july;
id=id_random_DPUK;
run;

/*w5*/
%let file = s5quest_0281_S.sav; %import_spss;
%let file = s5screen_0281_S.sav; %import_spss;

/*baseline: age, sex, ethnicity, education, income*/
data aaic.base;
	set s5quest_0281_S;
	id=input (id_random_DPUK, best32.);

	/*sex*/
	if sex=1 then male=1;
	if sex=2 then male=0;

	/*ethnicity*/
	if ETHN_DS=1 then white=1;
	else if ETHN_DS=2 then white=0;
	edu=TEDTOTYR;
	income=TINCHH4;
	keep id white male edu income;
run;

/*APOE*/
%let file = PA_APOE_ver3update_S.sav; %import_spss;
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
DATA QUEST5; set s5quest_0281_S (rename=(&quest_rename));
	id=input(id_random_DPUK, best32.);
	keep id &quest_new;
run;

DATA screen5; set s5screen_0281_S (rename=(&screen_rename));
	id=input(id_random_DPUK, best32.);
	keep id &screen_new;
run;

data empty; input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data; by id_random_DPUK; run;
data tmp1; merge empty new_data; by id_random_DPUK; run;
data add5; set tmp1 (rename=(&add_rename)); id=input (id_random_DPUK, best32.); keep id &add_new; run;

proc sort data=quest5; by id;
proc sort data=screen5; by id;
proc sort data=add5; by id;
run;
data w5; merge quest5 screen5 add5; by id; 	wave=5; run;

/*w7*/
%let file = 87quest_0281_S.sav; %import_spss;
%let file = 87screen_0281_S.sav; %import_spss;

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

DATA QUEST7; set s7quest_0281_S (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	keep id &quest_new;
run;

DATA screen7; set s7screen_0281_S (rename=(&screen_rename));
	id=input (id_random_DPUK, best32.);
	keep id &screen_new;
run;

data empty; input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data; by id_random_DPUK; run;

data tmp1; merge empty new_data;
	by id_random_DPUK;
run;

data add7;
	set tmp1 (rename=(&add_rename));
	id=input (id_random_DPUK, best32.);
	keep id &add_new;
run;

proc sort data=quest7; by id;
proc sort data=screen7; by id;
proc sort data=add7; by id;
run;

data w7;
	merge quest7 screen7 add7;
	by id;
	wave=7;
run;

/*w9*/
%let file = s9quest_0281_S.sav; %import_spss;
%let file = s9screen_0281_S.sav; %import_spss;

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

DATA QUEST9; set s9quest_0281_S (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	keep id &quest_new;
run;

DATA screen9; set 39screen_0281_S (rename=(&screen_rename));
	id=input (id_random_DPUK, best32.);
	keep id &screen_new;
run;

data empty; input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data; by id_random_DPUK; run;

data tmp1; merge empty new_data; by id_random_DPUK; run;

data add9; set tmp1 (rename=(&add_rename));
	id=input (id_random_DPUK, best32.);
	keep id &add_new;
run;

data w9; merge quest9 screen9 add9;
	by id;
	wave=9;
run;

/*w11*/
%let file = s11quest_0281_S.sav; %import_spss;
%let file = s11screen_0281_S.sav; %import_spss;

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

DATA QUEST11; set s1lquest_0281_S (rename=(&quest_rename));
	id=input (id_random_DPUK, best32.);
	keep id &quest_new;
run;

DATA screen11; set sllscreen_0281_S (rename=(&screen_rename));
	id=input (id_random_DPUK, best32.);
	keep id &screen_new;
run;

data empty; input id_random_DPUK &retain_name;
	cards;
;
run;

proc sort data=new_data; by id_random_DPUK; run;

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
%let file = s12quest_0281_S.sav; %import_spss;
%let file = s12screen_0281_S.sav; %import_spss;

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

proc sort data=new_data; by id_random_DPUK; run;

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
%let file = s3quest_0281_S.sav; %import_spss;
%let file = s3screen_0281_5.sav; %import_spss;

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

proc sort data=new_data; by id_random_DPUK; run;

data tmp1;
	merge empty new_data;
	by id_random_DPUK;
run;

data add3;
	set tmp1 (rename=(&add_rename));
	id=input (id_random_DPUK, best32.);
	keep id &add_new;
run;

data w3;
	merge quest3 screen3 add3;
	by id;
	wave=3;
run;

data comb; set w3 w5 w7 w9 w11 w12; run;
