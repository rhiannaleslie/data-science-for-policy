#clustering algorithm

get_cluster_partitions <- function(data, group_col, cluster_num) {
  group_col <- sym(group_col)
  
  features <- data %>%
    select(-all_of(group_col))
  
  # Scale features 
  features_scaled <- as.data.frame(lapply(features, function(x) {
    2 * (x - min(x)) / (max(x) - min(x)) - 1
  }))
  
  # Run kmeans
  km <- kmeans(features_scaled, centers = cluster_num, algorithm = "Lloyd", iter.max = 100L)
  
  # Silhouette score
  sil <- cluster::silhouette(km$cluster, dist(features_scaled))
  sil_score <- mean(sil[, 3])
  
  # Silhouette plot
  sil_plot <- factoextra::fviz_silhouette(sil)
  
  # Add partitions back to data
  partitioned_data <- data %>%
    dplyr::mutate(partition = km$cluster) %>%
    tidyr::pivot_longer(cols = contains("20"),
                        names_to = "month",
                        values_to = "perc_change") %>%
    dplyr::left_join(date_lookup, by = c("month"))
  
  return(list("data" = partitioned_data,
              "score" = sil_score,
              "sil_plot" = sil_plot))
}


clustering_visualisation <- function(cluster_data, group_col, lab){
  
  group_col <- sym(group_col)
  
  plot_data <- split(cluster_data, f = cluster_data$partition)
  
  for (each_cluster in 1:length(plot_data)) {
    
    p <- ggplot(data = plot_data[[each_cluster]]) +
      geom_line(aes(y = perc_change, x = date, colour = !!group_col)) +
      theme_bw() +
      facet_wrap(~partition) +
      labs(x = "Date",
           y = "12 month percentage change",
           colour = paste0(lab, " in cluster")) +
      guides(colour = guide_legend(ncol =  1)) +
      scale_y_continuous(limits = c(min(cluster_data$perc_change), max(cluster_data$perc_change))) +
      theme(legend.text = element_text(size = 14),
            legend.title = element_text(size = 16),
            legend.position = "right",
            axis.title = element_text(size = 16),
            axis.text.x = element_text(size = 14),
            axis.text.y = element_text(size = 14),
            strip.text = element_text(size = 18))
    
    ggsave(paste0("outputs/", lab, each_cluster,".png"),
           height = 10,
           width = 15)
    
  }
  
  
}


  