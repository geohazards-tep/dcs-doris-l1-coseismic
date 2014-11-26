## Developer Cloud Service ADORE Doris coseismic interferogram with Envisat ASAR Image Mode Level 1 

The Delft Institute of Earth Observation and Space Systems of Delft University of Technology has developed an Interferometric Synthetic Aperture Radar (InSAR) processor named [Doris](http://doris.tudelft.nl/) (Delft object-oriented radar interferometric software)

Doris is a standalone program that can perform most common steps of the interferometric radar processing in a modular set up. Doris handles SLC (Single Look Complex) data to generate interferometric products, and can be used to georeference unwrapped products. For an example, see the DEM of Las Vegas, created from ENVISAT data. As phase unwrapper, the external SNAPHU software is recommended (follow the link below to download, and install separately).

ADORE stands for [Automated DORIS Environment](https://code.google.com/p/adore-doris/). It is development started at the University of Miami Geodesy Group, to help researchers generate interferograms with ease. Just like DORIS it is an open source project and it comes with the same license. ADORE tries to provide a streamlined user interface for generating interferograms with DORIS and has some additional features for displaying and exporting the results, and time series analysis. 

## Quick link
 
* [Getting Started](#getting-started)
* [Installation](#installation)
* [Submitting the workflow](#submit)
* [Community and Documentation](#community)
* [Authors](#authors)
* [Questions, bugs, and suggestions](#questions)
* [License](#license)

### <a name="getting-started"></a>Getting Started 

To run this application you will need a Developer Cloud Sandbox, that can be either requested from the ESA [Research & Service Support Portal](http://eogrid.esrin.esa.int/cloudtoolbox/) for ESA G-POD related projects and ESA registered user accounts, or directly from [Terradue's Portal](http://www.terradue.com/partners), provided user registration approval. 

A Developer Cloud Sandbox provides Earth Sciences data access services, and helper tools for a user to implement, test and validate a scalable data processing application. It offers a dedicated virtual machine and a Cloud Computing environment.
The virtual machine runs in two different lifecycle modes: Sandbox mode and Cluster mode. 
Used in Sandbox mode (single virtual machine), it supports cluster simulation and user assistance functions in building the distributed application.
Used in Cluster mode (a set of master and slave nodes), it supports the deployment and execution of the application with the power of distributed computing for data processing over large datasets (leveraging the Hadoop Streaming MapReduce technology). 
### <a name="installation"></a>Installation

#### Pre-requisites

Downgrade *geos* with:

```bash
sudo yum -y downgrade geos-3.3.2
```

##### Using the releases

Log on the developer cloud sandbox. Download the rpm package from https://github.com/Terradue/dcs-doris-l1-coseismic/releases. 
Install the dowanloaded package by running these commands in a shell:

```bash
sudo yum -y install dcs-doris-l1-coseismic-<version>-ciop.x86_64.rpm
```

#### Using the development version

Log on the developer sandbox and run these commands in a shell:

```bash
sudo yum -y install adore-t2
cd
git clone git@github.com:geohazards-tep/dcs-doris-l1-coseismic.git
cd dcs-doris-l1-coseismic
mvn install
```

### <a name="submit"></a>Submitting the workflow

Run this command in a shell:

```bash
ciop-simwf
```
Or invoke the Web Processing Service via the Sandbox dashboard or the [Geohazards Thematic Exploitation platform](https://geohazards-tep.eo.esa.int) providing a master/slave product URLs and a project name.

### <a name="community"></a>Community and Documentation

To learn more and find information go to 

* [Developer Cloud Sandbox](http://docs.terradue.com/developer) service 
* [Doris](http://doris.tudelft.nl/)
* [Adore Doris](https://code.google.com/p/adore-doris/)

### <a name="authors"></a>Authors (alphabetically)

* Brito Fabrice
* D'Andria Fabio

### <a name="questions"></a>Questions, bugs, and suggestions

Please file any bugs or questions as [issues](https://github.com/geohazards-tep/dcs-doris-l1-coseismic/issues/new) or send in a pull request.

### <a name="license"></a>License

Copyright 2014 Terradue Srl

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
