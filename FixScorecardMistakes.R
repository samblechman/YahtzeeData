# This script first runs IngestTextractCSVs.R to get the raw scores array
# Then, it applies 3 transformations to clean the data
#     1. Fixing mistakes in optical character recognition (because of handwriting/other problems)
#              e.g., page 34 - column 3 - 1004 --> 100
#     2. Swapping adjacent cells due to mine or Julia writing scores in the wrong cells
#              e.g., page 5 - column 6 - switch LG Straight/Yahtzee
#     3. Fixing mistakes in sums due to bad math by me or Julia
#              (see 1)
#        [these can include multiple columns, multiple old values, and multiple new values]

# Finally, the values of each cell are checked to ensure they make sense
# This includes ensuring subtotals/totals are the same as the sum of their respective cells
# It also includes values being within bounds (Aces ~ 0,1,2,3,4,5), (Yahtzee ~ 0,50), etc.


setwd('~/Desktop/YahtzeeData/') # change to appropriate directory
source('IngestTextractCSVs.R')


#### Lists of fixes/swaps ####
# fix bad OCR
fixList <- list(
   'Aces' = c(
      "page 2 - columns 1,6 - '','' --> 1,0",
      "page 3 - column 1,5 - '','' --> 0,1",
      "page 4 - columns 1,5 - '','' --> 1,1",
      "page 5 - columns 1,3,5 - 13,'','' --> 3,1,0",
      "page 6 - column 4 - '' --> 1",
      "page 7 - columns 4 - '' --> 1",
      "page 8 - columns 6 - '' --> 1",
      "page 9 - columns 2,3,6 - '','','' --> 1,1,1",
      "page 10 - columns 3,5 - '','' --> 2,1",
      "page 12 - columns 1,2,4,5 - '','','','' --> 0,0,1,0",
      "page 13 - columns 3,4,5 - 21,'','' --> 2,1,1",
      "page 14 - column 1,3,5 - '',73,'' --> 0,3,1",
      "page 15 - columns 2,3,4 - '','','' --> 1,1,1",
      "page 16 - column 4 - '' --> 1",
      "page 17 - columns 1,6 - '','' --> 2,1",
      "page 18 - columns 2,3,5 - 2,'','' --> 1,2,1",
      "page 19 - columns 1,3 - '','' --> 1,1",
      "page 20 - columns 2,3 - 44,'' --> 1,4",
      "page 21 - column 4 - '' --> 1",
      "page 22 - column 4 - '' --> 1",
      "page 25 - columns 3 - '' --> 1",
      "page 26 - columns 3 - '' --> 1",
      "page 28 - columns 1 - '' --> 1",
      "page 31 - columns 2,3,4,5 - '','','','' --> 1,0,1,1",
      "page 32 - column 1 - 6 --> 0",
      "page 33 - column 1 - '' --> 1",
      "page 34 - column 6 - 1 --> 3",
      "page 35 - columns 2,4,5 - '','','' --> 1,1,1",
      "page 36 - columns 1,5,6 - '',4,'' --> 2,1,1",
      "page 37 - columns 1,4,5 - '','','' --> 1,2,1",
      "page 38 - column 1 - '' --> 0",
      "page 39 - columns 4,5 - '','' --> 0,0",
      "page 40 - column 1 - '' --> 3",
      "page 42 - column 3 - '' --> 0",
      "page 43 - column 4 - '' --> 0",
      "page 44 - column 1 - '' --> 0",
      "page 47 - columns 1,3 - '',11 --> 0,1",
      "page 48 - column 1 - '' --> 1",
      "page 50 - column 1 - '' --> 0",
      "page 51 - column 6 - '' --> 1",
      "page 52 - column 3 - '' --> 0",
      "page 53 - column 3 - '' --> 1",
      "page 54 - column 3 - '' --> 1",
      "page 57 - columns 1,3,5 - '','','' --> 1,1,1",
      "page 59 - columns 2,5 - '',12 --> 1,2",
      "page 60 - columns 3,5,6 - '','','' --> 1,1,2",
      "page 61 - column 3 - '' --> 1",
      "page 63 - column 1 - '' --> 1"
   ),
   'Twos' = c(
      "page 7 - column 1 - '' --> 0",
      "page 17 - column 6 - 12 --> 2",
      "page 25 - column 3 - '' --> 0",
      "page 29 - column 1 - 4 --> 6",
      "page 36 - column 4 - '' --> 0",
      "page 50 - column 4 - '' --> 6",
      "page 55 - column 1 - 96 --> 6",
      "page 59 - column 2 - 76 --> 6",
      "page 64 - column 2 - '' --> 6"
   ),
   'Threes' = c(
      "page 16 - column 5 - 912 --> 9",
      "page 21 - column 5 - 33 --> 3",
      "page 24 - column 6 - 812 --> 12",
      "page 27 - column 6 - '' --> 0",
      "page 45 - column 4 - 43 --> 3",
      "page 56 - column 2 - '' --> 6",
      "page 58 - column 1 - 120 --> 12"
   ),
   'Fours' = c(
      "page 15 - column 3 - 12 --> 8", # ** okay, lol, this is quite the story, but accounts for the discrepancy in wins (need to fix totals for this game as well)
      "page 20 - column 5 - 102 --> 12",
      "page 27 - column 3 - 91 --> 9",
      "page 28 - column 2 - 58 --> 8"
   ),
   'Fives' = c(
      "page 18 - column 2 - 2012 --> 20",
      "page 55 - column 6 - 10 --> 16" # this last one will later be switched with the fours cell above
   ),
   'Sixes' = c(
      "page 15 - column 1 - 800 --> 18",
      "page 63 - column 4 - 224 --> 24",
      "page 64 - column 3 - 16 --> 18"
   ),
   'Total1' = c(
      "page 1 - column 6 - 687 --> 67",
      "page 2 - column 5 - 522 --> 52",
      "page 7 - column 1 - 655 --> 65",
      "page 15 - column 3 - 63 --> 59", # **
      "page 25 - column 2 - 7 --> 72",
      "page 38 - column 4 - 64 --> 65",
      "page 41 - column 2 - 781 --> 71",
      "page 45 - column 4 - 5 --> 50"
   ),
   'Bonus' = c(
      "page 11 - column 2 - 300 --> 0",
      "page 15 - column 3 - 35 --> 0", # **
      "page 31 - column 5 - 38 --> 0"
   ),
   'Total2' = c(
      "page 1 - column 6 - '' --> 102",
      "page 4 - column 6 - 1075 --> 105",
      "page 5 - column 6 - 15 --> 100",
      "page 15 - column 3 - 98 --> 59", # **
      "page 17 - column 6 - 960 --> 60",
      "page 18 - column 1 - 5 --> 50",
      "page 31 - column 5 - 0 --> 62",
      "page 38 - column 4 - 0 --> 100",
      "page 45 - column 4 - 5 --> 50",
      "page 64 - column 3 - 1034 --> 102"
   ),
   '3 of a Kind' = c(
      "page 13 - column 6 - 206 --> 26",
      "page 20 - column 3 - '' --> 26",
      "page 34 - column 4 - 1216 --> 16",
      "page 37 - column 4 - 2 --> 23",
      "page 40 - column 5 - 130 --> 30"
   ),
   '4 of a Kind' = c(
      "page 22 - column 3,4 - 6,1 --> 0,0",
      "page 35 - column 1 - 1 --> 0",
      "page 60 - column 3 - 6 --> 0",
      "page 61 - column 2 - 20 --> 0",
      "page 64 - column 2 - 1229 --> 29"
   ),
   'Full House' = c(
      "page 2 - column 2 - 15 --> 0",
      "page 14 - column 3 - 325 --> 25",
      "page 57 - column 5 - 5 --> 25",
      "page 62 - column 2 - 272 --> 27",
      "page 64 - column 6 - 6 --> 0"
   ),
   'SM Straight' = c(
      "page 2 - column 6 - 233 --> 30",
      "page 4 - column 3 - 0 --> 30",
      "page 14 - column 2 - 39 --> 30"
   ),
   'LG Straight' = c(
      "page 40 - column 5 - 06 --> 0"
   ),
   'Yahtzee' = c(
      "page 2 - columns 1,2 - 6502001,1 --> 50,0",
      "page 3 - column 5 - 50 --> 0",
      "page 19 - columns 3,5 - 5,5 --> 50,50",
      "page 20 - columns 3,4 - 5,5 --> 50,50",
      "page 21 - column 1 - 04 --> 0",
      "page 22 - column 2 - 1 --> 0",
      "page 26 - columns 4,6 - 05,5 --> 0,50",
      "page 27 - column 2 - 5 --> 50",
      "page 28 - column 6 - 5 --> 50",
      "page 29 - column 2 - 5 --> 50",
      "page 32 - column 2 - 5 --> 50",
      "page 34 - column 3 - 50 --> 0",
      "page 38 - columns 1,3,4,6 - 5,4,5,5 --> 50,0,50,50",
      "page 44 - column 2 - 500 --> 0",
      "page 45 - column 5 - 5 --> 50",
      "page 47 - column 3 - 5 --> 50",
      "page 48 - column 5 - 1 --> 0",
      "page 49 - column 4 - 401 --> 40",
      "page 54 - column 4 - 50 --> 0",
      "page 57 - column 4 - 5 --> 50",
      "page 58 - column 5 - 5 --> 50",
      "page 60 - column 6 - 5 --> 50",
      "page 63 - columns 3,6 - 5,5 --> 50,50",
      "page 64 - columns 1,5 - 5,5 --> 50,50"
   ),
   'Chance' = c(
      "page 18 - column 2 - 232 --> 20",
      "page 23 - column 2 - 1 --> 19",
      "page 24 - column 3 - 2023 --> 23"
   ),
   'Y Bonus' = c(
      "page 8 - column 3 - 50 --> 100",
      "page 60 - column 6 - 0 --> 50",
      "page 60 - column 5 - 50 --> 0"
   ),
   'TotalLower' = c(
      "page 4 - columns 3,6 - '','' --> 111,144",
      "page 16 - columns 1,2 - '',1 --> 138,143",
      "page 19 - column 3 - 144 --> 194",
      "page 26 - column 6 - 103 --> 203",
      "page 34 - column 4 - 111133 --> 133",
      "page 35 - columns 1,2 - '',5 --> 140,161",
      "page 40 - columns 5,6 - '','' --> 107,160",
      "page 45 - column 3 - 224 --> 226",
      "page 52 - column 6 - '' --> 315",
      "page 54 - column 6 - '' --> 138",
      "page 57 - columns 5,6 - '','' --> 138,156",
      "page 58 - columns 5,6 - '','' --> 149,163"
   ),
   'TotalUpper' = c(
      "page 2 - column 3 - 589 --> 59",
      "page 3 - column 4 - 259 --> 59",
      "page 4 - column 6 - 1015 --> 105",
      "page 7 - column 2 - 757 --> 57",
      "page 15 - column 3 - 98 --> 59", # **
      "page 19 - column 6 - 5 --> 50",
      "page 25 - column 4 - '' --> 99",
      "page 28 - column 5 - '' --> 101",
      "page 30 - column 5 - 4167 --> 167",
      "page 32 - column 4 - 5 --> 50",
      "page 34 - column 3 - 1004 --> 100",
      "page 40 - column 5 - 10760 --> 60",
      "page 40 - column 6 - 160 --> 104",
      "page 41 - column 6 - '' --> 52",
      "page 46 - column 6 - '' --> 102",
      "page 52 - column 6 - 31554 --> 54",
      "page 53 - column 6 - '' --> 51",
      "page 54 - columns 5,6 - '',138 --> 102,51",
      "page 57 - columns 5,6 - 138,156 --> 60,103",
      "page 58 - columns 4,5,6 - '',149,163 --> 98,98,100",
      "page 59 - column 6 - '' --> 56"
   ),
   'GrandTotal' = c(
      "page 4 - column 3 - 1214 --> 214",
      "page 11 - column 1 - 2316 --> 316",
      "page 12 - column 1 - 25 --> 259",
      "page 15 - column 3 - 233 --> 194", # **
      "page 27 - column 3 - 1 --> 180",
      "page 33 - column 6 - '' --> 262",
      "page 39 - columns 5,6 - '','' --> 314,216",
      "page 40 - columns 5,6 - '',104 --> 167,264",
      "page 41 - column 6 - 52 --> 126",
      "page 43 - column 5 - 23 --> 233",
      "page 44 - column 6 - 225 --> 228",
      "page 46 - column 6 - 102298 --> 298",
      "page 47 - columns 5,6 - 350,'' --> 330,321",
      "page 50 - column 6 - 171 --> 271",
      "page 52 - columns 5,6 - '','' --> 157,369",
      "page 53 - column 6 - 51131 --> 131",
      "page 54 - columns 4,5,6 - 261,102,51 --> 267,339,189",
      "page 57 - columns 5,6 - 60,103 --> 198,259",
      "page 58 - columns 4,5,6 - 98202,98,100 --> 202,247,263",
      "page 59 - column 6 - 56209 --> 209"
   )
)

# swap cells
swapsList <- c(
   "page 5 - column 6 - switch LG Straight/Yahtzee",
   "page 14 - column 6 - switch Yahtzee/Chance",
   "page 16 - columns 5,6 - switch TotalLower/TotalUpper",
   "page 17 - columns 1,2 - switch TotalLower/TotalUpper",
   "page 24 - columns 1,2 - switch TotalLower/TotalUpper",
   "page 24 - column 5 - switch Fours/Fives",
   "page 27 - column 3 - switch Threes/Fours",
   "page 30 - column 5 - switch TotalLower/TotalUpper",
   "page 32 - column 6 - switch 4 of a Kind/Full House",
   "page 35 - columns 3,4 - switch TotalLower/TotalUpper",
   "page 36 - columns 1,2 - switch TotalLower/TotalUpper",
   "page 43 - columns 1,2 - switch TotalLower/TotalUpper",
   "page 49 - column 4 - switch LG Straight/Yahtzee",
   "page 50 - column 6 - switch 4 of a Kind/Full House",
   "page 55 - column 6 - switch Fours/Fives",
   "page 62 - column 2 - switch 4 of a Kind/Full House"
)

# bad math
probsList <- c(
   "page 64 - columns 4,6 - 189,222 --> 187,212", 'GrandTotal',
   "page 64 - columns 4,6 - 90,122 --> 88,112", 'TotalLower',
   "page 63 - column 2 - 153 --> 152", 'GrandTotal',
   "page 62 - column 2 - 262 --> 266", 'GrandTotal',
   "page 61 - column 2 - 240 --> 242", 'GrandTotal',
   "page 61 - column 2 - 139 --> 141", 'TotalLower',
   "page 60 - column 5 - 173 --> 169", 'GrandTotal',
   "page 60 - column 5 - 61 --> 57", 'Total1 + Total2 + TotalUpper',
   "page 60 - column 2 - 233 --> 236", 'GrandTotal',
   "page 60 - column 2 - 105 --> 108", 'Total2 + TotalUpper',
   "page 60 - column 2 - 70 --> 73", 'Total1',
   "page 59 - column 1 - 214 --> 314", 'GrandTotal',
   "page 52 - column 4 - 245 --> 235", 'GrandTotal',
   "page 48 - column 6 - 274 --> 264", 'GrandTotal',
   "page 48 - column 6 - 171 --> 161", 'TotalLower',
   "page 46 - column 6 - 298 --> 300", 'GrandTotal',
   "page 46 - column 6 - 102 --> 104", 'Total2 + TotalUpper',
   "page 46 - column 6 - 67 --> 69", 'Total1',
   "page 45 - column 4 - 186 --> 185", 'GrandTotal',
   "page 45 - column 4 - 136 --> 135", 'TotalLower',
   "page 36 - column 1 - 308 --> 307", 'GrandTotal',
   "page 36 - column 1 - 113 --> 112", 'Total2 + TotalUpper',
   "page 35 - columns 5,6 - 257,105 --> 260,201", 'GrandTotal',
   "page 35 - columns 5,6 - 97,106 --> 100,102", 'Total2 + TotalUpper',
   "page 35 - columns 5,6 - 62,68 --> 65,67", 'Total1',
   "page 33 - column 3 - 268 --> 258", 'GrandTotal',
   "page 33 - column 3 - 165 --> 155", 'TotalLower',
   "page 31 - column 5 - 221 --> 231", 'GrandTotal',
   "page 27 - column 6 - 182 --> 180", 'GrandTotal',
   "page 27 - column 6 - 44 --> 42", 'Total1 + Total2 + TotalUpper',
   "page 13 - column 2 - 247 --> 256", 'GrandTotal',
   "page 13 - column 2 - 202 --> 211", 'TotalLower',
   "page 11 - column 1 - 316 --> 326", 'GrandTotal',
   "page 11 - column 1 - 214 --> 224", 'TotalLower',
   "page 8 - columns 3,4 - 372,226 --> 362,225", 'GrandTotal',
   "page 8 - columns 3,4 - 321,168 --> 311,167", 'TotalLower',
   "page 2 - column 2 - 35 --> 45", 'Total1 + Total2 + TotalUpper',
   "page 2 - column 2 - 89 --> 99", 'GrandTotal',
   "page 1 - column 1 - 169 --> 159", 'TotalLower',
   "page 1 - column 1 - 214 --> 204", 'GrandTotal'
)
#### End of fixes/swaps list ####


#### Make the fixes/swaps ####
# Functions and object to parse the fixes/swaps notation and perform them
pattern_fixes <- "^page ([0-9]+) - column(s)? ([1-6,]+) - [0-9',]+ --> ([0-9,]+)$"
pattern_swaps <- "^page ([0-9]+) - column(s)? ([1-6,]+) - switch ([A-z0-9 ]+)/([A-z0-9 ]+)$"

# convert written descriptions of fixes/swaps to structured description (data.frame)
# fixes
fixList <- lapply(X = fixList, 
                  FUN = function(string) {
                     data.frame(
                        page = as.integer(gsub(pattern_fixes, '\\1', string)),
                        col = gsub(pattern_fixes, '\\3', string),
                        newvals = gsub(pattern_fixes, '\\4', string)
                     )
                  })
# swaps
swapsList <- data.frame(
   page = as.integer(gsub(pattern_swaps, '\\1', swapsList)),
   col = gsub(pattern_swaps, '\\3', swapsList),
   row1 = gsub(pattern_swaps, '\\4', swapsList),
   row2 = gsub(pattern_swaps, '\\5', swapsList)
)
# bad math
probsList <- data.frame(
   row = probsList[seq(2,length(probsList), 2)],
   page = as.integer(gsub(pattern_fixes, '\\1', probsList[seq(1,length(probsList), 2)])),
   col = gsub(pattern_fixes, '\\3', probsList[seq(1,length(probsList), 2)]),
   newvals = gsub(pattern_fixes, '\\4', probsList[seq(1,length(probsList), 2)])
)


# Function to perform fixes
fixCells <- function(row, page, col, newvals) {
   if (grepl(' + ', row, fixed=TRUE)) row <- strsplit(row, split=' + ', fixed=TRUE)[[1]]
   if (grepl(',', col)) {
      col <- strsplit(col, ',')[[1]]
      newvals <- strsplit(newvals, ',')[[1]]
   }
   stopifnot('Number of cells to be changed != number of new values provided.' = length(col) == length(newvals))
   col <- as.integer(col)
   newvals <- as.integer(newvals)
   scores[row, col, page] <<- newvals
}
# Function to perform swaps
swapCells <- function(row1, row2, page, col) {
   # TODO: in the future, handle cases where swapping columns within same row?
   if (grepl(',', col)) {
      col <- strsplit(col, split=',')[[1]]
   }
   col <- as.integer(col)
   temp <- scores[row1, col, page]
   scores[row1, col, page] <<- scores[row2, col, page]
   scores[row2, col, page] <<- temp
}


# loop over each scoreboard row (e.g., Aces, Twos, etc.)
# and make each fix as specified in data.frames stored within fixList
for (row in names(fixList)) {
   fixDF <- fixList[[row]]
   for (i in seq_len(nrow(fixDF))) {
      fixCells(row=row, page=fixDF$page[i], col=fixDF$col[i], newvals=fixDF$newvals[i])
   }
}

# loop over each row in the swapsList data.frame and make the swap
for (i in seq_len(nrow(swapsList))) {
   swapCells(row1=swapsList$row1[i], row2=swapsList$row2[i], page=swapsList$page[i], col=swapsList$col[i])
}


# finally, fix all bad math problems
for (i in seq_len(nrow(probsList))) {
   row <- strsplit(probsList$row[i], split=' + ', fixed=TRUE)[[1]]
   for (r in row) {
      fixCells(row=r, page=probsList$page[i], col=probsList$col[i], newvals=probsList$newvals[i])
   }
}

# remove unnecessary variables
rm(swapsList, pattern_swaps, swapCells, fixList, pattern_fixes, fixCells, row, i, fixDF, probsList, r)
#### END fixes/swaps ####


# Impute blank cells as 0
# convert character --> integer
scores[scores == ''] <- 0L # im shocked this works
storage.mode(scores) <- 'integer'


#### CHECK IF ALL VALUES MAKE SENSE ####
checkError <- function(expr, msg) {
   if (!all(expr)) {
      cat(which(!expr), msg, '\n')
      checked <<- TRUE
   }
}

for (i in rev(seq_len(dim(scores)[3]))) {
   t <- scores[,,i]
   checked <- FALSE
   
   # upper values valid?
   checkError(t['Aces',] %in% 0L:6L,           'Aces out of bounds')
   checkError(t['Twos',] %in% seq(0, 10, 2),   'Twos out of bounds')
   checkError(t['Threes',] %in% seq(0, 15, 3), 'Threes out of bounds')
   checkError(t['Fours',] %in% seq(0, 20, 4),  'Fours out of bounds')
   checkError(t['Fives',] %in% seq(0, 25, 5),  'Fives out of bounds')
   checkError(t['Sixes',] %in% seq(0, 30, 6),  'Sixes out of bounds')
   
   # bonus value valid?
   checkError(t['Bonus',] %in% c(0L, 35L),                              'Bonus value not 0 or 35')
   checkError((apply(t[upper_rows,], 2, sum) >= 63L) == (t['Bonus',] == 35L), 'Bonus presence wrong!')
   
   # upper sums valid?
   checkError(apply(t[1:6,], 2, sum) == t['Total1',],       'Upper sum != upper subtotal')
   checkError((t['Total1',] + t['Bonus',]) == t['Total2',], 'Upper subtotal + bonus != upper grandtotal')
   
   # upper sum same in upper and lower tables?
   checkError(t['Total2',] == t['TotalUpper',], 'Upper total != top and bottom')
   
   # lower values valid?
   checkError(t['3 of a Kind',] >= 0L & t['3 of a Kind',] <= 30L, '3 of a Kind out of bounds')
   checkError(t['4 of a Kind',] >= 0L & t['4 of a Kind',] <= 30L, '4 of a Kind out of bounds')
   checkError(t['Full House',] %in% c(0L, 25L),  'Full house != 0 or 25')
   checkError(t['SM Straight',] %in% c(0L, 30L), 'SM Straight != 0 or 30')
   checkError(t['LG Straight',] %in% c(0L, 40L), 'LG Straight != 0 or 40')
   checkError(t['Yahtzee',] %in% c(0, 50L),      'Yahtzee != 0 or 50')
   checkError(t['Chance',] >= 0L & t['Chance',] <= 30L & !t['Chance',] %in% 1:4, 'Chance out of bounds')
   
   checkError(apply(t[lower_rows,], 2, sum) == t['TotalLower',], 'Lower sum != lower total')
   checkError((t['TotalLower',] + t['TotalUpper',]) == t['GrandTotal',], 'Grand total sum != Grand total')
   
   if (checked) {
      cat(i, '\n')
      print(t)
   }
}
rm(checked, t, i, checkError, lower_rows, upper_rows)
#### END CHECK ####























