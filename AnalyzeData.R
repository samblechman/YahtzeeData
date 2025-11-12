

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


# Does the data follow a geometric distribution?
source('~/Desktop/WrightLab/UsefulRfuncs/newBarplotFxn.R')

trials <- apply(scores['GrandTotal',,], 2, function(x) {
   if (x[1] > x[2]) return(1)
   if (x[2] > x[1]) return(0)
   if (x[1] == x[2]) return(NA)
})
trials <- trials[!is.na(trials)]
trials

# observed win rate
prob <- sum(trials) / length(trials)

# expected distribution of losses between wins
x <- 0:8
exp_loss_strk_lens <- dgeom(x=x, prob=prob) * sum(trials == 1L)

# observed distribution of lossess between wins
rl <- rle(trials)
obs_loss_strk_lens_raw <- rl$lengths[rl$values == 0L]
range(obs_loss_strk_lens_raw) # 1, 8 (what about 0 losses???)
y <- rl$lengths[rl$values == 1L] - 1
obs_loss_strk_lens_raw <- c(obs_loss_strk_lens_raw, rep(0, sum(y[y > 0L])))
obs_loss_strk_lens <- sapply(x, function(v) sum(obs_loss_strk_lens_raw == v))

loss_str_mat <- t(cbind(obs_loss_strk_lens, exp_loss_strk_lens))
rownames(loss_str_mat) <- c('observed', 'expected')
# Calculate chi-squared goodness of fit statistic
# sum[ (O - E)^2 / E ]
chi_sq_stat <- sum((obs_loss_strk_lens - exp_loss_strk_lens)^2 / exp_loss_strk_lens)
deg_fr <- (nrow(loss_str_mat)-1) * (ncol(loss_str_mat)-1)
pval <- pchisq(q=chi_sq_stat, df=deg_fr)


par(mfrow=c(1,1), tck=-0.01, mgp=c(2, 0.5, 0), mar=c(4,3,2,1))
b <- barplot(loss_str_mat, beside=TRUE, yaxt='n', legend=TRUE)
axis(side=1, at=apply(b,2,mean), labels=x, line=0.5)
axis(side=2, las=1)
text(x=b[length(b)], y=max(loss_str_mat)*seq(0.82, 0.75, length.out=3L), labels=paste0(c('Chi-squared statistic = ', 'degrees of freedom = ', 'p-value = '), round(c(chi_sq_stat, deg_fr, pval), 2)), adj=1)








# verify the current record: (Julia wins - Sam wins - ties)
table(apply(scores['GrandTotal',,], 2, function(x) {
   if (x[1] > x[2]) return('Julia')
   if (x[2] > x[1]) return('Sam')
   if (x[1] == x[2]) return('Tied')
   return('??')
}))


# plot wins matrix
x <- as.vector(sign(diff(scores['GrandTotal',,]))) # -1 is Julia, 1 is me, 0 is tied

{
   pdf(file = 'plots/wins_matrix.pdf')
   par(mar=c(4,4,2,1), mgp=c(1.75, 0.3, 0), tck=-0.01)
   plot(NA, xlim=c(-0.5, 110), ylim=c(-0.5, 110), xlab='Sam wins', ylab='', xaxs='i', yaxs='i', yaxt='n')
   axis(side=2, las=1)
   title(ylab='Jul wins', line=2.5)
   abline(v=0:110-0.5, h=0:110-0.5, col='#00000066', lwd=0.25)
   abline(a=0, b=1, lty='41', lwd=2)
   
   xpos <- 0
   ypos <- 0
   for (g in 1:dim(scores)[3]) {
      if (x[g] == -1) {
         ypos <- ypos + 1
      } else if (x[g] == 1) {
         xpos <- xpos + 1
      }
      points(x=xpos, y=ypos, pch=15, cex=0.75)
   }
   dev.off()
}




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












