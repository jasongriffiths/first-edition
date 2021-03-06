## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Fit and run fixed and mixed effects effects Carlina stochastic IPM
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

rm(list=ls(all=TRUE))

library(doBy)
library(lme4)
library(MCMCglmm)
library(parallel)
library(rjags)
set.seed(53241986)

## Working directory must be set here, so the source()'s below run
root=ifelse(.Platform$OS.type=="windows","c:/repos","~/Repos"); 
setwd(paste(root,"/ipm_book/Rcode/c2",sep="")); 

source("../utilities/Standard Graphical Pars.R");

root=ifelse(.Platform$OS.type=="windows","c:/repos","~/Repos"); 
setwd(paste(root,"/ipm_book/Rcode/c7/Carlina",sep="")); 

#Read in the Carlina demographic data
load("CarlinaIBMsim.Rdata")
str(sim.data)

store.sim.data <- sim.data

#Select recruit data for the last 20 years (years 31 to 50)
recr.data <- subset(sim.data,Recr==1)
recr.data <- subset(recr.data,Yeart>30)
recr.data <- transform(recr.data,Yeart = factor(Yeart - 30))

#plant data for years 30 to 49, we do this to as the recruit size in 
#year t was generated by the year t-1 parameters
sim.data <- subset(sim.data,Yeart>29 & Yeart<50)
with(sim.data,table(Yeart,Recr))
#Make Yeart a factor
sim.data <- transform(sim.data,Yeart = factor(Yeart - 29))

#fit some survival models

mod.Surv <- glm(Surv ~ Yeart  , family = binomial, data = sim.data)
mod.Surv.1 <- glm(Surv ~ Yeart + z  , family = binomial, data = sim.data)
mod.Surv.2 <- glm(Surv ~ Yeart * z  , family = binomial, data = sim.data)

anova(mod.Surv,mod.Surv.1,mod.Surv.2,test="Chisq")
AIC(mod.Surv,mod.Surv.1,mod.Surv.2)

#there is evidence of an interaction, as we might expect as both the intercept and slope vary from 
#year to year

#Let's refit so we can easily get the parameter estimates

mod.Surv <- glm(Surv ~ Yeart/ z -1 , family = binomial, data = sim.data)

summary(mod.Surv)

#Let's refit using glmer

mod.Surv.glmer   <- glmer(Surv ~ 1 + (1|Yeart)  , family = binomial, data = sim.data)
mod.Surv.glmer.1 <- glmer(Surv ~ z + (1|Yeart)  , family = binomial, data = sim.data)
mod.Surv.glmer.2 <- glmer(Surv ~ z + (1|Yeart) + (0 + z|Yeart)  , family = binomial, data = sim.data)
mod.Surv.glmer.3 <- glmer(Surv ~ z + (z|Yeart)  , family = binomial, data = sim.data)
anova(mod.Surv.glmer,mod.Surv.glmer.1,mod.Surv.glmer.2,mod.Surv.glmer.3)


# # d<-1
# prior=list(R=list(V=1, fix=1), G=list(G1=list(V=diag(d), nu=d, alpha.mu=rep(0,d), alpha.V=diag(d)*1000)))

# mod.Surv.MCMC   <- MCMCglmm(Surv ~ 1, random=~Yeart  , family = "categorical", data = sim.data,
# slice=TRUE, pr=TRUE,prior=prior)

# mod.Surv.MCMC.1   <- MCMCglmm(Surv ~ z, random=~Yeart  , family = "categorical", data = sim.data,
# slice=TRUE, pr=TRUE,prior=prior)

# d<-2
# prior=list(R=list(V=1, fix=1), G=list(G1=list(V=diag(d), nu=d, alpha.mu=rep(0,d), alpha.V=diag(d)*1000)))

# mod.Surv.MCMC.2  <- MCMCglmm(Surv ~ z, random=~idh(1+z):Yeart  , family = "categorical", data = sim.data,
# slice=TRUE, pr=TRUE,prior=prior)

# mod.Surv.MCMC.3   <- MCMCglmm(Surv ~ z, random=~us(1+z):Yeart  , family = "categorical", data = sim.data,
# slice=TRUE, pr=TRUE,prior=prior)

# post.modes <- posterior.mode(mod.Surv.MCMC.2$Sol)

# intercepts.MCMC <- post.modes["(Intercept)"] + post.modes[3:22]

# slopes.MCMC <- post.modes["z"] + post.modes[23:42]

# par(mfrow=c(1,2),bty="l",pty="s",pch=19)

# plot(intercepts.MCMC,coef(mod.Surv.glmer.2)$Yeart[,"(Intercept)"])
# abline(0,1,col="red")
# plot(slopes.MCMC,coef(mod.Surv.glmer.2)$Yeart[,"z"])
# abline(0,1,col="red")


#fit some flowering models

flow.data <- subset(sim.data,Surv==1)

mod.Flow <- glm(Flow ~ Yeart  , family = binomial, data = flow.data)
mod.Flow.1 <- glm(Flow ~ Yeart + z  , family = binomial, data = flow.data)
mod.Flow.2 <- glm(Flow ~ Yeart * z  , family = binomial, data = flow.data)

anova(mod.Flow,mod.Flow.1,mod.Flow.2,test="Chisq")
AIC(mod.Flow,mod.Flow.1,mod.Flow.2)

#No interaction term, as expected, refit to get paramter estimates easily

mod.Flow <- glm(Flow ~ Yeart + z -1 , family = binomial, data = flow.data)

#Let's refit using glmer

mod.Flow.glmer   <- glmer(Flow ~ 1 + (1|Yeart)  , family = binomial, data = flow.data)
mod.Flow.glmer.1 <- glmer(Flow ~ z + (1|Yeart)  , family = binomial, data = flow.data)
mod.Flow.glmer.2 <- glmer(Flow ~ z + (1|Yeart) + (0 + z|Yeart)  , family = binomial, data = flow.data)
mod.Flow.glmer.3 <- glmer(Flow ~ z + (z|Yeart)  , family = binomial, data = flow.data)
anova(mod.Flow.glmer,mod.Flow.glmer.1,mod.Flow.glmer.2,mod.Flow.glmer.3)

#fit some growth models

grow.data <- subset(sim.data,Surv==1 & Flow==0)

mod.Grow <- lm(z1 ~ Yeart  , data = grow.data)
mod.Grow.1 <- lm(z1 ~ Yeart +z , data = grow.data)
mod.Grow.2 <- lm(z1 ~ Yeart *z , data = grow.data)

anova(mod.Grow,mod.Grow.1,mod.Grow.2)
AIC(mod.Grow,mod.Grow.1,mod.Grow.2)

mod.Grow <- lm(z1 ~ Yeart/z-1  , data = grow.data)

#Let's refit using lmer

mod.Grow.lmer   <- lmer(z1 ~ 1 + (1|Yeart)  ,  data = grow.data, REML=FALSE)
mod.Grow.lmer.1 <- lmer(z1 ~ z + (1|Yeart)  ,  data = grow.data, REML=FALSE)
mod.Grow.lmer.2 <- lmer(z1 ~ z + (1|Yeart) + (0 + z|Yeart)  ,  data = grow.data, REML=FALSE)
mod.Grow.lmer.3 <- lmer(z1 ~ z + (z|Yeart)  ,  data = grow.data, REML=FALSE)
anova(mod.Grow.lmer,mod.Grow.lmer.1,mod.Grow.lmer.2,mod.Grow.lmer.3)

#fit some recruit size models

mod.Rcsz <- lm(z ~ 1  , data = recr.data)
mod.Rcsz.1 <- lm(z ~ Yeart , data = recr.data)

anova(mod.Rcsz,mod.Rcsz.1)
AIC(mod.Rcsz,mod.Rcsz.1)

mod.Rcsz <- lm(z ~ Yeart -1, data = recr.data)

#Let's refit using lmer

mod.Rcsz.lmer <- lmer(z ~ 1 + (1|Yeart) , data = recr.data)

#quick check

plot(as.numeric(coef(mod.Rcsz)),unlist(coef(mod.Rcsz.lmer)$Yeart))
abline(0,1)

#set up parameter vector with yearly estimates from fixed effects models (lm and glm)
m.par.est <- matrix(NA,nrow=12,ncol=20)
m.par.est[1,] <- coef(mod.Surv)[1:20]
m.par.est[2,] <- coef(mod.Surv)[21:40]
m.par.est[3,] <- coef(mod.Flow)[1:20]
m.par.est[4,] <- coef(mod.Flow)[21]
m.par.est[5,] <- coef(mod.Grow)[1:20]
m.par.est[6,] <- coef(mod.Grow)[21:40]
m.par.est[7,] <- summary(mod.Grow)$sigma
m.par.est[8,] <- coef(mod.Rcsz)[1:20]
m.par.est[9,] <- summary(mod.Rcsz)$sigma
m.par.est[10,] <- 1
m.par.est[11,] <- 2
m.par.est[12,] <- 0.00095

#set up parameter vector with yearly estimates from mixed effects models (lmer and glmer)
m.par.est.mm <- matrix(NA,nrow=12,ncol=20)
m.par.est.mm[1,] <- as.vector(unlist(coef(mod.Surv.glmer.2 )$Yeart["(Intercept)"]))
m.par.est.mm[2,] <- as.vector(unlist(coef(mod.Surv.glmer.2 )$Yeart["z"]))
m.par.est.mm[3,] <- as.vector(unlist(coef(mod.Flow.glmer.1 )$Yeart["(Intercept)"]))
m.par.est.mm[4,] <- as.vector(unlist(coef(mod.Flow.glmer.1 )$Yeart["z"]))
m.par.est.mm[5,] <- as.vector(unlist(coef(mod.Grow.lmer.2)$Yeart["(Intercept)"]))
m.par.est.mm[6,] <- as.vector(unlist(coef(mod.Grow.lmer.2)$Yeart["z"]))
m.par.est.mm[7,] <- as.vector(unlist(summary(mod.Grow.lmer.2)$sigma))
m.par.est.mm[8,] <- as.vector(unlist(coef(mod.Rcsz.lmer)$Yeart["(Intercept)"]))
m.par.est.mm[9,] <- as.vector(unlist(summary(mod.Rcsz.lmer)$sigma))
m.par.est.mm[10,] <- 1
m.par.est.mm[11,] <- 2
m.par.est.mm[12,] <- 0.00095

plot(m.par.est,m.par.est.mm)

source("Carlina Demog Funs DI.R") 

rownames(m.par.est) <- names(m.par.true)
rownames(m.par.est.mm) <- names(m.par.true)

save(m.par.est,m.par.est.mm,file="Yearly parameters.Rdata")

#test correlations between yearly parameters
cor.test(m.par.est[1,],m.par.est[3,])
cor.test(m.par.est[1,],m.par.est[5,])
cor.test(m.par.est[1,],m.par.est[8,])

cor.test(m.par.est[3,],m.par.est[5,])
cor.test(m.par.est[3,],m.par.est[8,])

cor.test(m.par.est["grow.int",],m.par.est["rcsz.int",])
plot(m.par.est["grow.int",],m.par.est["rcsz.int",])
   
#####################################################################
#Run stochastic fixed effects IPM
#####################################################################

iterate_model<-function(params,n.years,n.est) {

#Construct the yearly kernels

	K.year.i <- array(NA,c(n.years,nBigMatrix,nBigMatrix))
	
	for(i in 1:n.years){
		year.K<-mk_K(nBigMatrix,params[,i],minsize,maxsize)
		K.year.i[i,,] <- year.K$K
	}
    h <- year.K$h; 

#Calculate mean kernel, v and w

	mean.kernel <- apply(K.year.i,2:3,mean)
	
	w <- Re(eigen(mean.kernel)$vectors[,1]); 
	v <- Re(eigen(t(mean.kernel))$vectors[,1]);

	# scale eigenvectors <v,w>=1 
	w <- abs(w)/sum(h*abs(w))
	v <- abs(v)
	v <- v/(h*sum(v*w))
    cat(h*sum(v*w)," should = 1","\n")
	
	v.Ktw <- rep(NA,n.years)
	
	for(i in 1:n.years) {
		v.Ktw[i] <- sum(v*(K.year.i[i,,] %*% w))*h
	}
 
#initialize variables	

	nt<-rep(1/nBigMatrix,nBigMatrix)
	rt.V <- rt.N <- rep(NA,n.est)
	size.dist<-rep(0,nBigMatrix)
	size.dist.fl<-rep(0,nBigMatrix)

#Iterate model

	for (year.t in 1:n.est){
		if(year.t%%10000==0) cat("iterate: ", year.t,"\n");

		#Select year at random
		
		year.i <- sample(1:n.years,1)
		
		#iterate model with year-specific kernel
		nt1<-K.year.i[year.i,,] %*% nt
	
		sum.nt1<-sum(nt1)
		
		#Calculate log growth rates  
		
		rt.V[year.t] <- log(sum(nt1*v)/sum(nt*v))
		rt.N[year.t] <- log(sum(nt1)/sum(nt))
			
		#distribution of flowering plant sizes in year t
		dist.fl.year <- nt * s_z(year.K$meshpts,params[,year.i]) * p_bz(year.K$meshpts,params[,year.i])

		#distribution of plant sizes in year t
		size.dist <- size.dist + nt

		
		size.dist.fl<-size.dist.fl+dist.fl.year

		nt <- nt1 / sum.nt1  
		
		# cat(Rt[year.t],"  ",sum.nt,"\n")
		
				
	}

   	size.dist <- size.dist / sum(size.dist)
	size.dist.fl <- size.dist.fl / sum(size.dist.fl)
	
	return(list(size.dist=size.dist,size.dist.fl=size.dist.fl,
		    rt.N=rt.N,rt.V=rt.V,meshpts=year.K$meshpts,
		    mean.kernel=mean.kernel,v.Ktw=v.Ktw))
}

nBigMatrix <- 100
n.est <- 20000
n.runin <- 500
minsize <- 1.5
maxsize <- 5

iter <- iterate_model(m.par.est,20,n.est)

rt.N <- iter$rt.N;
rt.V <- iter$rt.V; 

Ls.Nt <- mean(rt.N)
SE.Ls.Nt <- sqrt(var(rt.N)/length(rt.N))
acf(rt.N,plot=FALSE)$acf[2:5];

Ls.Vt <- mean(rt.V)
SE.Ls.Vt <- sqrt(var(rt.V)/length(rt.V))
acf(rt.V,plot=FALSE)$acf[2:5];

cat("log Lambda S using Nt ",Ls.Nt," 95% c.i ",Ls.Nt+2*SE.Ls.Nt," ",Ls.Nt-2*SE.Ls.Nt,"\n")
cat("log Lambda S using Vt ",Ls.Vt," 95% c.i ",Ls.Vt+2*SE.Ls.Vt," ",Ls.Nt-2*SE.Ls.Vt,"\n")

lam.1 <- Re(eigen(iter$mean.kernel)$values[1])

var.v.Ktw <- var(iter$v.Ktw)

approx.Ls <- log(lam.1) - var.v.Ktw/(2*lam.1*lam.1)

cat("SFA Stochastic log Lambda = ",approx.Ls,"\n")

n.est <- 500000

iter <- iterate_model(m.par.est,20,n.est)

rt.N <- iter$rt.N;
rt.V <- iter$rt.V; 

Ls.Nt <- mean(rt.N)
SE.Ls.Nt <- sqrt(var(rt.N)/length(rt.N))
acf(rt.N,plot=FALSE)$acf[2:5];

Ls.Vt <- mean(rt.V)
SE.Ls.Vt <- sqrt(var(rt.V)/length(rt.V))
acf(rt.V,plot=FALSE)$acf[2:5];

cat("log Lambda S using Nt ",Ls.Nt," 95% c.i ",Ls.Nt+2*SE.Ls.Nt," ",Ls.Nt-2*SE.Ls.Nt,"\n")
cat("log Lambda S using Vt ",Ls.Vt," 95% c.i ",Ls.Vt+2*SE.Ls.Vt," ",Ls.Vt-2*SE.Ls.Vt,"\n")


#well that's not too bad 

#how fast do they converge?

Ls.N <- cumsum(rt.N)/(1:n.est)
Ls.V <- cumsum(rt.V)/(1:n.est)

n.samp <- n.est

plot(Ls.N[1:n.samp],type="l")
points(Ls.V[1:n.samp],type="l",col="red")
abline(h=mean(rt.N))


#what about log(V(t+1)) being approximately independent of log(V(t))?
dev.new(height=4,width=8);
set_graph_pars("panel2");

pacf(rt.N,lag.max=10,ylim=c(-0.1,0.1),main="")
add_panel_label("a")
pacf(rt.V,lag.max=10,ylim=c(-0.1,0.1),main="")
add_panel_label("b")

#dev.copy2eps(file="~/Repos/ipm_book/c7/figures/logVtRandomWalk.eps")
#the answer seems yes it but so is Nt pretty much.

#let's do the same again using the mixed model posterior modes

iter <- iterate_model(m.par.est.mm,20,n.est)

rt.N <- iter$rt.N;
rt.V <- iter$rt.V; 

Ls.Nt <- mean(rt.N)
SE.Ls.Nt <- sqrt(var(rt.N)/length(rt.N))
acf(rt.N,plot=FALSE)$acf[2:5];

Ls.Vt <- mean(rt.V)
SE.Ls.Vt <- sqrt(var(rt.V)/length(rt.V))
acf(rt.V,plot=FALSE)$acf[2:5];

cat("Lambda S using Nt ",Ls.Nt," 95% c.i ",Ls.Nt+2*SE.Ls.Nt," ",Ls.Nt-2*SE.Ls.Nt,"\n")
cat("Lambda S using Vt ",Ls.Vt," 95% c.i ",Ls.Vt+2*SE.Ls.Vt," ",Ls.Vt-2*SE.Ls.Vt,"\n")

lam.1 <- Re(eigen(iter$mean.kernel)$values[1])

var.v.Ktw <- var(iter$v.Ktw)

approx.Ls <- log(lam.1) - var.v.Ktw/(2*lam.1*lam.1)

cat("Stochastic Lambda = ",mean(rt.N),"   approx=",approx.Ls,"\n")

#well that's not too bad 
#what about log(V(t+1)) being approximately independent of log(V(t))?

par(mfrow=c(1,2),pty="s",bty="l")

pacf(rt.N,lag.max=10,ylim=c(-0.1,0.1))

pacf(rt.V,lag.max=10,ylim=c(-0.1,0.1))

#the answer seems yes it but so is Nt pretty much.




