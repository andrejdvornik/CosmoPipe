#=========================================
#
# File Name : reformat_column.sh 
# Created By : awright
# Creation Date : 24-05-2024
# Last Modified : Fri 24 May 2024 09:52:18 AM CEST
#
#=========================================

input="@DB:DATAHEAD@"
ext=${input##*.}
outfile=${input//.${ext}/_rfmt.${ext}}

#Get the format variables 
COLUMNNAME=`echo @BV:NEWCOLUMN@ | awk '{print $1}'` 
COLUMNCOMM=`echo @BV:NEWCOLUMN@ | awk '{print $2}'` 
COLUMNUNIT=`echo @BV:NEWCOLUMN@ | awk '{print $3}'` 

#Merge the goldweight column {{{
_message "   -> @BLU@Merging goldweight column @DEF@"
#Check if input file lengths are ok {{{
links="FALSE"
for file in ${input} ${outfile}
do 
  if [ ${#file} -gt 250 ] 
  then 
    links="TRUE"
  fi 
done 

if [ "${links}" == "TRUE" ] 
then
  #Remove existing infile links 
  if [ -e infile_$$.lnk ] || [ -h infile_$$.lnk ]
  then 
    rm infile_$$.lnk
  fi 
  #Remove existing outfile links 
  if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
  then 
    rm outfile_$$.lnk
  fi
  #Create input link
  originp=${input}
  ln -s ${input}_tmp infile_$$.lnk_tmp
  input="infile_$$.lnk"
  #Create outfile links 
  ln -s ${outfile} outfile_$$.lnk
  origout=${outfile}
  outfile=outfile_$$.lnk
fi 
#}}}
#Strip out the old column 
_message " @BLU@> Pull out column to update @DEF@"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactoasc \
  -i ${input} \
  -o ${outfile}_tmp \
  -k ${COLUMNNAME} -t OBJECTS 2>&1
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
_message " @BLU@> Delete column to update from original catalogue @DEF@"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey \
  -i ${input} \
  -o ${input}_tmp \
  -k ${COLUMNNAME} -t OBJECTS 2>&1
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#Get the format variables 
TTYPE=`echo @BV:NEWFORMAT@ | awk '{print $1}'` 
DEPTH=`echo @BV:NEWFORMAT@ | awk '{print $2}'` 
if [ ${TTYPE^^} == "DOUBLE" ] || [ ${TTYPE^^} == "FLOAT" ] 
then 
  HTYPE="FLOAT"
elif [ ${TTYPE^^} == "STRING" ] 
then 
  HTYPE="STRING"
else 
  HTYPE="INT"
fi 
#Set up new ldac catalogue with correct format 
echo > ${outfile}.columns <<- EOF
COL_NAME = ${COLUMNNAME}
COL_TTYPE = $TTYPE
COL_HTYPE = $HTYPE
COL_COMM = "${COLUMNCOMM}"
COL_UNIT = "${COLUMNUNIT}"
COL_DEPTH = ${DEPTH}
#
EOF
_message " @BLU@> Create proto-catalgoue with column in new format @DEF@"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/asctoldac \
  -i ${outfile}_tmp \
  -o ${outfile}_proto \
  -c ${outfile}.columns 2>&1
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
_message " @BLU@> Merge new column with original catalogue @DEF@"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i ${input}_tmp \
  -p ${outfile}_proto \
  -o ${outfile} \
  -k @BV:COLUMNNAME@ -t OBJECTS 2>&1
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#Undo linking {{{
rm ${input}_tmp ${outfile}_tmp ${outfile}_proto
if [ "${links}" == "TRUE" ] 
then 
  #Remove old links {{{
  mv ${outfile} ${origout} 
  input=${originp}
  outfile=${origout}
  #}}}
fi 
#}}}
#Delete the temporary input file 
rm -f ${input}_tmp 
#}}}
#Rename the original weight column {{{
_message "   -> @BLU@Changing original @BV:WEIGHTNAME@ column to @BV:WEIGHTNAME@_nogoldwt@DEF@"
#Check if input file lengths are ok {{{
links="FALSE"
for file in ${outfile}
do 
  if [ ${#file} -gt 250 ] 
  then 
    links="TRUE"
  fi 
done 
if [ "${links}" == "TRUE" ] 
then
  #Remove existing outfile links 
  if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
  then 
    rm outfile_$$.lnk
  fi
  #Create outfile links 
  ln -s ${outfile}_tmp outfile_$$.lnk_tmp
  origout=${outfile}
  outfile=outfile_$$.lnk
fi 
#}}}
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacrenkey \
  -i ${outfile}_tmp \
  -o ${outfile} \
  -k @BV:WEIGHTNAME@ @BV:WEIGHTNAME@_nogoldwt 2>&1
#Undo linking {{{
if [ "${links}" == "TRUE" ] 
then 
  #Remove old links {{{
  rm ${outfile}_tmp
  mv ${outfile} ${origout} 
  outfile=${origout}
  #}}}
fi 
#}}}
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#remove the temporary output file 
rm ${outfile}_tmp 
#}}}
#Incorporate the goldweight column into the shape weight {{{
_message "   -> @BLU@Incorporating goldweight into @BV:WEIGHTNAME@ column@DEF@"
#Check if input file lengths are ok {{{
links="FALSE"
for file in ${outfile}
do 
  if [ ${#file} -gt 250 ] 
  then 
    links="TRUE"
  fi 
done 
if [ "${links}" == "TRUE" ] 
then
  #Remove existing outfile links 
  if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
  then 
    rm outfile_$$.lnk
  fi
  #Create outfile links 
  ln -s ${outfile} outfile_$$.lnk
  origout=${outfile}
  outfile=outfile_$$.lnk
fi 
#}}}
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldaccalc \
  -i ${outfile} \
  -o ${outfile}_tmp \
  -t OBJECTS \
  -c "SOMGoldWeight*@BV:WEIGHTNAME@_nogoldwt;" -n "@BV:WEIGHTNAME@" "Shape measurement weight including gold weight" -k FLOAT 2>&1
#Undo linking {{{
if [ "${links}" == "TRUE" ] 
then 
  #Remove old links {{{
  rm ${outfile}
  mv ${outfile}_tmp ${origout}_tmp
  outfile=${origout}
  #}}}
fi 
#}}}
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}
#Convert the SOMGoldWeight into a binary Goldclass {{{
_message "   -> @BLU@Constructing binary goldclass@DEF@"
#Check if input file lengths are ok {{{
links="FALSE"
for file in ${outfile}
do 
  if [ ${#file} -gt 250 ] 
  then 
    links="TRUE"
  fi 
done 
if [ "${links}" == "TRUE" ] 
then
  #Remove existing outfile links 
  if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
  then 
    rm outfile_$$.lnk
  fi
  #Create outfile links 
  ln -s ${outfile}_tmp outfile_$$.lnk_tmp
  origout=${outfile}
  outfile=outfile_$$.lnk
fi 
#}}}
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldaccalc \
  -i ${outfile}_tmp \
  -o ${outfile}     \
  -t OBJECTS \
  -c "1-SOMGoldWeight/(SOMGoldWeight+0.000000000000001);" -n "SOMnonGold" "Inverse selection of Binary GoldWeight" -k SHORT 2>&1
#Undo linking {{{
if [ "${links}" == "TRUE" ] 
then 
  #Remove old links {{{
  rm ${outfile}_tmp
  mv ${outfile} ${origout}
  outfile=${origout}
  #}}}
fi 
#}}}
#Check if input file lengths are ok {{{
links="FALSE"
for file in ${outfile}
do 
  if [ ${#file} -gt 250 ] 
  then 
    links="TRUE"
  fi 
done 
if [ "${links}" == "TRUE" ] 
then
  #Remove existing outfile links 
  if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
  then 
    rm outfile_$$.lnk
  fi
  #Create outfile links 
  ln -s ${outfile} outfile_$$.lnk
  origout=${outfile}
  outfile=outfile_$$.lnk
fi 
#}}}
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldaccalc \
  -i ${outfile} \
  -o ${outfile}_tmp     \
  -t OBJECTS \
  -c "1-SOMnonGold;" -n "SOMweight" "Binary GoldWeight (for use with gold-weighted @BV:WEIGHTNAME@)" -k SHORT 2>&1
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
#Undo linking {{{
if [ "${links}" == "TRUE" ] 
then 
  #Remove old links {{{
  rm ${outfile}
  mv ${outfile}_tmp ${origout}_tmp
  outfile=${origout}
  #}}}
fi 
#}}}
#Delete the temporary output file
mv ${outfile}_tmp ${outfile}
#}}}
#Save the output file to the list {{{
outlist="$outlist $outname"
#}}}
#Notify {{{
_message " }\n"
#}}}

#Add the new file to the datablock {{{
if [ "${outlist}" != "" ]
then 
  _write_datablock som_weight_refr_gold "`echo ${outlist}`"
fi 
#}}}

#}}}

