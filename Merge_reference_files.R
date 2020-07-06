#saving original path to use later
ORIG_output_path <- getwd()

#read in all of the file names in refs folder
Reference_df <- as.data.frame(list.files(path = 'refs'))

#edit column name
colnames(Reference_df) <- c("biosample_num")
#add a column for the SRA number 
Reference_df$`SRAnum` <- ""
#add a column to identify biosample numbers with more than one SRA number 
Reference_df$`extraSRAnum` <- ""

#set the working directory
setwd('refs')

#loop through list of reference files (biosamples)
for(i in 1:nrow(Reference_df)) {
  #have to avoid errors because some files don't have SRA numbers and you can't read in an empty file
  tryCatch({
    #read in file based on biosample number 
    file1 <- read.table(as.character(Reference_df$biosample_num[i]))
    #read in that biosample's sra number (contents of the file)
    Reference_df$`SRAnum`[i] <- paste(as.character(file1[1,1]))
    #mark the biosample number if there is more than one SRA number in the file
    if(nrow(file1) > 1){
      Reference_df$`extraSRAnum`[i] <- "*"
    }
  }, error=function(e){})
}

#make list of all with more than 1 SRA
Multiples <- Reference_df[which(Reference_df$extraSRAnum == "*"),-(3)]

#make and merge dataframes of the multiples
Full_multiples <- data.frame(SRAnum=character(0), biosample_num=character(0))
#loop through all biosample numbers with multiple SRA numbers
for(i in as.numeric(rownames(Multiples))){
  #download file for that biosample number
  file1 <- read.table(file = (as.character(Reference_df$biosample_num[i])), header = FALSE, fill = TRUE)
  #if not 1xn matrix, make into one
  if(ncol(file1) > 1){
    col1 <- as.data.frame(as.vector(file1$V1))
    col2 <- as.data.frame(as.vector(file1$V2))
    colnames(col1) <- c("")
    colnames(col2) <- c("")
    file1 <- rbind(col1, col2)
  }
  #make matching headings
  colnames(file1) <- c("SRAnum")
  #make biosample number not unique among all of the same,
  #apply it to all SRA numbers
  file1$biosample_num <- Reference_df$biosample_num[i]
  #merge this df to Full_multiples
  Full_multiples <- rbind(Full_multiples, file1)
}
#remove holes from full multiples which were generated due to formatting issues
#of tables with more than one column of SRA numbers
Full_multiples <- Full_multiples[which(Full_multiples$SRAnum != ""),]

#merge to dataframe of all without more than one SRA
Singles <- Reference_df[which(Reference_df$extraSRAnum != "*"),-(3)]
#swap rows to match Full_multiples format for merging
Singles <- Singles[,c("SRAnum", "biosample_num")]
#merge
SRA_Biosample_Ref_File <- rbind(Singles, Full_multiples)
#remove .txt in biosample number
SRA_Biosample_Ref_File$biosample_num <- gsub('.txt','',SRA_Biosample_Ref_File$biosample_num)
#write out file

#reset output directory to original to write outputs to a higher folder
setwd(ORIG_output_path)

#write SRA-Biosample Reference File
write.table(x = SRA_Biosample_Ref_File, 
            file = 'SRA_Biosample_Ref_File.txt', 
            row.names = FALSE, 
            quote = FALSE)

#change reference file to make into the SRA id file
SRAs <- SRA_Biosample_Ref_File[which(SRA_Biosample_Ref_File$SRAnum != ""),]
SRAs <- as.data.frame(SRAs[,-(2)])
colnames(SRAs) <- c("SRAs")

#write SRA id file 
write.table(x = SRAs, 
            file = 'SRA_ids.txt',
            row.names = FALSE, 
            col.names = FALSE,
            quote = FALSE)
