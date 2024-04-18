#=========================================
#
# File Name : spatial_split.R
# Created By : awright
# Creation Date : 10-07-2023
# Last Modified : Wed 20 Mar 2024 08:50:32 PM CET
#
#=========================================

#Split a catalogue into N spatial regions, with 
#optimal size/separation given an input aspect ratio

#Read input parameters 
inputs<-commandArgs(TRUE) 

#Interpret the command line options {{{
sphere<-FALSE
badval<- -999
x.break<-0
while (length(inputs)!=0) {
  #Check for valid specification {{{
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }  
  if (!grepl('^-',inputs[1])) {
    print(inputs)
    stop(paste("Incorrect options provided!"))
  }
  #/*fend*/}}}
  if (inputs[1]=='-i') { 
    #Read the input catalogue /*fold*/ {{{
    inputs<-inputs[-1]
    input.cat<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-o') { 
    #Read the output catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    if (any(grepl('^-',inputs))) { 
      output.cats<-inputs[1:(which(grepl('^-',inputs))[1]-1)]
      inputs<-inputs[-(1:(which(grepl('^-',inputs))[1]-1))]
    } else { 
      output.cats<-inputs
      inputs<-NULL
    } 
    #/*fold*/}}}
  } else if (inputs[1]=='-n') { 
    #Read the number of splits /*fold*/ {{{
    inputs<-inputs[-1]
    nsplit<-as.integer(inputs[1])
    if (!is.finite(nsplit)) { 
      stop(paste("Provided number of splits is not a finite integer:",inputs[1]))
    }
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-k') { 
    #Read the number of splits /*fold*/ {{{
    inputs<-inputs[-1]
    nsplitkeep<-as.integer(inputs[1])
    if (!is.finite(nsplitkeep)) { 
      stop(paste("Provided number of splits-to-keep is not a finite integer:",inputs[1]))
    } else if (nsplitkeep==0) { 
      stop(paste("Provided number of splits-to-keep is zero?!"))
    }
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-a') { 
    #Read the target aspect-ratio /*fold*/ {{{
    inputs<-inputs[-1]
    asp<-as.numeric(inputs[1])
    if (!is.finite(asp)) { 
      stop(paste("Provided target aspect-ratio is not finite:",inputs[1]))
    }
    if (asp<0) { 
      stop(paste("Provided target aspect-ratio is negative:",inputs[1]))
    }
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='-v') { 
    #Read the spatial column names /*fold*/ {{{
    inputs<-inputs[-1]
    x.name<-inputs[1]
    y.name<-inputs[2]
    inputs<-inputs[-2:-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--x.break') { 
    #Read the spatial column names /*fold*/ {{{
    inputs<-inputs[-1]
    x.break<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--sphere') { 
    #Read the spatial column names /*fold*/ {{{
    inputs<-inputs[-1]
    sphere<-TRUE
    #/*fold*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}

if (!exists("nsplitkeep")) { 
  nsplitkeep<-nsplit
}

#Read the input catalogue {{{
cat<-helpRfuncs::read.file(input.cat,nrow=100)
#}}}

#Check that the x.name and y.name varaibles are in the catalogue 
if ((!x.name %in% colnames(cat)) & (!y.name %in% colnames(cat))) {  
  stop(paste("Neither",x.name,"nor",y.name,"variables are in the provided catalogue!")) 
} else if (!x.name %in% colnames(cat)) {  
  stop(paste(x.name,"variable is not in provided catalogue!")) 
} else if (!y.name %in% colnames(cat)) {  
  stop(paste(y.name,"variable is not in provided catalogue!")) 
}

#Read the input catalogue {{{
cat<-helpRfuncs::read.file(input.cat,cols=c(x.name,y.name))
#}}}

if (x.break!=0) { 
  cat[[x.name]][which(cat[[x.name]]>x.break)]<-cat[[x.name]][which(cat[[x.name]]>x.break)]-360
}

#Set up the cut object (for faster splitting) {{{
tmp<-data.frame(x=cat[[x.name]],y=cat[[y.name]])
#}}}

#X range and Y range {{{
if (any(tmp$x==badval)) { 
  cat("WARNING: Catalogue has x-values which are bad!\n")
  x.range<-range(tmp$x[which(tmp$x!=badval)],na.rm=T)
} else { 
  x.range<-range(tmp$x,na.rm=T)
} 
if (any(tmp$y==badval)) { 
  cat("WARNING: Catalogue has y-values which are bad!\n")
  y.range<-range(tmp$y[which(tmp$y!=badval)],na.rm=T)
} else { 
  y.range<-range(tmp$y,na.rm=T)
} 
#}}}

cat(paste0("x.range: ",'[',x.range[1],',',x.range[2],']\n'))
cat(paste0("y.range: ",'[',y.range[1],',',y.range[2],']\n'))

#Do sphere correction? {{{
if (sphere) { 
  cat(paste("correcting for spherical projection\n"))
  tmp$x<-(tmp$x-median(tmp$x))*cos(tmp$y*pi/180)+median(tmp$x)
}
#}}}

#Define the aspect ratio of the input data {{{
data_asp=diff(range(tmp$y))/diff(range(tmp$x))
cat(paste("data aspect ratio:",data_asp,"\n"))
#}}}
#Define the initial nsplit using requested aspect ratio {{{
nsplit.x<-max(c(round(sqrt(nsplit/data_asp/asp)),1))
nsplit.y<-nsplit/nsplit.x
#}}}

cat(paste("starting nsplit.x:",nsplit.x,"\nstarting nsplit.y:",nsplit.y,"\n"))

count=0
while (nsplit.x%%1>0 | nsplit.y%%1>0) {
  #Check for infinite loop {{{
  if (count>1e6) {
    stop("Unable to construct an nsplit binning by adapting aspect ratio")
  }
  #}}}
  #Update the aspect ratio {{{
  if (asp>1) {
    asp=asp*1.05
  } else if (asp==1) {
    asp=1.05
  } else {
    asp=asp/1.05
  }
  #}}}
  #Update x splits {{{
  nsplit.x<-max(c(round(sqrt(nsplit/data_asp/asp)),1))
  #}}}
  #Construct y splits {{{
  nsplit.y<-nsplit/nsplit.x
  #}}}
  #Update count {{{
  count<-count+1
  #}}}
}

cat(paste("final nsplit.x:",nsplit.x,'\nfinal nsplit.y:',nsplit.y,'\n'))

#Create bins, and deal with particularly narrow input data {{{
if (nsplit.x==1 & nsplit.y>1) {
  cat('binning only in y!\n')
  edges<-seq(min(tmp$y),max(tmp$y),length=nsplit.y+1)
  bins<-data.frame(n=1:nsplit.y-1,x=mean(tmp$x),y=diff(edges)/2+edges[1:nsplit.y])
  #}}}
} else if (nsplit.y==1 & nsplit.x>1) {
  cat('binning only in x!\n')
  edges<-seq(min(tmp$x),max(tmp$x),length=nsplit.x+1)
  bins<-data.frame(n=1:nsplit.x-1,x=diff(edges)/2+edges[1:nsplit.x],y=mean(tmp$y))
  #}}}
} else if (nsplit.x==1 & nsplit.y==1) {
  #There is only one bin?! {{{
  cat('Only one bin!\n')
  bins<-data.frame(n=0,x=mean(tmp$x),y=mean(tmp$y))
  #}}}
} else {
  #Bin in x & y {{{
  cat('binning in x & y\n')
  x.edges<-seq(min(tmp$x),max(tmp$x),length=nsplit.x+1)
  x.bins<-diff(x.edges)/2+x.edges[1:nsplit.x]
  y.edges<-seq(min(tmp$y),max(tmp$y),length=nsplit.y+1)
  y.bins<-diff(y.edges)/2+y.edges[1:nsplit.y]
  expand<-expand.grid(x.bins,y.bins)
  bins<-data.frame(n=1:(nsplit.x*nsplit.y)-1,
                   x=expand[,1],y=expand[,2])
  #}}}
}
#}}}

if (x.break!=0) { 
  bins$x[which(bins$x<0)]<-bins$x[which(bins$x<0)]+360 
}

#Write the bin centers to file 
helpRfuncs::write.file(file=output.cats,bins)
#}}}

#Finish

