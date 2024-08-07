
library(argparser)

parser = arg_parser(
    description="Assign label from training catalogue to target catalogue using nearest-neighbour match in feature space."
)
parser<-add_argument(parser,
    short="-i", "--input", 
    help="path to the target file",
)
parser<-add_argument(parser,
    short="-o", "--output",
    help="path to the output with added label",
)
parser<-add_argument(parser,
    short="-t", "--train", 
    help="path to the training data containing the desired label",
)
parser<-add_argument(parser,
    "--features",short="-f", nargs="+",
    help="column names of features to match, must be present in input and training data",
)
parser<-add_argument(parser,
    "--label",short="-l", 
    help="column name of the label to match",
)
parser<-add_argument(parser,
    "--radius",short="-r",default=1, 
    help="radius of the match in arcsec",
)
parser<-add_argument(parser,
    "--sparse", default=1, 
    help="sparse-sample the training data by taking every n-th data point"
)
parser<-add_argument(parser,
    "--extname", default='OBJECTS', 
    help="open catalogue using this extension name"
)

#Get the arguments 
args<-parse_args(parser)
#Split features by space and comma 
args$features=helpRfuncs::vecsplit(args$features,",")
args$features=helpRfuncs::vecsplit(args$features," ")


cat("reading input data\n")
train_data = helpRfuncs::read.file(args$train, cols=c(args$features, args$label))
if (args$sparse>1) { 
  train_data = train_data[sample(nrow(train_data),size=nrow(train_data)/args$sparse),]
}
test_data = helpRfuncs::read.file(args$input,cols=c(args$features))

cat("running matching\n")

#Get typical comparison sample radial separations 
match<-list(ID=matrix(0,nrow=2,ncol=0))
rad=args$radius
cat(paste0("Using initial matching radius of  ",rad," arcsec\n"))
match = celestial::coordmatch(coordref=data.frame(train_data[[args$features[1]]],train_data[[args$features[2]]]),
                              coordcompar=data.frame(train_data[[args$features[1]]],train_data[[args$features[2]]]),
                              rad=rad,ignoreexact=TRUE)

if(ncol(match$ID)==0 || nrow(match$bestmatch)/nrow(match$ID) < 0.5) { 
  cat(paste0("estimating appropriate matching radius from training data:\n"))
  cat(paste0(rad," arcsec "))
  while(ncol(match$ID)==0 || nrow(match$bestmatch)/nrow(match$ID) < 0.5) { 
    rad=rad*5
    cat(paste0("- failed\n", rad," arcsec "))
    match = celestial::coordmatch(coordref=data.frame(train_data[[args$features[1]]],train_data[[args$features[2]]]),
                                  coordcompar=data.frame(train_data[[args$features[1]]],train_data[[args$features[2]]]),
                                  rad=rad,ignoreexact=TRUE)
  }
  cat(paste0("- success!\n"))
  rad = ceiling(quantile(match$bestmatch$sep,probs=pnorm(3)-pnorm(-3)))
  if (rad>=50 & rad < 3600) rad<-ceiling(rad/60)*60
  if (rad>3600) rad<-ceiling(rad/3600)*3600
  print(str(match))
  cat(paste0("Using final matching radius of  ",rad," arcsec\n"))
}

idx = celestial::coordmatch(coordref=data.frame(test_data[[args$features[1]]],test_data[[args$features[2]]]), 
                            coordcompar=data.frame(train_data[[args$features[1]]],train_data[[args$features[2]]]),
                            rad=rad)$ID[,1]

if (length(idx) != nrow(test_data)) { 
  stop("Output match IDs not of same length as queried locations?!") 
}

cat(paste0("There are ",length(which(idx!=0))," matches out of ",nrow(test_data),"(",round(digits=2,100*length(which(idx!=0))/nrow(test_data)),"%)\n"))

prediction = train_data[[args$label]][idx]

if (length(prediction)!=nrow(test_data)) { 
  warning("There are un-matched sources! These will be assigned a value of -999!") 
  test_data[[args$label]] <- -999 
  test_data[[args$label]][which(idx!=0)] <- prediction
} else { 
  test_data[[args$label]] = prediction
}


cat("writing output data\n")
helpRfuncs::write.file(test_data,file=args$output)

