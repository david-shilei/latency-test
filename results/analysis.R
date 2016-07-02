args <- commandArgs(trailingOnly = TRUE)
print(args)

csv_file <- args[1]
d <- read.csv(file=csv_file, sep=",")
metrics <- setNames(d, c("Time", "Latency"))

png(paste(csv_file, "png", sep="."))

par(mfrow=c(1,2))
plot(metrics$Latency, main="Ping Analysis")
boxplot(metrics$Latency)

dev.off()
