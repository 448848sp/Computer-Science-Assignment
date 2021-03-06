library("rjson")
library("data.table")
library("rlist")
library("tidyverse")
library("stringr")
library("base")
library("dplyr")
library("primes")
library("ClustMMDD")
library("stringdist")
library("arules")
library("lsa")
library("stats")
library("cluster")
library("factoextra")
library("MLmetrics")

#importing data from JSON file
mydata <- fromJSON(file="C:/Users/sophi/OneDrive/Afbeeldingen/Documenten/Computer Science/Assignment Computer Science/TVs-all-merged.json")
mydata
new_list= list()
for (i in mydata){
    new_list = c(new_list,i)
}

dfs <-lapply(new_list, data.frame, stringsAsFactors = FALSE)
data.df <- rbindlist(dfs, fill=TRUE)
summary(data.df)

#Data cleaning in title variable
data.df$title <- as.character(data.df$title)
data.df$title <- tolower(data.df$title)
data.df$title <- str_replace_all(data.df$title, '-inch', 'inch')
data.df$title <- str_replace_all(data.df$title, '"', 'inch')
data.df$title <- str_replace_all(data.df$title, ' inch', 'inch')
data.df$title <- str_replace_all(data.df$title, 'inches', 'inch')
data.df$title <- str_replace_all(data.df$title, "'", 'inch')
data.df$title <- str_replace_all(data.df$title, 'hertz' , 'hz')
data.df$title <- str_replace_all(data.df$title, ' hz' , 'hz')
data.df$title <- str_replace_all(data.df$title, '-hz' , 'hz')

#using model words including decimals to compute binary vectors
modelwords <- str_extract_all(data.df$title, "([a-zA-Z0-9]+([.]*[0-9]+))+[:punct:]*[a-zA-Z0-9]*|[a-zA-Z0-9]+[:punct:]([a-zA-Z]*[0-9]+)+")
dataframes <- lapply(modelwords, data.frame, stringsAsFactors = TRUE)
modelwords_filter <- rbindlist(dataframes, fill=TRUE)

unique_modelwords<- unique(modelwords_filter)
unique_modelwords$X..i..<-as.character(unique_modelwords$X..i..)

data.df$ID <- seq.int(nrow(data.df))

binary_vectors <- as.data.frame(matrix(0, ncol = nrow(data.df), nrow = nrow(unique_modelwords)), col.names=data.df$ID, row.names= unique_modelwords$X..i..)

for (k in 1:nrow(data.df)){
  for (j in 1:nrow(unique_modelwords)){
    if(grepl(unique_modelwords$X..i..[j],data.df$title[k],fixed=TRUE)==TRUE){
      binary_vectors[j,k]= 1
    }
  }
}

#minhashing using h(x)(a+bx)mod(p)
p_values <- sample(generate_primes(min=0.5*nrow(binary_vectors), max= 10000), 1, replace=FALSE)

signature_matrix <- as.data.frame(matrix(999999, ncol = ncol(binary_vectors), nrow = 0.5*nrow(binary_vectors)), col.names= data.df$ID)
for (m in 1:nrow(signature_matrix)){
  a_values <- sample(0:100,1)
  b_values <- sample(1:100,1)
  hashfunction <- function(x){(a_values+(b_values*x))%%p_values}  
  for(l in 1:nrow(binary_vectors)){
    for (n in 1:ncol(binary_vectors)){
      minhash_value <- signature_matrix[m,n]
      if(binary_vectors[l,n]==1){
        minhash_value = hashfunction(l)
      }
      if(minhash_value<= signature_matrix[m,n]){
        signature_matrix[m,n]=minhash_value  
      } 
    }  
  }
}

unique_signature <- unique.data.frame(signature_matrix)




#threshold (1/b)^(1/r), goal : find documents with jaccard similarity of at least t
column_is<-c("PQ", "PC", "F1*-measure", "comp")
divisible_by <- c(1, 2, 5, 10, 13, 25, 26, 50, 65, 130, 325, 650)
bootstrapping_results<-as.data.frame(matrix(0, ncol = 4, nrow = 12), row.names=divisible_by, col.names=column_is)
colnames(bootstrapping_results)<-column_is




#rows of bootstrapping_results are how many bands
#change r & b and rows in the matrix manually, could be done with a for loop but this gives more insight early on
for(bt in 1:5){
sample = sort(sample(ncol(unique_signature),round(ncol(unique_signature)*0.63)))
unique_signature_sample <- unique_signature[,sample]
s=1
r=650
b=1
buckets <- list()
while(s<nrow(unique_signature_sample)){
  band <- as.data.frame(unique_signature_sample[s:(s+r-1),])
  for(f in 1:ncol(band)){
    column_value <- ""
    for(d in 1:nrow(band)){
      paste_value <- toString(band[d,f])
      column_value <- paste(column_value,paste_value,sep="")
    }
    buckets <- append(buckets,column_value)
  }
  s=s+r
}

buckets_df <- lapply(buckets, data.frame, stringsAsFactors = FALSE)
buckets_df <- rbindlist(buckets_df)
buckets_df$product <-0
e=1
g=1
while(e <=ncol(unique_signature_sample)){
  buckets_df$product[g] <- sample[e]
  if(e==ncol(unique_signature_sample)&g<nrow(buckets_df)){
  e=0
  }
  e=e+1
  g=g+1
}

buckets_df$product <- as.character(buckets_df$product)
agg <- aggregate(product~X..i.., data = buckets_df, paste0, collapse=" ")

near_neighbours <- as.data.frame(matrix(0, nrow = ncol(unique_signature_sample), ncol = ncol(unique_signature_sample)),row.names = sample)
colnames(near_neighbours)<-sample
for(h in 1:nrow(agg)){
  neighbours <- strsplit(agg$product[h], split = " ")
  neighbours <- lapply(neighbours, data.frame, stringsAsFactors = FALSE)
  neighbours <- rbindlist(neighbours)
  combinations <- expand.grid(neighbours$X..i.., neighbours$X..i..)
  for(z in 1:nrow(combinations)){
    value_1<-as.character(strtoi(combinations[z,1]))
    value_2<-as.character(strtoi(combinations[z,2]))
    near_neighbours[value_1,value_2]=1
  }
}
near_neighbours[lower.tri(near_neighbours,diag=TRUE)]<-0

D_f<-0
D_n<-length(data.df$modelID[sample])-length(unique(data.df$modelID[sample]))
N_c<-sum(near_neighbours)
sample_list<-as.list(sample)
for(ro in sample){
  for(co in sample){
    ro_chr<-as.character(ro)
    co_chr<-as.character(co)
    if(near_neighbours[ro_chr,co_chr]==1 & data.df$modelID[ro]==data.df$modelID[co]){
      D_f<-D_f+1
    }
  }
}

PQ<-D_f/N_c
PC<-D_f/D_n
F1_measure<-(2*PC*PQ)/(PC+PQ)

bootstrapping_results[12,1]<-bootstrapping_results[12,1]+PQ
bootstrapping_results[12,2]<-bootstrapping_results[12,2]+PC
bootstrapping_results[12,3]<-bootstrapping_results[12,3]+F1_measure
bootstrapping_results[12,4]<-bootstrapping_results[12,4]+N_c
}


averaged_bootstrapping<-bootstrapping_results/5
averaged_bootstrapping[,4]<- averaged_bootstrapping[,4]/(0.5*1023*1022)


PQ_plot<-plot(averaged_bootstrapping$comp,averaged_bootstrapping$PQ, type="l", col="black", lwd=1, xlab="Fraction of Comparisons", ylab="Pair Quality")
f1_plot<-plot(averaged_bootstrapping$comp,averaged_bootstrapping$`F1*-measure`, type="l", col="black", lwd=1, xlab="Fraction of Comparisons", ylab="F1*-measure")
averaged_bootstrapping[13,]<-c(0,1,0,1) 
PC_plot<-plot(averaged_bootstrapping_pr$comp,averaged_bootstrapping_pr$PC, type="l", col="black", lwd=1, xlab="Fraction of Comparisons", ylab="Pair Completeness")
  




#USE OPTIMAL VALUES FOR R AND B FOR FULL DATASET
s=1
r=50
b=13
buckets <- list()
while(s<nrow(unique_signature)){
  band <- as.data.frame(unique_signature[s:(s+r-1),])
  for(f in 1:ncol(band)){
    column_value <- ""
    for(d in 1:nrow(band)){
      paste_value <- toString(band[d,f])
      column_value <- paste(column_value,paste_value,sep="")
    }
    buckets <- append(buckets,column_value)
  }
  s=s+r
}

buckets_df <- lapply(buckets, data.frame, stringsAsFactors = FALSE)
buckets_df <- rbindlist(buckets_df)
buckets_df$product <-0
e=1
g=1
while(e <=ncol(unique_signature)){
  buckets_df$product[g] <- e
  if(e==ncol(unique_signature)&g<nrow(buckets_df)){
    e=0
  }
  e=e+1
  g=g+1
}

buckets_df$product <- as.character(buckets_df$product)
agg <- aggregate(product~X..i.., data = buckets_df, paste0, collapse=" ")

near_neighbours <- matrix(0, ncol = nrow(data.df), nrow = nrow(data.df))
for(h in 1:nrow(agg)){
  neighbours <- strsplit(agg$product[h], split = " ")
  neighbours <- lapply(neighbours, data.frame, stringsAsFactors = FALSE)
  neighbours <- rbindlist(neighbours)
  combinations <- expand.grid(neighbours$X..i.., neighbours$X..i..)
  for(z in 1:nrow(combinations)){
    value_1<-strtoi(combinations[z,1])
    value_2<-strtoi(combinations[z,2])
    near_neighbours[value_1,value_2]=1
  }
}


#similarity measure
features <- data.df[,-c("shop","url","modelID","title")]
features <- dplyr::rename_with(features, tolower)
brand <- features %>%
  select(contains('brand'))
brand$brand_feature<-""
for(w in 1:nrow(brand)){
  if(!is.na(brand$featuresmap.brand[w])){
    brand$brand_feature[w]<-paste(brand$brand_feature[w],brand$featuresmap.brand[w])
  }
  if(!is.na(brand$featuresmap.brand.name[w])){
    brand$brand_feature[w]<-paste(brand$brand_feature[w],brand$featuresmap.brand.name[w])
  }
  if(!is.na(brand$brand[w])){
    brand$brand_feature[w]<-paste(brand$brand_feature[w],brand$.brand[w])
  }
  if(!is.na(brand$featuresmap.brand.name.[w])){
    brand$brand_feature[w]<-paste(brand$brand_feature[w],brand$featuresmap.brand.name.[w])
  }
}
brand$featuresmap.brand<-NULL
brand$featuresmap.brand.name<-NULL
brand$brand<-NULL
brand$featuresmap.brand.name.<-NULL
brand$brand_feature <- tolower(brand$brand_feature)

data.df$shop<-tolower(data.df$shop)

dissimilarity <- near_neighbours
for(x in 1:nrow(dissimilarity)){
  for(y in 1:ncol(dissimilarity)){
    if(dissimilarity[x,y]==0){
      dissimilarity[x,y]=99999
    }
    if(dissimilarity[x,y]==1 & data.df$shop[x]==data.df$shop[y]){
      dissimilarity[x,y]=99999
    }
    if(nchar(brand$brand_feature[x])<nchar(brand$brand_feature[y])){
      large_brand<-brand$brand_feature[y]
      small_brand<-brand$brand_feature[x]
    }else{
      large_brand<-brand$brand_feature[x]
      small_brand<-brand$brand_feature[y]
    }
    if(brand$brand_feature[x]!="" & brand$brand_feature[y]!="" & !grepl(small_brand,large_brand)){
      dissimilarity[x,y]=99999 
    }
  }
}

for(c in 1:nrow(dissimilarity)){
  for(o in 1:ncol(dissimilarity)){
    if(dissimilarity[c,o]==1){
      dissimilarity_value <- 1-cosine(binary_vectors[,c],binary_vectors[,o])
      dissimilarity[c,o]=dissimilarity_value
    }
  }
}



#classification algorithm with bootstrapping without lsh
column_name<-c("P", "R", "F1-measure", "comp")
grid_thresholds<- c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1)
classification_results<-as.data.frame(matrix(0, ncol = 4, nrow = 9))
colnames(classification_results)<-column_name
rownames(classification_results)<-grid_thresholds
for(Threshold in seq(0.1, 1, by=0.1)){
for(boot in 1:5){
sample_cl = sort(sample(ncol(unique_signature),round(ncol(unique_signature)*0.63)))
Duplicates<- as.data.frame(matrix(0, nrow = length(sample_cl), ncol = length(sample_cl)),row.names = sample_cl)
colnames(Duplicates)<-sample_cl
dissimilarity_sample<-dissimilarity[sample_cl,sample_cl]
colnames(dissimilarity_sample)<-sample_cl
rownames(dissimilarity_sample)<-sample_cl
for(c in 1:nrow(dissimilarity_sample)){
  for(o in 1:ncol(dissimilarity_sample)){
    if(dissimilarity_sample[c,o]<Threshold){
      Duplicates[c,o]<-1
    }
  }
}

Duplicates[lower.tri(Duplicates,diag=TRUE)]<-99999
FP<-0
TP<-0
FN<-0
count_ones<-0
for(ro in sample_cl){
  for(co in sample_cl){
    ro_chr<-as.character(ro)
    co_chr<-as.character(co)
    if(Duplicates[ro_chr,co_chr]==1 & data.df$modelID[ro]==data.df$modelID[co]){
      TP<-TP+1
      count_ones<-count_ones+1
    }
    if(Duplicates[ro_chr,co_chr]==1 & data.df$modelID[ro]!=data.df$modelID[co]){
      FP<-FP+1
      count_ones<-count_ones+1
    }
    if(Duplicates[ro_chr,co_chr]==0 & data.df$modelID[ro]==data.df$modelID[co]){
      FN<-FN+1
    }
  }
}

th_chr<-as.character(Threshold)
precision<-TP/(TP+FP)
recall<-TP/(TP+FN)
classification_results[th_chr,1]<-classification_results[th_chr,1]+precision
classification_results[th_chr,2]<-classification_results[th_chr,2]+recall
classification_results[th_chr,3]<-classification_results[th_chr,3]+((2*precision*recall)/(precision+recall))
classification_results[th_chr,4]<-classification_results[th_chr,4]+count_ones
}
}


classification_results_averaged<-classification_results/5
classification_results_averaged[,4]<-classification_results_averaged[,4]/max(classification_results_averaged[,4])
cassification_results_averaged[order('comp'),]
plot(classification_results_averaged$comp,classification_results_averaged$`F1-measure`, type="l", col="black", lwd=1, xlab="Fraction of Comparisons", ylab="F1-measure", ylim = c(0,0.20))
ggplot(data=classification_results_averaged, aes(x=comp, y=`F1-measure`))+
  geom_line()+ ylim(0,0.2) + labs(x="Fraction of comparisons") + theme_bw() + theme(panel.border = element_blank(), panel.grid.major = element_blank(),
                                                                                    panel.grid.minor = element_blank(), axis.line = element_line(colour = "black"))


