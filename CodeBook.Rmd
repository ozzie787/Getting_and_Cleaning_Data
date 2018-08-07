---
title: "Obtaining and Cleaning a Data Set"
author: "Stephen Osborne"
output:
     html_document:
          toc: TRUE
---

```{r eval=FALSE, message=FALSE, warning=FALSE, include=FALSE, paged.print=FALSE}
library(knitr)
library(rmarkdown)
```

```{r global_options, eval=FALSE, include=FALSE}
knitr::opts_chunk$set(fig.width=12, fig.height=8, fig.path='Figs/',
                      echo=TRUE, warning=FALSE, message=FALSE)
```



## Libraries/Packages Required

The following libraries were used

* data.table
* dplyr

If installed, they can be loaded as follows:

```{r libraries, message=FALSE, warning=FALSE, include=TRUE}
library(data.table)
library(dplyr)
```

## Obtaining & Extracting Data

###The Data

The data was accessed from:  
**URL:** <https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip>  
**Time:** 2018-08-06 17:09:10 BST.  
**Data Format:** ZIP Archive

### Download of, and Extracting the Raw Data

If the data is not downloaded, the data is downloaded from the above URL. If the data has been previously downloaded and named as data.zip, the script prints a message and moves onto the next step.

```{r message=FALSE}
if (!file.exists("data.zip")) {
     message("Downloading data (≈60 Mb) from 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'... Please wait")
     download.file(url = "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", dest = "data.zip", method = "curl")
} else {
     message("Data already downloaded as data.zip")
}
```

If the data is not extracted, the data is extracted from data.zip. If the data has been previously extracted to to "UCI HAR Dataset", the script prints a message and moves onto the next step.

```{r message = FALSE}
if (file.exists("data.zip") & !file.exists("UCI HAR Dataset")) {
     message("Extracting data... Please wait")
     unzip("data.zip")
} else {
     message("Data already extracted to ./UCI HAR Dataset/")
}
```

## Producing the Full Data Set
### Loading the data to data tables from the raw data files

The plain text files were loaded into data tables using fread(). The data vectors, data labels, subject ID and column header components are labeled `X`, `y`, `_sub` and `headers` respectively. The activity labels are read into a vector, `act_labs`.

```{r}
trainX    <- fread("UCI HAR Dataset/train/X_train.txt")
trainy    <- fread("UCI HAR Dataset/train/y_train.txt")
train_sub <- fread("UCI HAR Dataset/train/subject_train.txt")
testX     <- fread("UCI HAR Dataset/test/X_test.txt")
testy     <- fread("UCI HAR Dataset/test/y_test.txt")
test_sub  <- fread("UCI HAR Dataset/test/subject_test.txt")
act_labs  <- readLines("UCI HAR Dataset/activity_labels.txt")
headers   <- readLines("UCI HAR Dataset/features.txt")
```

### Combining the data tables

The rows of vector, data label and subject ID components from the training and testing data sets were recombined separately using `rbind()`. Durring the formation of `comboy`, the numerical classes (1 to 6) are substituted with character strings. This is acived using `mutate()` where the activity number is referanced against a list of activity labels expressed as a vector.

```{r}
comboX    <- rbind(trainX,testX)
comboy    <- rbind(trainy,testy) %>% mutate(V1=tstrsplit(act_labs," ")[[2]][V1])
combo_sub <- rbind(train_sub,test_sub)
```

`cbind()` was used to join the columns of subject_IDs (`_sub`), activity labels (`y`) and vector data (`X`) to form the combined data set `data`.

```{r}
data      <- cbind(combo_sub,comboy,comboX)
```

### Data Table Column Headers

To make the column headings more human readable, using `gsub` any parethesis were removed and hyphens (-) were substituted for periods (.). Variables with a lowercase "t" ot "f" prefix were substituted to "time" and "freq" respectively using `gsub()`.

```{r}
headers <- {
     headers %>%
     gsub("\\(","",.) %>%
     gsub("\\)","",.) %>%
     gsub("-",".",.) %>%
     gsub(" t"," time",.) %>%
     gsub(" f"," freq",.)
}
```

The columns of the data set were named using `colnames()`. At this stage, the numbers read from original header list are perserved to provide unique header names for use with the `dplyr` package. `Subject_ID` and `Activity` are not included in the header list read in, therefore are combined with `headers` to provide sufficient names for all the columns.

```{r}
colnames(data) <- c("Subject_ID", "Activity", headers)
```

## Constructing the Final Data Set

`grep()` was used to extract any column that contained data relating to a mean or standard deviation of a quantity and their names were stored in `names_mean` and `names_std` respectively. The option ```value = TRUE``` is set to return the actual values rather than a list of indices. The REGEX expressions [Mm] and [Ss] is used to capture columns including the patterns: "Mean"; "mean"; "Std"; and "std".

```{r}
names_mean <- grep("[Mm]ean", headers, value = TRUE)
names_std  <- grep("[Ss]td", headers, value = TRUE)
```
The final data set, `final_data` was formed using `select()`. The columns, "Subject_ID" and "Activity" are written explicitly as they are included in neither `names_mean` nor `names_std`.

```{r}
final_data <- data %>% select(c("Subject_ID","Activity",names_mean,names_std))
```

At this stage, the perserved numbers in the column headers are removed using `tstrsplit()` and spliting on a space. The indice "[[2]]" is specified as we only want to perseve the second level of the output containing the column names without the numbers.

```{r}
head(names_mean)
final_headers <- tstrsplit(c(names_mean,names_std)," ")[[2]]
head(final_headers)
```
The column names of `final_data` was set using `colnames()`. Like before `Subject_ID` and `Activity` are not included in the header list, therefore are combined with `final_headers` to provide sufficient names for all the columns.

```{r}
colnames(final_data) <- c("Subject_ID","Activity",final_headers)
```

## Results
 
The tidy data set `final_result` was obtained by grouping `final_data` by `Subject_ID` and `Activity` and piping it to `summarise_each`. The option `funs()` is set to `mean` to obtain a single mean for each recorded variable per user and per activity.
 
```{r message=FALSE, warning=FALSE}
final_result <- {
     group_by(final_data,Subject_ID,Activity) %>%
     summarise_each(funs(mean))
}
print(final_result)
```

## Finalisation & Clean-up

The script removes all variables but `data`, `final_data` and `final_result` from the global environment at the end of the execution. This leaves the combined, reduced and tidy data sets ready for viewing by the end user.
