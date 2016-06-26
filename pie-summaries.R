library(dplyr)
library(ggplot2)

lowerCI <- function(v) {
	mean(v) - sd(v)*1.96/sqrt(length(v))
}

upperCI <- function(v) {
	mean(v) + sd(v)*1.96/sqrt(length(v))
}

plotCIs <- function(dataFrame, x_variable, y_variable, label, zeroLine=FALSE) {
	p <- ggplot(dataFrame, aes(x=x_variable, fill=x_variable, y=y_variable))
	if (zeroLine) {
		p <- p + geom_hline(yintercept=0, linetype="dotted")
	}
	p <- p +
		stat_summary(fun.ymin=lowerCI, fun.ymax=upperCI, geom="errorbar", aes(width=.1)) +
		stat_summary(fun.y=mean, geom="point", shape=18, size=3, show.legend = FALSE) + 
		labs(x = NULL, y = label)
	print(p)
}

setwd("~/Documents/src/pie-summaries")

# data was reshaped in Google Sheets, and opposite answer corrections were calculated here: https://docs.google.com/spreadsheets/d/1ykUK7l82OZAMIvE8jHLjqYt6GmsKuTl934qqgxZ2faE/edit?usp=sharing
# aaa = arcs angles areas
aaa <- read.csv("data/arcs-angles-areas-merged.csv") %>%
	mutate(chart_type = factor(chart_type,
							   levels=c('Pie Chart', 'Donut Chart', 'Arc-Length Chart',  'Area Chart', 'Pie Angle Chart', 'Donut Angle Chart'),
							   labels=c('Pie Chart', 'Donut Chart', 'Arc-Length',  'Area Only', 'Angle Only', 'Angle Only Donut')),
		   judged_true_corrected = ifelse(log_error == log_opposite, judged_true, (100-ans_trial)-correct_ans)
	)

aaaAggregated <- aaa %>%
	group_by(chart_type, subjectID) %>%
	summarize(meanError = mean(judged_true_corrected),
			  meanAbsError = mean(abs(judged_true_corrected)))

aaaPies <- aaaAggregated %>%
	filter(chart_type == "Pie Chart") %>%
	select(subjectID,
		   pie_meanError = meanError,
		   pie_meanAbsError = meanAbsError,
		   chartPie = chart_type) # since we can't seem to get rid of the chart_type column

aaaJoined <- left_join(aaaPies, aaaAggregated) %>%
	mutate(pieDifferenceMeanError = meanError-pie_meanError,
		   pieDifferenceMeanAbsError = meanAbsError-pie_meanAbsError)

plotCIs(aaaAggregated, aaaAggregated$chart_type, aaaAggregated$meanError, "Error (Bias)", TRUE)

plotCIs(aaaAggregated, aaaAggregated$chart_type, aaaAggregated$meanAbsError, "Absolute Error (Precision)")

plotCIs(aaaJoined, aaaJoined$chart_type, aaaJoined$pieDifferenceMeanError, "Error relative to Pie (Bias)", TRUE)

plotCIs(aaaJoined, aaaJoined$chart_type, aaaJoined$pieDifferenceMeanAbsError, "Absolute Error relative to Pie (Precision)", TRUE)


#
#
# donut inner radii
donuts <- read.csv("data/donut-radii-merged.csv") %>%
	mutate(inner_radius = factor(inner_radius))

# get the average result for condition 1 per subject
donutsAggregated <- donuts %>%
	group_by(inner_radius, subjectID) %>%
	summarize(meanError = mean(judged_true),
			  meanAbsError = mean(abs(judged_true)))

donuts0radius <- donutsAggregated %>%
	filter(inner_radius == 0) %>%
	rename(pie_meanError = meanError,
		   pie_meanAbsError = meanAbsError,
		   r0 = inner_radius)

donutsJoined <- left_join(donuts0radius, donutsAggregated) %>%
	mutate(pieDifferenceMeanError = meanError-pie_meanError,
		   pieDifferenceMeanAbsError = meanAbsError-pie_meanAbsError)

plotCIs(donutsAggregated, donutsAggregated$inner_radius, donutsAggregated$meanError, "Error (Bias)", TRUE)

plotCIs(donutsAggregated, donutsAggregated$inner_radius, donutsAggregated$meanAbsError, "Absolute Error (Precision)")

plotCIs(donutsJoined, donutsJoined$inner_radius, donutsJoined$pieDifferenceMeanError, "Error relative to Pie (Bias)", TRUE)

plotCIs(donutsJoined, donutsJoined$inner_radius, donutsJoined$pieDifferenceMeanAbsError, "Absolute Error relative to Pie (Precision)", TRUE)

#
#
# pie-variations variations
variations <- read.csv("data/pie-variations-enriched.csv")

variationsFiltered <- variations %>%
	filter(workerID != "QV69HK91") %>% # filter out the guy who answered in degress rather than percent
	mutate(chart.type = factor(chart.type,
							   levels=c('pie', 'outerRadius', 'exploded',  'square', 'ellipse'),
							   labels=c('Pie', 'Larger Slice', 'Exploded', 'Square', 'Ellipse')),
		   absError = abs(judged.true),
		   opposite = (abs(opposite.ans-correct.ans) < absError) & (abs(50-correct.ans) > 5))

variationsAggregated <- variationsFiltered %>%
	group_by(chart.type, workerID) %>%
	summarize(meanError = mean(judged.true),
			  ci95Error = sd(judged.true)*1.96/sqrt(n()),
			  meanAbsError = mean(abs(judged.true)),
			  ci95AbsError = sd(abs(judged.true))*1.96/sqrt(n())
	)

# Only pick pie charts
pieChartsOnly <- variationsAggregated %>%
	filter(chart.type == "Pie") %>%
	select(workerID,
		   pie_meanError = meanError,
		   pie_meanAbsError = meanAbsError,
		   chartPie = chart.type) # since we can't seem to get rid of the chart.type column

# join pieChartsOnly back in to calculate difference from pie error per person
variationsJoined <- left_join(pieChartsOnly, variationsAggregated, by=c("workerID")) %>%
	mutate(
		pieDifferenceMeanError = meanError-pie_meanError,
		pieDifferenceMeanAbsError = meanAbsError-pie_meanAbsError)

plotCIs(variationsAggregated, variationsAggregated$chart.type, variationsAggregated$meanError, "Error (Bias)", TRUE)

plotCIs(variationsAggregated, variationsAggregated$chart.type, variationsAggregated$meanAbsError, "Absolute Error (Precision)")

plotCIs(variationsJoined, variationsJoined$chart.type, variationsJoined$pieDifferenceMeanError, "Error relative to Pie (Bias)", TRUE)

plotCIs(variationsJoined, variationsJoined$chart.type, variationsJoined$pieDifferenceMeanAbsError, "Absolute Error relative to Pie (Precision)", TRUE)

