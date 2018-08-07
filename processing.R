#******************************************************************************
# NOTE: Comments are listed as sublevels of a main comment. They are used to  *
#       outline the processes used throughout this script and how they relate *
#       to one another.                                                       *
#                                                                             *
#       EXAMPLE: # A Comment such as a main process               (Top level) *
#                # > This is a subprocess                           (Level 1) *
#                # >> This is a subprocess of a subprocess          (Level 2) *
#                # A second main process                          (Top level) *
#                # > This is a subprocess                           (Level 1) *
#                # A Comment such as a third main process         (Top level) *
#                # > This is a subprocess                           (Level 1) *
#                # >> This is a subprocess of a subprocess          (Level 2) *
#                ... etc.                                           (Level N) *
#                                                                             *
#******************************************************************************

# Load required libraries
library(data.table)
library(dplyr)

# Download and extract data
# > If not downloaded, download the data. If downloaded, move on.
if (!file.exists("data.zip")) {
     message("Downloading data (≈60 Mb) from 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'... Please wait")
     download.file(url = "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", dest = "data.zip", method = "curl")
} else {
     message("Data already downloaded as data.zip")
}

# > If data is downloaded and not extracted, extract the ZIP archive. If extracted, move on.
if (file.exists("data.zip") & !file.exists("UCI HAR Dataset")) {
     message("Extracting data... Please wait")
     unzip("data.zip")
} else {
     message("Data already extracted to ./UCI HAR Dataset/")
}

# Combining the Full Data Sets
# > Load Vectors (X), Activity Labels (y), Subject_IDs (_sub) and header information.

trainX    <- fread("UCI HAR Dataset/train/X_train.txt")
trainy    <- fread("UCI HAR Dataset/train/y_train.txt")
train_sub <- fread("UCI HAR Dataset/train/subject_train.txt")
testX     <- fread("UCI HAR Dataset/test/X_test.txt")
testy     <- fread("UCI HAR Dataset/test/y_test.txt")
test_sub  <- fread("UCI HAR Dataset/test/subject_test.txt")
act_labs  <- readLines("UCI HAR Dataset/activity_labels.txt")
headers   <- readLines("UCI HAR Dataset/features.txt")

# > Combine X, y and _sub to form full data set
# >> Combine X, y and _sub of training set to test set individually using rbind().

comboX    <- rbind(trainX,testX)
comboy    <- rbind(trainy,testy) %>% mutate(V1=tstrsplit(act_labs," ")[[2]][V1])
combo_sub <- rbind(train_sub,test_sub)

# >> Combine the _sub, y and X columns using cbind()
data      <- cbind(combo_sub,comboy,comboX)

# > Form headers, make headings more human readable, remove parethesis and substitute hyphens (-) for periods (.).

headers <- {
     headers %>%
     gsub("\\(","",.) %>%
     gsub("\\)","",.) %>%
     gsub("-",".",.) %>%
     gsub(" t"," time",.) %>%
     gsub(" f"," freq",.)
}

# > Name columns on data set. Numbers from original header list perserved to provide unique header names.

colnames(data) <- c("Subject_ID", "Activity", headers)

# Constructing the Final Data Set
# > List out required columns

names_mean <- grep("[Mm]ean", headers, value = TRUE)
names_std  <- grep("[Ss]td", headers, value = TRUE)

# > Form final data set including columns, "Subject_ID" and "Activity"

final_data <- data %>% select(c("Subject_ID","Activity",names_mean,names_std))

# > Remove perservered column numbers from header names

final_headers <- {
     tstrsplit(c(names_mean,names_std)," ")[[2]]
}

# > Set column names of "final_data"

colnames(final_data) <- c("Subject_ID","Activity",final_headers)

# Results

final_result <- group_by(final_data,Subject_ID,Activity) %>% summarise_each(funs(mean))
print(final_result)

# Clean up the environment only leaving the final data sets in the environment
message("Cleaning up...")
rm("act_labs","combo_sub","comboX","comboy","final_headers","headers","names_mean","names_std","test_sub","testX","testy","train_sub","trainX","trainy")

message("DONE!")
message("Data sets are stored on the following variables:")
message("data         <<< Full data set")
message("final_data   <<< Reduced data set of mean and standard deviation data")
message("final_result <<< Tidy final data set")
