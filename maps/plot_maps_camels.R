
plot_map_catch_attr<-function(dat,c2p,n_classes=6,col_scheme='RdYlBu',col_rev=FALSE,color_bar=TRUE,subplot_hist=TRUE,
                              col_trans=0,b_round=2,text_legend='',cex=1,pch=16,qual=FALSE,
                              force_zero_center=FALSE,force_n_classes=FALSE,set_breaks=FALSE,breaks=NA){

  # arguments:
  # dat: data as data.frame
  # c2p: columns to use for plotting

  if(colnames(dat)[1]!='gauge_id'){stop('First column of dat must be gauge_id')}
  if(!length(col_scheme)%in%c(1,length(c2p))){stop('col_scheme must have either 1 or length(c2p) elements')}
  if(!length(b_round)%in%c(1,length(c2p))){stop('b_round must have either 1 or length(c2p) elements')}
  if(!length(col_rev)%in%c(1,length(c2p))){stop('col_rev must have either 1 or length(c2p) elements')}
  if(!length(qual)%in%c(1,length(c2p))){stop('qual must have either 1 or length(c2p) elements')}
  if(!length(subplot_hist)%in%c(1,length(c2p))){stop('subplot_hist must have either 1 or length(c2p) elements')}
  if(!length(set_breaks)%in%c(1,length(c2p))){stop('set_breaks must have either 1 or length(c2p) elements')}
  if(!length(breaks)%in%c(1,length(c2p))){stop('breaks must have either 1 or length(c2p) elements')}

  for (v in c2p){

    my_col_scheme<-ifelse(length(col_scheme)==length(c2p),col_scheme[v==c2p],col_scheme)
    my_b_round<-ifelse(length(b_round)==length(c2p),b_round[v==c2p],b_round)
    my_col_rev<-ifelse(length(col_rev)==length(c2p),col_rev[v==c2p],col_rev)
    my_qual<-ifelse(length(qual)==length(c2p),qual[v==c2p],qual)
    my_subplot_hist<-ifelse(length(subplot_hist)==length(c2p),subplot_hist[v==c2p],subplot_hist)
    my_force_zero_center<-ifelse(length(force_zero_center)==length(c2p),force_zero_center[v==c2p],force_zero_center)
    my_force_n_classes<-ifelse(length(force_n_classes)==length(c2p),force_n_classes[v==c2p],force_n_classes)
    my_set_breaks<-ifelse(length(set_breaks)==length(c2p),set_breaks[v==c2p],set_breaks)

    if(length(breaks)==length(c2p)){ # if loop is necessary because ifelse only returns one element

      if(length(which(v==c2p))>1){
        stop('The same column is used twice')
      }

      my_breaks<-breaks[[which(v==c2p)]]
    }else{
      my_breaks<-breaks
    }

    plot_points_us_basins(dat[,c(1,v)],n_classes,col_scheme=my_col_scheme,col_rev=my_col_rev,color_bar,
                          subplot_hist=my_subplot_hist,col_trans,b_round=my_b_round,text_legend=colnames(dat)[v],
                          cex,pch,qual=my_qual,force_zero_center=my_force_zero_center,force_n_classes=my_force_n_classes,
                          set_breaks=my_set_breaks,breaks=my_breaks)

  }

}

plot_points_us_basins<-function(dat,n_classes=6,col_scheme='RdYlBu',col_rev=FALSE,color_bar=TRUE,
                                subplot_hist=TRUE,col_trans=0,b_round=2,text_legend='',cex=1,pch=16,qual=FALSE,
                                force_zero_center=FALSE,force_n_classes=FALSE,
                                set_breaks=FALSE,breaks=NA){

  # input variables:
  # dat: matrix with two columns: catchment id (must be named 'gauge_id') and variable to plot
  # n_classes: number of color classes (even number suggested)
  # col_scheme: http://colorbrewer2.org/ color scheme - RdYlBu: red to blue - BrBG: green to brown - PRGn: purple to green
  # col_rev: reverse the color scheme?
  # col_trans: use transparent colors (0 is opaque 255 is transparent)
  # b_round: number of decimals to keep for the break values
  # text_legend: text to add above the color bar
  # qual: is the information qualitative (e.g. vegetation classes)

  if(!exists('camels_topo')){

    load(paste(dir_catch_attr,'camels_topo.Rdata',sep=''))

  }

  dat2plot<-merge(dat,camels_topo,by='gauge_id')

  if(dim(dat2plot)[1]==0){stop('Merge with topo failed, check gauge_id')}

  plot_points_us(x=dat2plot$gauge_lon,y=dat2plot$gauge_lat,z=dat2plot[,2],n_classes,col_scheme,col_rev,color_bar,subplot_hist,
                 col_trans,b_round,text_legend,cex,pch,qual,force_zero_center,force_n_classes,set_breaks,breaks)

}

### PLOT POINTS ON US MAP

plot_points_us<-function(x,y,z,n_classes=6,col_scheme='RdYlBu',col_rev=FALSE,color_bar=TRUE,subplot_hist=TRUE,
                         col_trans=0,b_round=2,text_legend='',cex=1,pch=16,qual=FALSE,
                         force_zero_center=FALSE,force_n_classes=FALSE,set_breaks=FALSE,breaks=NA){

  # works well for pdf width=10,height=7

  # input variables:
  # x,y: coordinates
  # z: variable to plot
  # n_classes: number of color classes (even number suggested)
  # col: http://colorbrewer2.org/ color scheme - RdYlBu: red to blue - BrBG: green to brown - PRGn: purple to green
  # col_rev: reverse the color scheme?
  # col_trans: use transparent colors (0 is opaque 255 is transparent)
  # b_round: number of decimals to keep for the break values
  # text_legend: text to add above the color bar

  require(RColorBrewer)
  require(maps)
  library(TeachingDemos) # for subplot

  if(length(x)!=length(y)|length(x)!=length(z)){stop('x,y and z must have the same length')}

  if(force_zero_center&n_classes%%2!=0){stop('n_classes must be an even number if force_zero_center is TRUE')}

  # define colors and breaks

  if(!qual){

    if(set_breaks){

      b<-breaks

    }else{

      b<-unique(round(quantile(z,seq(1/n_classes,1-1/n_classes,length.out=n_classes-1),na.rm = TRUE),b_round))

      if(b[1]==0&length(b)>1){b<-b[-1]}

      if(force_n_classes&length(b)<n_classes){

        z_temp<-z[z>b[1]] # only works if first class is the most populated one (e.g. no snow). TODO: use which.max(table(findInterval))
        b_temp<-unique(round(quantile(z_temp,seq(1/n_classes,1-1/n_classes,length.out=n_classes-2),na.rm = TRUE),b_round))
        b<-c(b[1],b_temp)

      }

      if(force_zero_center){
        b[n_classes/2]<-0
      }

    }

    print(b)

    if(length(b)<2){ # the mimimum number of color delivered by colorbrewer is 3

      col<-brewer.pal(4,col_scheme)[1:(length(b)+1)]

    } else {

      col<-brewer.pal(length(b)+1,col_scheme)

    }

  } else { # qualitative classes

    # create a array containing the name of all classes used, i.e. to be plotted
    qc<-table(z)
    qc_nonzero<-qc[as.numeric(qc)!=0]
    qc_label<-names(qc_nonzero)

    # create a table associating expected classes to hard-coded colors

    if(col_scheme=='seas'){

      if(any(qc_label!=c('djf','jja','mam','son'))){

        stop('When color scheme is seas, the variable to plot must have 4 levels: djf, jja, mam, son')

      }

      col_table<-data.frame(categ=c('djf','mam','jja','son'),
                            R_color=c('lightskyblue','darkolivegreen2','darkgoldenrod1','sienna2'))

    } else if(col_scheme=='glim'){

      file_glim_colors<-paste0(dir_data,'GLiM/GLiM_classes_colors.txt')

      if(!file.exists(file_glim_colors)){

        stop(paste('File with glim colors is missing:',file_glim_colors))

      }

      # load colors
      table_glim_classes<-read.table(file_glim_colors,sep=';',header=TRUE)
      table_glim_classes$short_name<-as.factor(table_glim_classes$short_name)

      if(any(colnames(table_glim_classes)!=c('short_name','long_name','R_color'))){

        stop(paste('Unexpect colum names in:',file_glim_colors))

      }

      col_table<-data.frame(categ=table_glim_classes$long_name,
                            R_color=table_glim_classes$R_color)

      if(!any(qc_label%in%col_table$categ)){

        stop(paste('One or more quanlitative class does not appear in:',file_glim_colors))

      }

    } else {

      if(length(qc_nonzero)>11){ # the maximum number of color delivered by colorbrewer is around 10

        print('combining two colors classes because number of breaks > 11')

        # combining two color classes
        n_colors_paired<-ceiling(length(qc_nonzero)/2)
        col<-c(brewer.pal(n_colors_paired,'Paired'),brewer.pal(length(qc_nonzero)-n_colors_paired,'Set3'))

      } else{

        col<-brewer.pal(length(qc_nonzero),col_scheme)

      }

      col_table<-data.frame(categ=qc_label,
                            R_color=col)

    }

    # determine color of each basin
    z_temp<-data.frame(sort_column=1:length(z),z=z) # add a sorting column
    merged_table<-merge(z_temp,col_table,by.x='z',by.y='categ',all.x=TRUE) # all.x allows to keep NA values
    merged_table<-merged_table[order(merged_table$sort_column),] # sort

    if(dim(merged_table)[1]!=length(z)){

      stop('Error when determining colors.')

    }

    col_each_basin<-as.character(merged_table$R_color)

  }

  if(col_rev){col<-rev(col)} # reverse color scheme if necessary
  if(col_trans>0){col<-paste(col,col_trans,sep='')} # use semi-transparent colors if necessary

  if(color_bar){

    layout(matrix(1:2,2,1),heights=c(4,0.85),widths=1)

  }

  # plot map
  par(mar=c(0,0,0,0))
  map("state",col='gray60',fill=TRUE,border=NA)
  map("state",col='gray89',add=TRUE,lwd=1,resolution=0)
  map("state",col='black',add=TRUE,lwd=0.8,resolution=0,interior = FALSE)

  if(qual){

    if(pch>=21){
      points(x, y, bg=col_each_basin,cex=cex,pch=pch)
    } else{
      points(x, y, col=col_each_basin,cex=cex,pch=pch)
    }

  }else{

    if(pch>=21){
      points(x, y, bg=col[findInterval(z,b)+1],cex=cex,pch=pch)
    } else{
      points(x, y, col=col[findInterval(z,b)+1],cex=cex,pch=pch)
    }

  }

  text(-122,25.5,text_legend,pos=4)

  if(subplot_hist){

    if(qual){

      par(las=3,cex=0.8)
      table_seas<-table(z)
      table_seas<-table_seas[c('djf','mam','jja','son')]
      subplot(barplot(table_seas,main='',ylab='',xlab='',col=col,names.arg=FALSE),-69,28.5,size=c(0.75,0.75))

    }else{

      par(las=0,cex=0.8)
      subplot(hist(z,main='',ylab='',xlab='',breaks=10),-69,28.5,size=c(0.75,0.75))

    }
  }

  # plot legend
   if(!qual){
    if(color_bar){
      par(mar=c(3,5,0,5),cex=1)
      plot.legend.na(col, b, vert=FALSE)
    }
   }else{
     par(mar=c(0,0,0,0),cex=0.2) # extra small legend so that everything fits
     plot.new()
     if(pch>=21){
       legend('top',pt.bg=as.character(col_table$R_color),legend=col_table$categ,pch=pch,ncol=2,bty='n')
     }else{
       legend('top',col=as.character(col_table$R_color),legend=col_table$categ,pch=pch,ncol=2,bty='n')
     }
   }

  # reset layout
  # layout(1,heights=1,widths=1) # commented to use layout in another part of the script

}

# plot horizontal or verstical color bar

plot.legend.na<-function (col, breaks, vert=TRUE, density = NULL, angle = 45, slwd = par("lwd"), cex.leg = 1) {

  nbrk <- length(breaks)
  ncol <- length(col)

  if (ncol != (nbrk + 1)) {
    stop("Length of col must be length of breaks plus 1")
  }
  if (is.null(density)) {
    dens <- NULL
  }
  else {
    dens <- rep(density, length = ncol)
  }

  lwds <- rep(slwd, length = ncol)
  angs <- rep(angle, length = ncol)

  if(vert){

    image(x = c(1), y = seq(1, (ncol + 1)) - 0.5, z = matrix(seq(1, (ncol + 1)) - 0.5, nrow = 1), col = col, breaks = seq(1,(ncol + 1)), ylim = c(1, (ncol + 1)), axes = FALSE, xlab = "", ylab = "")

    for (k in 1:ncol) {
      polygon(x = c(0, 2, 2, 0, 0), y = c(k, k, k + 1, k + 1, k), col = "white", border = NA, xpd = FALSE)
      polygon(x = c(0, 2, 2, 0, 0), y = c(k, k, k + 1, k + 1, k), col = col[k], density = dens[k], lwd = lwds[k],
              angle = angs[k], border = NA, xpd = FALSE)
    }

    axis(4, lwd = 0, at = seq(2, ncol), labels = breaks, las = 1, tick = FALSE, cex.axis = cex.leg)

  }else{

    image(y = c(1), x = seq(1, (ncol + 1)) - 0.5, z = matrix(seq(1, (ncol + 1)) - 0.5, ncol = 1), col = col, breaks = seq(1,(ncol + 1)), xlim = c(1, (ncol + 1)), axes = FALSE, xlab = "", ylab = "")

    for (k in 1:ncol) {
      polygon(y = c(0, 2, 2, 0, 0), x = c(k, k, k + 1, k + 1, k), col = "white", border = NA, xpd = FALSE)
      polygon(y = c(0, 2, 2, 0, 0), x = c(k, k, k + 1, k + 1, k), col = col[k], density = dens[k], lwd = lwds[k],
              angle = angs[k], border = NA, xpd = FALSE)
    }

    axis(1, lwd = 0, at = seq(2, ncol), labels = breaks, las = 1, tick = FALSE, cex.axis = cex.leg)

  }

  box()

}
