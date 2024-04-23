#
#
# Script to construct adapt magnitude catalogue from standard KiDS specz cat
# i.e. just replace the MAG_GAAP_X columns with MAGadapt_GAAP_X
#

inputs<-commandArgs(T)
#Read in the specz catalogue 
cat(paste0("Reading ",inputs[1]))
cat<-helpRfuncs::read.file(inputs[1],data.table=F)
cat(paste0(" - Done\n"))
#Select the "MAGadapt_GAAP" columns 
cols<-colnames(cat)[which(grepl('adapt',colnames(cat)))]
#Loop through and replace the MAG_GAAP columns with these
for (col in cols) { 
  cat(paste0(col,'->',gsub('adapt','',col),'\n'))
  tmp.col<-cat[[col]]
  tmp.err<-cat[[gsub('MAG_','MAGERR_',col)]]
  tmp.col[which(tmp.err>2.5/log(10))]<- +99
  cat[[gsub('adapt','',col)]]<-tmp.col
}
#Define the output filename 
if (length(inputs)>1) { 
  outfile<-inputs[2]
} else { 
  outend<-helpRfuncs::vecsplit(inputs[1],'.',-1)
  outfile<-sub(paste0(".",outend),paste0("_adapt.",outend),inputs[1])
  if (outfile==inputs[1]) { 
    stop(paste("unable to create a distinct outfile because infile has no extension",
                                 "and output directory is the same as input?!"))
  } 
}
if (outfile==inputs[1]) { 
  warning(paste("Input and Output file are the same!"))
} 
#Output the catalogue 
cat(paste0("Writing ",outfile))
helpRfuncs::write.file(file=outfile,cat)
cat(paste0(" - Done\n"))


