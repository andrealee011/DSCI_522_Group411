# authors: Katie Birchard, Ryan Homer, Andrea Lee
# date: 2020-01-18
# Rscript src/render_EDA.R --datafile=data/train.feather --out=doc
"Create and save exploratory data analysis figures.

Usage: render_EDA.R --datafile=<path to the dataset> --out=<path to output directory>

Options:
<datafile>      Complete URL to the dataset.
<out> The destination path to save the EDA figures.
" -> doc

suppressMessages(library(docopt))
suppressMessages(library(tidyverse))
suppressMessages(library(lubridate))
suppressMessages(library(caret))
suppressMessages(library(knitr))
suppressMessages(library(ggpubr))
suppressMessages(library(feather))
suppressMessages(library(kableExtra))

main <- function(args) {
  check_args(args)
  make_plot(args$datafile, args$out)
  make_table(args$datafile, args$out)
}

check_args <- function(args) {
  if (!file.exists(path.expand(args$datafile))) {
    stop("Unable to find datafile.")
  }
  
  # make sure path exists
  if (!dir.exists(path.expand(args$out))) {
    dir.create(path.expand(args$out), recursive = TRUE)
  }
}

make_plot <- function(datafile, out) {
  dest_path <- path.expand(out)
  
  # Read in data
  avocado <- read_feather(datafile)
  
  ### What is the average avocado price per region?
  avocado_by_region <- avocado %>%
    group_by(region) %>%
    summarize(ave_price = mean(average_price))
  
  # There are many regions here, so it might make sense to group them
  price_per_region <- ggplot(avocado, aes(x=reorder(region, -average_price), y=average_price)) +
    geom_boxplot(alpha=0.1) +
    geom_point(aes(x=reorder(region, -ave_price), y=ave_price, colour="red"),
               data=avocado_by_region) +
    xlab("Regions") +
    ylab("Average Price ($)") +
    ggtitle("Avocado Price by Region") +
    scale_colour_manual(values=c("red"),
                        breaks=c("red"),
                        labels=c("Mean"),
                        name=c("")) +
    theme_bw() +
    theme(axis.text.x = element_text(angle=90, size = 8),
          axis.title.x = element_blank()) 
  
  # What is the average avocado price by type (organic vs. non-organic)
  avocado_by_type <- avocado %>%
    group_by(type) %>%
    summarize(ave_price = mean(average_price))
  
  price_per_type <- ggplot(avocado, aes(x=reorder(type, -average_price), y=average_price)) +
    geom_boxplot(alpha=0.2) +
    geom_point(aes(x=reorder(type, -ave_price), y=ave_price, colour="red"),
               data=avocado_by_type) +
    xlab("Type") +
    ylab("Average Price ($)") +
    ggtitle("Avocado Price by Type") +
    scale_colour_manual(values=c("red"),
                        breaks=c("red"),
                        labels=c("Mean"),
                        name=c("")) +
    theme_bw() +
    theme(axis.title.x = element_blank())
  
  # What is the average price per month?
  avocado_by_month <- avocado %>%
    group_by(month) %>%
    summarize(ave_price = mean(average_price))
  
  price_per_month <- ggplot(avocado, aes(x=month, y=average_price)) +
    geom_boxplot(alpha=0.2) +
    geom_point(aes(x=month, y=ave_price, colour="red"),
               data=avocado_by_month) +
    xlab("Month") +
    ylab("Average Price ($)") +
    ggtitle("Avocado Price by Month") +
    scale_colour_manual(values=c("red"),
                        breaks=c("red"),
                        labels=c("Mean"),
                        name=c("")) +
    theme_bw() +
    theme(axis.title.x = element_blank(),
          legend.position = "right")
  
  plot <- gridExtra::arrangeGrob(price_per_region, price_per_type,
                          price_per_month,
                          ncol=1, nrow=3)

  ggsave('EDA_plot.png',  plot, path = file.path(dest_path))
  
  # What is the average price over time?
  year_plot <- avocado %>%
    group_by(year_month) %>%
    summarize(average_price = mean(average_price)) %>%
    ggplot(aes(x=year_month, y=average_price)) +
    geom_point(alpha=0.5, colour="darkblue") +
    xlab("Year-Month") +
    ylab("Average Price") +
    #ggtitle("Average Avocado Price Over Time") +
    theme_bw() +
    theme(axis.text.x = element_text(angle=90)) 
  
  ggsave('EDA_year_plot.png',  year_plot, path = file.path(dest_path))
}

make_table <- function(datafile, out) {
  dest_path <- path.expand(out)
  
  # Read in data
  avocado <- read_feather(datafile)
  
  # What is the distribution of the different categorical features?
  region_summary <- avocado %>%
    count(region)
  region_summary <- avocado %>%
    group_by(region) %>%
    summarize(min = min(average_price),
              lower_quartile = quantile(average_price, 0.25),
              mean = mean(average_price),
              median = median(average_price),
              upper_quantile = quantile(average_price, 0.75),
              max = max(average_price))  %>%
    left_join(region_summary)
    region_summary_table <- kable(region_summary,
                                caption = "Table 1. Summary statistics for the average price of avocados in all regions in the United States.") %>% 
                          as_image(file = file.path(dest_path, 'EDA_region_table.png'))
  
  type_summary <- avocado %>%
    count(type)
    type_summary <- avocado %>%
    group_by(type) %>%
    summarize(min = min(average_price),
              lower_quartile = quantile(average_price, 0.25),
              mean = mean(average_price),
              median = median(average_price),
              upper_quantile = quantile(average_price, 0.75),
              max = max(average_price))  %>%
    left_join(type_summary)
    type_summary_table <- kable(type_summary, 
                              caption = "Table 2. Summary statistics for the average price of avocados for organic and non-organic avocados.") %>% 
                        as_image(file = file.path(dest_path, 'EDA_type_table.png'))
  
  month_summary <- avocado %>%
    count(month)
  month_summary <- avocado %>%
    group_by(month) %>%
    summarize(min = min(average_price),
              lower_quartile = quantile(average_price, 0.25),
              mean = mean(average_price),
              median = median(average_price),
              upper_quantile = quantile(average_price, 0.75),
              max = max(average_price))  %>%
    left_join(month_summary)
    month_summary_table <- kable(month_summary, 
                               caption = "Table 3. Summary statistics for the average price of avocados for each month of the year.") %>% 
                         as_image(file = file.path(dest_path, 'EDA_month_table.png'))
}

main(docopt(doc))