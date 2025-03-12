# This script ingests .csv files from Amazon's Textract tool

### INPUT ###
# the output from Textract is a directory per image that contains two tables:
# table-1.csv is the upper yahtzee table
# table-2.csv is the lower yahtzee table

### ACTIONS ###
# the .csv files are slightly messy because of imperfect optical character recognition
# this script cleans them up a bit

### OUTPUT ###
# An array of dimensions:
#     20 rows (number of rows for a single yahtzee game: Aces, Twos, ..., Grand Total)
#     6 columns (each page contains 3 games with 2 players each)
#     NumPages (number of score pages)



setwd('~/Desktop/YahtzeeData/') # change to appropriate directory


#### DEFINE HELPER FUNCTIONS ####
parseNums <- function(x, table, lens) {
   # Helper function for prepLines below
   start <- 3L
   end <- 8L
   if (lens == 9L) {
      start <- 4L
      end <- 9L
   }
   x <- x[start:end]
   x <- gsub('I', '1', x, ignore.case=TRUE)
   x <- gsub('S', '5', x, ignore.case=TRUE)
   x <- gsub(' ', '', x)
   return(x)
}

prepLines <- function(table, dir) {
   # This function grabs table-1.csv or table-2.csv
   # It takes only the necessary rows and makes a few simple cleanup changes
   t <- readLines(paste0('TextractOutput/', dir, '/table-', table, '.csv'))
   start_line <- 1
   end_line <- 9
   if (table == 2) {
      start_line <- grep('LOWER SECTION', t) + 1
      end_line <- grep('GRAND TOTAL', t)
      stopifnot('lower table weird' = end_line - start_line == 11L)
   }
   t <- t[start_line:end_line]
   if (table == 2) {
      t <- t[-9] # for lower table - remove the second yahtzee bonus row of cells - not necessary
   }
   t <- gsub("'", '', t)
   t <- gsub('"', '', t)
   t <- gsub('^,', '', t)
   t <- strsplit(t, ',')
   if (all(sapply(t, function(x) x[length(x)] == ''))) {
      t <- lapply(t, function(x) x[-length(x)])
   }
   
   # handle edge cases
   if (dir == 3L & table == 2L) t[[length(t)]] <- t[[length(t)]][-length(t[[length(t)]])]
   if (dir == 60 & table == 1L) t[[1]] <- t[[1]][-length(t[[1]])]
   
   # check for consistent table spacing by row
   lt <- unique(lengths(t))
   stopifnot('strsplit failed' = length(lt) == 1L)
   
   # turn row list into matrix
   t <- t(sapply(t, parseNums, table=table, lens=lt))
   
   return(t)
}

combineTables <- function(dir) {
   # grab each table and combine
   t <- rbind(
      prepLines(table=1, dir=dir),
      prepLines(table=2, dir=dir)
   )
   
   rownames(t) <- yahtzee_rownames
   colnames(t) <- rep(c('J', 'S'), times=3L)
   
   # handle yahtzee bonus (worth 50 points each)
   t['Y Bonus',] <- sapply(X = strsplit(t['Y Bonus',], split=''),
                           FUN = function(x) 50 * length(x))
   
   # remove any non-integer character
   t <- gsub('[^0-9]', '', t)
   
   # return verified data
   return(t)
}


#### CREATE EMPTY ARRAY ####
upper_rows <- c('Aces', 'Twos', 'Threes', 'Fours', 'Fives', 'Sixes')
lower_rows <- c('3 of a Kind', '4 of a Kind', 'Full House', 'SM Straight', 'LG Straight', 'Yahtzee', 'Chance', 'Y Bonus')
yahtzee_rownames <- c(upper_rows, 'Total1', 'Bonus', 'Total2',
                      lower_rows, 'TotalLower', 'TotalUpper', 'GrandTotal')
scores <- array(data = NA_integer_, 
                dim = c(20, 6, length(list.files('TextractOutput/'))),
                dimnames = list(yahtzee_rownames, NULL))

for (dir in 1:65) {
   scores[,,dir] <- combineTables(dir = dir)
}
rm(yahtzee_rownames, dir, combineTables, parseNums, prepLines)


