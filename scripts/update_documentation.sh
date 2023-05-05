#
# Script to generate an initial documentation file for an input script
#

#Input script name 
for script in `ls ../scripts/ ../config/`
do 

	script=${1##*/}
	#Script extension
	ext=${script##*.}
	#Documentation name 
	docu=${script//.${ext}/.man.sh}

  if [ ! -f ../man/${docu} ]
  then 
    continue
  else 
    cp ../man/${docu} ${docu}
  fi 
	
	#Construct the list of variables present in this script {{{
	variables=`cat $1 | grep -v "^#" | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
	  awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `
	#If there is a python script, add the variables from that too
	if [ -f ${script/.${ext}/.py} ]
	then 
	  variables="${variables} `cat ${script/.${ext}/.py} | grep -v "^#" | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
	  awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `"
	fi 
	#If there is a cosmosis .ini file, add the variables from that too 
	inifile=${script/.${ext}/.ini}
	inifile=../config/${inifile}
	echo ${inifile}
	if [ -f ${inifile} ]
	then 
	  variables="${variables} `cat ${inifile} | grep -v "^#" | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
	  awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `"
	fi 
	#If there is an R script, add the variables from that too
	if [ -f ${script/.${ext}/.R} ]
	then 
	  variables="${variables} `cat ${script/.${ext}/.R} | grep -v "^#" | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
	  awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep -v "DB:" | xargs echo `"
	fi 
	variables=`echo ${variables} | tr " " "\n" | sort | uniq | xargs echo`
	#}}}
	
  #Update the variables entry {{{
  grep -B 10000 "function _inp_var" ${docu} | head -n -2 > tmp.man.sh
	cat >> tmp.man.sh <<- EOF 
	function _inp_var { 
	  #Variable inputs (leave blank if none)
	  echo $variables
	} 
	EOF
  grep -A 10000 "function _inp_var" ${docu} | tail -n +4 >> tmp.man.sh
  mv tmp.man.sh ${docu}
  #}}}
	
	#Construct the list of DB variables present in this script {{{
	variables=`cat $1 | grep "@" | sed 's/\(@.*@\)/\n\1\n/g' | grep "@" | \
	  awk -F@ '{s="";for (i=2;i<=NF;i+=2) {s=s? s "\n" $i:$i} print s }' | grep -v "^$" | sort | uniq | grep "DB:" | sed 's/DB://g' | xargs echo `
	variables=`echo ${variables} | tr " " "\n" | sort | uniq | xargs echo`
	#}}}
	
  #Update the variables entry {{{
  grep -B 10000 "function _inp_data" ${docu} | head -n -2 > tmp.man.sh
	cat >> tmp.man.sh <<- EOF 
	function _inp_data { 
	  #Data inputs (leave blank if none)
	  echo $variables
	} 
	EOF
  grep -A 10000 "function _inp_data" ${docu} | tail -n +4 >> tmp.man.sh
  mv tmp.man.sh ${docu}
  #}}}

  #mv $docu ../man/
  break
done
	

