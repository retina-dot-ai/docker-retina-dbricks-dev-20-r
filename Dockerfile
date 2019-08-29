FROM retina/dbricks-dev-10-python:latest

MAINTAINER "Brad Ito" brad@retina.ai

ARG R_CRAN_REPO=https://mran.microsoft.com/snapshot/2019-08-27

# install R and littler
# based on https://hub.docker.com/r/rocker/r-ubuntu/dockerfile

# for details on the ppa's see
# https://rubuntu.netlify.com/
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    software-properties-common \
    ed \
    less \
    vim-tiny \
    wget \
    ca-certificates \
  && add-apt-repository --enable-source --yes "ppa:marutter/rrutter3.5" \
  && add-apt-repository --enable-source --yes "ppa:marutter/c2d4u3.5" \
  && apt-get clean

RUN apt-get update \
  && apt-get install --yes --no-install-recommends \
    r-base \
    r-base-dev \
    r-recommended \
    littler \
  && ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
  && ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
  && ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
  && ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
  && install.r docopt \
  && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# install system dependencies for R
# libssl-dev provides OpenSSL used by R:git2r
# libxml2-dev provides xml2-config which is used by R:XML
RUN apt-get update \
  && apt-get install --yes --no-install-recommends \
    libssl-dev \
    libxml2-dev

# setup reproducibility in R using a fixed CRAN-like repo
#RUN echo "options(repos = c(CRAN = '${R_CRAN_REPO}'))" >> /usr/local/lib/R/etc/Rprofile.site

# hwriterPlus is used by databricks to render html
# but the package was removed by its author from CRAN
# so we install it from an old MRAN snapshot
RUN install2.r --error --repos=https://mran.revolutionanalytics.com/snapshot/2017-02-26 \
    hwriterPlus

# install basic and commonly-used R packages from a recent MRAN snapshot
# - tidyverse (requires httr, rvest, xml2)
RUN install2.r --error --repos=$R_CRAN_REPO \
    devtools \
    httr \
    rvest \
    tidyverse \
    testthat \
    xml2

# install spark and Databricks-required packages from a recent MRAN snapshot
# - Rserve (allows Spark to communicate with a local R process)
# - htmltools (used by databricks notebooks to render html)
RUN install2.r --error --repos=$R_CRAN_REPO \
    htmltools \
    htmlwidgets \
    Rserve \
    SparkR \
    sparklyr

# cleanup
RUN apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
