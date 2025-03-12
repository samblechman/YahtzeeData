

setwd('~/Desktop/YahtzeeData/') # change to appropriate directory
source('FixScorecardMistakes.R')


# Reshape scores array so each 3-game page is split into 3 different "slices" of a final array
scores <- array(scores, 
                dim = c(nrow(scores), 2, dim(scores)[3] * 3),
                dimnames = list(
                   rownames(scores),
                   c('Julia', 'Sam'),
                   NULL
                ))

# verify the current record: (Julia wins - Sam wins - ties)
table(apply(scores['GrandTotal',,], 2, function(x) {
   if (x[1] > x[2]) return('Julia')
   if (x[2] > x[1]) return('Sam')
   if (x[1] == x[2]) return('Tied')
   return('??')
}))


# define useful objects
cont_rows <- c('Aces', 'Twos', 'Threes', 'Fours', 'Fives', 'Sixes', 'Total1', 'Total2', '3 of a Kind', '4 of a Kind', 'Chance', 'Y Bonus', 'TotalLower', 'GrandTotal')
disc_rows <- c('Bonus', 'Full House', 'SM Straight', 'LG Straight', 'Yahtzee')


# lowest/highest individuals and total games
range(apply(scores['GrandTotal',,], 2, sum))


# percentage of successes in Straights, Full House, etc.
getSuccessPcnts <- function(row) {
   getPcnt <- function(t, msg) {
      t <- table(t)
      cat(round(t[2] / sum(t) * 100, 1), '% - ', msg, '\n', sep='')
   }
   cat(row, '\n')
   getPcnt(scores[row,,], 'Overall')
   getPcnt(scores[row,'Julia',], 'Julia')
   getPcnt(scores[row,'Sam',], 'Sam')
   cat('\n')
}

for (row in disc_rows) {
   getSuccessPcnts(row)
}


# who has higher rate of win for each row?
apply(X = scores[cont_rows[cont_rows != 'Total2'],,],
      MARGIN = 1,
      FUN = function(row) {
         table(apply(X = row, 
                     MARGIN = 2, 
                     FUN = function(x) {
                        if (x[1] > x[2]) return('Julia')
                        if (x[1] < x[2]) return('Sam')
                        if (x[1] == x[2]) return('Tied')
                     }))
      })

apply(scores, 1)




# distribution of margins of wins/losses
# smallest/biggest margins
# average margins
jwins <- which(apply(scores['GrandTotal',,], 2, function(x) x[1] > x[2]))
mean(apply(scores['GrandTotal',,jwins], 2, diff))
mean(apply(scores['GrandTotal',,-jwins], 2, diff))


# histograms of values for 1s, 2s, 3s, ..., 3 of a Kind, etc.
# oddities: never yahtzee in 1s or Chance
apply(X = scores[cont_rows,,],
      MARGIN = 1,
      FUN = range)


# how predictive is upper bonus / straights / full house ??












